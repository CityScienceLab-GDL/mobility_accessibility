import serial
import paho.mqtt.client as paho

broker="localhost"
port=1883

def on_publish(client,userdata,result):             #create function for callback
    print("¡Publicado en Gama!".format(userdata, result))
    pass

def on_message(client, userdata, message):
	print('------------------------------')
	print('topic: %s' % message.topic)
	print('payload: %s' % message.payload)
	print('qos: %d' % message.qos)

# Editar
ser = serial.Serial('COM5', 9800, timeout=1) # Cambiar por COM en el que se conecta el arduino
ser.flushInput()

client= paho.Client("table_client")                           #create client object
client.on_publish = on_publish                          #assign function to callback
client.on_message = on_message
client.connect(broker,port) 

while True:
    try:
        ser_bytes = ser.readline()
        msg = str(ser_bytes[0:len(ser_bytes)-2].decode("utf-8"))
        if "[" in msg and "]" in msg:
            msg_body = msg.split("[")[1]
            msg_body = msg_body.split("]")[0]
            msg_parts = msg_body.split(",")
            for part in msg_parts:
                polygon, scenario = part.split("/")
                if polygon in ["A", "B", "K", "I", "L"] and \
                scenario in ["1", "2", "3"]:
                    pass
                else:
                    raise Exception("Mensaje incompleto")
            print(msg_body)
            ret= client.publish("cityscope_table", msg_body) 
    except:
        print("Keyboard Interrupt")
        break