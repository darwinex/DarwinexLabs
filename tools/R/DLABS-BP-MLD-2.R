#
# Machine Learning on DARWIN Datasets - II
# Import & Manipulate DARWIN Time Series in R
#
# DLABS-BP-MLD-2.R
#

# 1) Load required libraries

# 2) Importing datasets from GitHub

# 3) Inspect data types & localize timezones

# 4) Creating OHLC DARWIN Time Series

# 5) Visualizing DARWIN Time Series

# 6) Efficient data storage practices

# 7) What's coming up next?

#################################################

# 1) Load required libraries

# Disable scientific formatting
options(scipen=9999)

if (!require("pacman")) 
  install.packages("pacman")

libs.vector <- c("anytime",
                 "data.table",
                 "xts", "zoo", "quantmod",
                 "plotly",
                 "microbenchmark")

pacman::p_load(char = libs.vector,
               install=TRUE, 
               update=FALSE)

#####

# 2) Importing datasets from GitHub

DWC.M1.QUOTES.dt <- fread("DWC.M1.QUOTES.29.12.2017.csv", colClasses="numeric")

#####

# 3) Initial data preparation, timezone localization & best practices

# Confirm data types
class(DWC.M1.QUOTES.dt$timestamp)
class(DWC.M1.QUOTES.dt$quote)

# Localize numeric timestamps to POSIXct (UTC)
DWC.M1.QUOTES.dt$timestamp <- anytime(DWC.M1.QUOTES.dt$timestamp, tz="UTC")

#####

# 4) Creating OHLC DARWIN Time Series

require(xts)

Convert.toOHLC <- function(x) {
  op <- as.vector(first(x))
  hl <- range(x, na.rm = TRUE)
  cl <- as.vector(last(x))
  
  xts(cbind(Open = op, High = hl[2], Low = hl[1], Close = cl), end(x))
}

Convert.DARWIN.To.D1.OHLC.XTS <- function(darwin.M1.dt,
                                          start.hour = 21,
                                          ts.type="open")
{
  # 1) Accept M1 data table and convert to 1-hour periodicity xts object
  ret.xts <- xts(x = as.numeric(.subset2(darwin.M1.dt, "quote")), 
                 order.by = anytime(as.numeric(.subset2(darwin.M1.dt, "timestamp")), tz="UTC"))
  
  # Create H1 xts object
  ret.xts <- to.period(x = ret.xts,
                       period = 'hours',
                       OHLC = FALSE,
                       indexAt = 'endof')
  
  ret.H1.zoo <- zoo(coredata(ret.xts), order.by = index(ret.xts))
  
  # Convert to xts
  y <- as.xts(ret.H1.zoo)
  
  # Find first occurence of start.hour
  first.y <- which(hour(index(y)) == start.hour)[1]
  
  # Set first observation to epoch (zero)
  .index(y) <- .index(y) - .index(y)[first.y]
  
  # Get endpoints for y by day
  ep <- endpoints(y, "days")
  
  ret.H1.zoo <- period.apply(ret.H1.zoo, ep, Convert.toOHLC)
  
  if(grepl("open", ts.type)) {
    # Lag the series by 1, making each timestamp the Open Time of the corresponding OHLC record.
    return(na.omit(lag(as.xts(ret.H1.zoo), -1)))  
  } else {
    return(as.xts(ret.H1.zoo))  
  }
}

#####

# 5) Visualizing DARWIN Time Series

# Visualize XTS data as Candlestick Chart with Bollinger Bands
ts.visualize.DARWIN.xts <- function(darwin.D1.xts,
                                    chart.type="candlestick") {
  
  # chart.type = candlesticks | closes | returns
  
  df <- data.frame(Date=index(darwin.D1.xts),coredata(darwin.D1.xts))
  
  bb <- BBands(df[ , c("High", "Low", "Close")])
  df <- cbind(df, bb[, 1:3])
  
  if(grepl("candlestick", chart.type)) {
    print(df %>%
            plot_ly(name="DWC", x = ~Date, type="candlestick",
                    open = ~Open, close = ~Close,
                    high = ~High, low = ~Low) %>%
            
            add_lines(y = ~up , name = "Bollinger Bands",
                      line = list(color = '#ccc', width = 0.5),
                      legendgroup = "Bollinger Bands",
                      hoverinfo = "none") %>%
            add_lines(y = ~dn, name = "B Bands",
                      line = list(color = '#ccc', width = 0.5),
                      legendgroup = "Bollinger Bands",
                      showlegend = FALSE, hoverinfo = "none") %>%
            add_lines(y = ~mavg, name = "Mv Avg",
                      line = list(color = '#E377C2', width = 0.5),
                      hoverinfo = "none") %>%
            
            layout(title = "DARWIN OHLC Candlestick Chart",
                   yaxis = list(title="DARWIN Quote"),
                   legend = list(orientation = 'h', x = 0.5, y = 1,
                                 xanchor = 'center', yref = 'paper',
                                 font = list(size = 10),
                                 bgcolor = 'transparent')))  
    
  } else if (grepl("closes", chart.type)) {
    print(df %>%
            plot_ly(x = ~Date, type="scatter", mode="lines",
                    y = ~Close) %>%
            
            layout(title = "DARWIN OHLC Line Chart (Close Quotes)",
                   yaxis=list(title="Closing Quote")) )
    
  } else if (grepl("returns", chart.type)) {
    
    rets <- (df$Close[2:nrow(df)] / df$Close[1:nrow(df)-1]) - 1
    
    print(
            plot_ly(x = df$Date, type="scatter", mode="lines",
                    y = c(0, cumprod(1+rets)-1)*100) %>%
            
            layout(title = "DARWIN OHLC Line Chart (C.Returns)",
                   yaxis=list(title="Cumulative Returns (%)")) )
  }
}

#####

# 6) Efficient data storage practices

DWC.D1.QUOTES.OHLC.xts <- Convert.DARWIN.To.D1.OHLC.XTS(DWC.M1.QUOTES.dt)

# saveRDS/readRDS vs. write.csv/read.csv

test.IO.funcs <- function() {
  microbenchmark(
    write.zoo(DWC.D1.QUOTES.OHLC.xts, "DWC.D1.QUOTES.OHLC.xts.csv", sep=","),
    saveRDS(DWC.D1.QUOTES.OHLC.xts, "DWC.D1.QUOTES.OHLC.xts.rds"),
    
    readRDS("DWC.D1.QUOTES.OHLC.xts.rds"),
    read.table("DWC.D1.QUOTES.OHLC.xts.csv", header=TRUE, sep=",")
  )  
}

