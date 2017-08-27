#+------------------------------------------------------------------+
#|                                          ZeroMQ_MT4_R_Template.R |
#|                                    Copyright 2017, Darwinex Labs |
#|                                        https://www.darwinex.com/ |
#+------------------------------------------------------------------+

library(rzmq)

# Random placeholder for PULL later.
pull.msg <- "N/A"

# Function to send commands to ZeroMQ MT4 EA
remote.send <- function(rSocket,data) {
  send.raw.string(rSocket, data)
  msg <- receive.string(rSocket)
  
  print(msg)
}

# Function to PULL data from ZeroMQ MT4 EA PUSH socket.
remote.pull <- function(pSocket) {

  msg <- receive.socket(pSocket, unserialize = FALSE, dont.wait = TRUE)
  
  if(is.null(msg)) {
    msg <- "No data PUSHED yet.."
    print(msg)
  } else {
    msg <- rawToChar(msg)
    print(msg)  
  }

  return(msg)
}

context = init.context()
reqSocket = init.socket(context,"ZMQ_REQ")
pullSocket = init.socket(context, "ZMQ_PULL")

connect.socket(reqSocket,"tcp://localhost:5555")
connect.socket(pullSocket,"tcp://localhost:5556")

while(TRUE) {
  
  # REMEMBER: If the data you're pulling isn't "downloaded" in MT4's History Centre,
  #           it's very likely your PULL will produce no data.
  
  #           So if you're going to be pulling data for a currency pair from MT4,
  #           make sure its data is downloaded, and chart open just in case.
  
  # Pull from server
  remote.pull(pullSocket)
  
  f <- file("stdin")
  open(f)
  
  print("Enter Command for MetaTrader 4 ZeroMQ Server, 'q' to quit")
  # e.g. RATES|EURUSD -> Retrieves Current Bid/Ask for EURUSD from MT4.
  mt4.command <- readLines(f, n=1)
  
  if(tolower(mt4.command)=="q"){
    break
  }
  
  # Send to ZeroMQ MetaTrader 4 Server
  if(!grepl("PULL", mt4.command))
    remote.send(reqSocket, mt4.command)
  
  # Pull from ZeroMQ MetaTrader 4 Server
  pull.msg <- remote.pull(pullSocket)
}
