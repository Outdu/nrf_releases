#!/usr/bin/env python


import pika, sys, os
import json
from subprocess import call
from threading import Thread
import time
import queue

meta_info_path = "/srv/sr/scripts/meta_info.json"
meta_info = None
with open(meta_info_path,'r') as f:
    meta_info = json.load(f)


class SubProcessUtil:
    def __init__(self):
        self.queue_name = meta_info["subprocess_queue_name"]
        self.msg_queue = queue.Queue()
        self.current_msg = None


    def utilThread(self):
        while True:
            msg = self.msg_queue.get()

            if msg['command'] == "shutdown":
                shutdowncmd = '{} {}'.format("sh", meta_info["shutdown_script_path"])
                call(shutdowncmd, shell=True)
                break


    def callback(self, ch, method, properties, body):
        print(" [x] Received %r" % body)
        msg = json.loads(body)
        self.msg_queue.put(msg)



def main():

    connection = None 
    while True:
        try:
            connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
            print("Connected to mq")
            break
        except:
            print("Error connecting to mq. Retrying in 5 secs")
            time.sleep(5)


    m_subprocessUtil = SubProcessUtil()

    thread = Thread(target=m_subprocessUtil.utilThread)
    thread.start()

    try:
        channel = connection.channel()
        channel.exchange_declare(exchange='com.outdu.sensor', exchange_type="topic", durable=True)
        channel.queue_declare(queue=m_subprocessUtil.queue_name, durable=True)
        channel.queue_bind(exchange='com.outdu.sensor', queue=m_subprocessUtil.queue_name, routing_key=m_subprocessUtil.queue_name)
        channel.basic_consume(queue=m_subprocessUtil.queue_name, on_message_callback=m_subprocessUtil.callback, auto_ack=True)

        print(' [*] Waiting for messages. To exit press CTRL+C')
        channel.start_consuming()
    except:
        pass

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Interrupted')
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)
