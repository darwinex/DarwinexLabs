# -*- coding: utf-8 -*-
"""
Status: DEPRECATED
Please visit DarwinexLabs/tree/master/tools/dwx_zeromq_connector

Created on Thu Aug 24 16:48:05 2017
@author: Darwinex Labs (www.darwinex.com)
"""

# IMPORT zmq library
import zmq

# Sample Commands for ZeroMQ MT4 EA
eurusd_buy_order = "TRADE|OPEN|0|EURUSD|0|50|50|Python-to-MT4"
eurusd_sell_order = "TRADE|OPEN|1|EURUSD|0|50|50|Python-to-MT4"
eurusd_closebuy_order = "TRADE|CLOSE|0|EURUSD|0|50|50|Python-to-MT4"
get_rates = "RATES|GBPUSD"

# Sample Function for Client
def zeromq_mt4_ea_client():
    
    # Create ZMQ Context
    context = zmq.Context()
    
    # Create REQ Socket
    reqSocket = context.socket(zmq.REQ)
    reqSocket.connect("tcp://localhost:5555")
    
    # Create PULL Socket
    pullSocket = context.socket(zmq.PULL)
    pullSocket.connect("tcp://localhost:5556")
    
    # Send RATES command to ZeroMQ MT4 EA
    remote_send(reqSocket, get_rates)
        
    # Send BUY EURUSD command to ZeroMQ MT4 EA
    # remote_send(reqSocket, eurusd_buy_order)
    
    # Send CLOSE EURUSD command to ZeroMQ MT4 EA. You'll need to append the 
    # trade's ORDER ID to the end, as below for example:
    # remote_send(reqSocket, eurusd_closebuy_order + "|" + "12345678")
    
    # PULL from pullSocket
    remote_pull(pullSocket)
    
# Function to send commands to ZeroMQ MT4 EA
def remote_send(socket, data):
    
    try:
        socket.send(data)
        msg = socket.recv_string()
        print msg
        
    except zmq.Again as e:
        print "Waiting for PUSH from MetaTrader 4.."
    
# Function to retrieve data from ZeroMQ MT4 EA
def remote_pull(socket):
    
    try:
        msg = socket.recv(flags=zmq.NOBLOCK)
        print msg
        
    except zmq.Again as e:
        print "Waiting for PUSH from MetaTrader 4.."
    
# Run Tests
zeromq_mt4_ea_client()

