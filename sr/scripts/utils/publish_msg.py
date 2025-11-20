import json
import sys

import pika
import time
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-qn','--queue_name', action='store', type=str, help="Name of the queue",required=True)
parser.add_argument('-d','--data', action='store', type=str, help="Data to publish", required=True)

args = parser.parse_args()


def publish(queue_name, data):
    print ("Establishing connection../..")
    while True:
        try:
            c = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
            print("Connected to mq")
            break
        except:
            print("Error connecting to mq. Retrying after 5 secs")
            time.sleep(5)
    channel = c.channel()
    channel.queue_declare(queue=queue_name, durable=True)
    channel.queue_bind(exchange='com.outdu.sensor', queue=queue_name, routing_key=queue_name)
    
    channel.basic_publish(exchange='com.outdu.sensor', routing_key=queue_name, body=data)
    print ("Message sent: ",data)



if __name__ == '__main__':

    publish(args.queue_name, args.data)

