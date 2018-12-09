#!/usr/bin/pythonRoot
# bring in the libraries

import RPi.GPIO as GPIO
from flup.server.fcgi import WSGIServer
import sys, urlparse
import time
import os

# Referred the following tutorial
# http://davstott.me.uk/index.php/2013/03/17/raspberry-pi-controlling-gpio-from-the-web/
# http://redmine.lighttpd.net/projects/1/wiki/Docs_ModFastCGI
# https://bbs.archlinux.org/viewtopic.php?id=68462

# Raspberry Pi GPIO ports
# Pin 11	Input trigger, High to Low
# Pin 12	MSB 1
# Pin 13	MSB 2
# Pin 15	MSB 3
# Pin 16	MSB 4

# set up our GPIO pins
GPIO.setmode(GPIO.BOARD)

# Set GPIO as output ports
GPIO.setup(11, GPIO.OUT)
GPIO.setup(12, GPIO.OUT)
GPIO.setup(13, GPIO.OUT)
GPIO.setup(15, GPIO.OUT)
GPIO.setup(16, GPIO.OUT)

# Turn off the robot initially
GPIO.output(11, True)
GPIO.output(12, False)
GPIO.output(13, False)
GPIO.output(15, False)
GPIO.output(16, False)
GPIO.output(11, False)

# ===============================================================================
# Command Constant declaration
# ===============================================================================
# CMDSTOP		EQU	000H
# PLSFORWARD	EQU	001H
# CNTFORWARD	EQU	002H
# PLSRIGHT		EQU	003H
# CNTRIGHT		EQU	004H
# PLSLEFT		EQU	005H
# CNTLEFT		EQU	006H
# PLSBACK		EQU	007H
# CNTBACK		EQU	008H
# FRONTDRV		EQU	009H
# BACKTDRV		EQU	00AH
# POWERTDRV		EQU	00BH
# SHUTDOWN		EQU	00FH



# all of our code now lives within the app() 
# function which is called for each http request we receive
def app(environ, start_response):
	# start our http response 
	start_response("200 OK", [("Content-Type", "text/html")])
	# look for inputs on the URL
	parm = urlparse.parse_qs(environ["QUERY_STRING"])
	
	# if there's a url variable named 'action'
	if "action" in parm:
		if parm["action"][0] == "0": 
			GPIO.output(11, True)
			
			GPIO.output(12, False)
			GPIO.output(13, False)
			GPIO.output(15, False)
			GPIO.output(16, False)
			
			GPIO.output(11, False)
			
			return['Command 0 executed']
		elif parm["action"][0] == "1":
			GPIO.output(11, True)
			
			GPIO.output(12, False)
			GPIO.output(13, False)
			GPIO.output(15, False)
			GPIO.output(16, True)
			
			GPIO.output(11, False)
			
			return['Command 1 executed']
		elif parm["action"][0] == "2":
			GPIO.output(11, True)
			
			GPIO.output(12, False)
			GPIO.output(13, False)
			GPIO.output(15, True)
			GPIO.output(16, False)
			
			GPIO.output(11, False)
			
			return['Command 2 executed']
		elif parm["action"][0] == "3":
			GPIO.output(11, True)
			
			GPIO.output(12, False)
			GPIO.output(13, False)
			GPIO.output(15, True)
			GPIO.output(16, True)
			
			GPIO.output(11, False)
			
			return['Command 3 executed']
		elif parm["action"][0] == "4":
			GPIO.output(11, True)
			
			GPIO.output(12, False)
			GPIO.output(13, True)
			GPIO.output(15, False)
			GPIO.output(16, False)
			
			GPIO.output(11, False)
			
			return['Command 4 executed']
		elif parm["action"][0] == "5":
			GPIO.output(11, True)
			
			GPIO.output(12, False)
			GPIO.output(13, True)
			GPIO.output(15, False)
			GPIO.output(16, True)
			
			GPIO.output(11, False)
			
			return['Command 5 executed']
		elif parm["action"][0] == "6":
			GPIO.output(11, True)
			
			GPIO.output(12, False)
			GPIO.output(13, True)
			GPIO.output(15, True)
			GPIO.output(16, False)
			
			GPIO.output(11, False)
			
			return['Command 6 executed']
		elif parm["action"][0] == "7":
			GPIO.output(11, True)
			
			GPIO.output(12, False)
			GPIO.output(13, True)
			GPIO.output(15, True)
			GPIO.output(16, True)
			
			GPIO.output(11, False)
			
			return['Command 7 executed']
		elif parm["action"][0] == "8":
			GPIO.output(11, True)
			
			GPIO.output(12, True)
			GPIO.output(13, False)
			GPIO.output(15, False)
			GPIO.output(16, False)
			
			GPIO.output(11, False)
			
			return['Command 8 executed']
		elif parm["action"][0] == "9":
			GPIO.output(11, True)
			
			GPIO.output(12, True)
			GPIO.output(13, False)
			GPIO.output(15, False)
			GPIO.output(16, True)
			
			GPIO.output(11, False)
			
			return['Command 9 executed']
		elif parm["action"][0] == "a":
			GPIO.output(11, True)
			
			GPIO.output(12, True)
			GPIO.output(13, False)
			GPIO.output(15, True)
			GPIO.output(16, False)
			
			GPIO.output(11, False)
			
			return['Command a executed']
		elif parm["action"][0] == "b":
			GPIO.output(11, True)
			
			GPIO.output(12, True)
			GPIO.output(13, False)
			GPIO.output(15, True)
			GPIO.output(16, True)
			
			GPIO.output(11, False)
			
			return['Command b executed']
		elif parm["action"][0] == "f":
			GPIO.output(11, True)
			
			GPIO.output(12, True)
			GPIO.output(13, True)
			GPIO.output(15, True)
			GPIO.output(16, True)
			
			GPIO.output(11, False)
			
			# Wait for 3 seconds and shoutdown the PI
			time.sleep(3)			
			os.system("shutdown now -h")
			return['Shutting down...']
		else:
			return['Invalid request 1']
	else:
		return['Invalid request 2']

# by default, Flup works out how to bind to the web server for us, 
# so just call it with our app() function and let it get on with it
WSGIServer(app).run()
