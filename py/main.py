import mydevice
import sys
from threading import Timer
import time
import os

sys.stdout = mydevice
sys.stderr = mydevice

#globals
#_wifi_info_visited = False
#_wifi_connect_done = False

def main():
	print("hello world from python")
	print("version: ")
	print(mydevice.version())
	return mydevice.run(lambda event: eventLoop(event))

# def pressBackspaceKey(n_times):
# 	for i in range(n_times):
# 		mydevice.touchScreenAt(739, 231) #backspace

# def pressKeys(keys):
# 	mydevice.touchScreenAt(149, 294) #a
# 	mydevice.touchScreenAt(427, 354) #b
# 	mydevice.touchScreenAt(292, 232) #r
# 	mydevice.touchScreenAt(149, 294) #a
# 	mydevice.touchScreenAt(300, 349) #c
# 	mydevice.touchScreenAt(149, 294) #a
# 	mydevice.touchScreenAt(264, 291) #d
# 	mydevice.touchScreenAt(149, 294) #a
# 	mydevice.touchScreenAt(427, 354) #b
# 	mydevice.touchScreenAt(292, 232) #r
# 	mydevice.touchScreenAt(149, 294) #a

# def touchPasswordWidget():
# 	mydevice.touchScreenAt(466, 171) #password

# def pressCheckmarkKey():
# 	mydevice.touchScreenAt(722, 406) #check mark button

def eventLoop(event):
	# if event and "screen_id" in event.keys():
		# global _wifi_info_visited
		# global _wifi_connect_done
		# if event["screen_id"] == "opening_menu1":
		# 	mydevice.touchWidgetById("opening_menu1/setup")
		# elif event["screen_id"] == "menu_setup":
		# 	mydevice.touchWidgetById("menu_setup/wireless")
		# elif event["screen_id"] == "wireless_menu":
		# 	mydevice.touchWidgetById("wireless_menu/wifi")
		# elif event["screen_id"] == "wifi_info":
		# 	if not _wifi_info_visited:
		# 		mydevice.touchWidgetById("wifi_info/search")
		# 		_wifi_info_visited = True
		# 	else:
		# 		timer = Timer(1, checkConnectedStatus) 
		# 		timer.start()
		# elif event["screen_id"] == "wifi_search":
		# 	if not _wifi_connect_done:
		# 		timer = Timer(2, selectWifiNetwork) 
		# 		timer.start()
		# elif event["screen_id"] == "wifi_connect":
		# 	pressBackspaceKey(12)
		# 	pressKeys("abracadabra")
		# 	touchPasswordWidget()
		# 	pressBackspaceKey(12)
		# 	pressKeys("abracadabra")
		# 	pressCheckmarkKey()
		# 	mydevice.touchWidgetById("wifi_connect/accept")
		# 	_wifi_connect_done = True
	return True

# def selectWifiNetwork():
# 	nth_obj = 0
# 	mydevice.touchWidgetByText("Jurassic WiFi                     ", nth_obj)

# def checkConnectedStatus():
# 	mydevice.touchScreenAt(420, 240)
# 	txt = mydevice.getWidgetTextOnScreenAt(420, 240) #Connected string should be here
# 	if txt != "Status : Connected":
# 		print("no match: " + str(txt))
# 		os.abort()
# 	else:
# 		print("TEST PASSED")
