import sys
import pika
import subprocess
import json

def callback(ch, method, properties, body):
    print(" [x] Received %r" % body)
    msg = json.loads(body)
    if msg['command'] == "unmount":
        print("unmount")
        subprocess.call('echo {} | sudo -S {} {}'.format("sahana123", "umount", msg['value']), shell=True)


if __name__ == '__main__':

    in_q = 'com.outdu.subprocess.in' 

    conn = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
    ch = conn.channel()
    ch.exchange_declare(exchange='com.outdu.sensor', exchange_type="topic", durable=True)
    ch.queue_declare(queue=in_q, durable=True)
    ch.queue_bind(exchange='com.outdu.sensor', queue=in_q, routing_key=in_q)
    ch.basic_consume(in_q, callback, True)

    ch.start_consuming()
