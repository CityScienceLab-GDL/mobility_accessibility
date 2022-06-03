import serial
import paho.mqtt.client as paho

broker="localhost"
port=1883

status = {"A":"1","B":"1","K":"1","I":"1","L":"1"}

def on_publish(client,userdata,result):             #create function for callback
    print("¡Publicado en Gama!".format(userdata, result))
    pass

def on_message(client, userdata, message):
	print('------------------------------')
	print('topic: %s' % message.topic)
	print('payload: %s' % message.payload)
	print('qos: %d' % message.qos)

# Editar
ser = serial.Serial('COM7', 9800, timeout=1) # Cambiar por COM en el que se conecta el arduino
ser.flushInput()

client= paho.Client("table_client")                           #create client object
client.on_publish = on_publish                          #assign function to callback
client.on_message = on_message
client.connect(broker,port) 

while True:
    try:
        ser_bytes = ser.readline()
        msg = str(ser_bytes[0:len(ser_bytes)-2].decode("utf-8"))
        msg_polygons = msg.split(",")
        for element in msg_polygons:
            msg_parts = element.split("/")
            if msg_parts[0] in ["A", "B", "K", "I", "L"] and msg_parts[1] in ["1", "2", "3"]:
                polygon = msg_parts[0]
                project = msg_parts[1]
                if status[polygon] != project:
                    print("Nuevo proyecto '{}' para poligono '{}'".format(polygon, project))
                    status[polygon] = project
                    msg_body = "A/{},B/{},K/{},I/{},L/{}".format(status["A"], status["B"], \
                                                status["K"], status["I"], status["L"])
                    ret= client.publish("cityscope_table", msg_body) 
    except:
        print("Keyboard Interrupt")
        break
        """
        print(msg)
    except:
        pass
        """