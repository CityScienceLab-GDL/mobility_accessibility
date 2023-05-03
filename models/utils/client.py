import paho.mqtt.client as paho
import argparse

broker="localhost"
port=1883

def on_publish(client,userdata,result):             #create function for callback
    print("data published on table\n".format(userdata, result))
    pass

def on_message(client, userdata, message):
	print('------------------------------')
	print('topic: %s' % message.topic)
	print('payload: %s' % message.payload)
	print('qos: %d' % message.qos)

parser = argparse.ArgumentParser(description='Input MQTT message.')
parser.add_argument('--poligono', type=str, default= "A",
                    help='an string for the message polygon_number')
parser.add_argument('--escenario', type=str, default="1",
                    help='an string for the message polygon_number')

args = parser.parse_args()

print("{}/{}".format(args.poligono, args.escenario))
msg = "{}/{}".format(args.poligono, args.escenario)
#msg = "A/2,B/2,I/2,K/2,L/2"
#msg = "A/2,B/2,I/2,K/2,L/2"
msg = "A/1,B/1,I/1,K/1,L/1"
client= paho.Client("table_client")                           #create client object
client.on_publish = on_publish                          #assign function to callback
client.on_message = on_message
client.connect(broker,port)                                 #establish connection
ret= client.publish("cityscope_table", msg)                   #publish