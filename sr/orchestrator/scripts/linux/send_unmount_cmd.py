import json

import pika

if __name__ == '__main__':
    print('Create connection')
    c = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
    print('Create channel')
    channel = c.channel()
    print('Declare queue')
    channel.queue_declare(queue='com.outdu.subprocess.in', durable=True)
    print('Queue declared')

    msg = {
        "messageType": "subprocessCommand",
        "command": "unmount",
        "value":"/srv/sr/dfmusb"
    }

    msg_str = json.dumps(msg)
    print('Send message')

    channel.basic_publish(exchange='com.outdu.sensor', routing_key='com.outdu.subprocess.in', body=msg_str)
    print("%s msg sent " % msg_str)
