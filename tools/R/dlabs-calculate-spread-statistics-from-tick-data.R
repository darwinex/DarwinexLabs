#
# Filename: dlabs-calculate-spread-statistics-from-tick-data.R 
#
# Reads in CSV file containing rows of {time_milliseconds|bid|ask|spread} and
# calculates MIN, MAX, AVERAGE and NUM_TICKS for each second, then store as a new CSV.
# 
# Date: 28/03/2018
# Darwinex Labs - https://blog.darwinex.com/category/labs/
#

library(data.table)

# Disable scientific numbers.
options(scipen = 9999)

# Variables
formatter <- "(_TickData_).*\\.csv$"
working_directory <- "C:\\Users\\INSERT-WINDOWS-USERNAME\\AppData\\Roaming\\MetaQuotes\\Terminal\\LONG-ALPHANUMERIC-STRING\\MQL4\\Files"
# working_directory <- "C:\\Users\\INSERT-WINDOWS-USERNAME\\AppData\\Roaming\\MetaQuotes\\Terminal\\LONG-ALPHANUMERIC-STRING\\MQL5\\Files"
zip_archives_directory <- "ZIP_ARCHIVES"
storage_prefix <- "SPREADS_"

# This date will be used to filter which CSV files to access
# in the \\MQL\\Files directory.
date_of_interest <- Sys.Date()-1 # Actual
# date_of_interest <- Sys.Date() # Current day's testing only.

# 1) Set Working Directory to MQL -> Files
setwd(working_directory)

# 2) Get list of files containg string in "formatter"
csv_list <- list.files(pattern = formatter) # Returns a character ARRAY

#
# FUNCTION - Calculates and returns a data frame containing
#            DATE | MIN | MAX | AVERAGE | NUM_TICKS
#
Calculate_Spreads_by_Second <- function(ts_list)
{
  require(data.table)
  
  # Create empty data table with 5 columns
  # for DATETIME | MIN | MAX | AVERAGE | NUM_TICKS
  ts_len <- length(ts_list)
  retDt <- data.table(DATETIME=numeric(ts_len), 
                      MIN=numeric(ts_len), 
                      MAX=numeric(ts_len), 
                      AVERAGE=numeric(ts_len), 
                      NUM_TICKS=numeric(ts_len), 
                      stringsAsFactors = F)
  
  for(i in 1:ts_len)
  {
    retDt[i,1] <- .subset2(ts_list[[i]], 1)[1]
    retDt[i,2] <- min(.subset2(ts_list[[i]], 4)) # Column "Spread" is index 4 in tick data CSV {time|bid|ask|spread}
    retDt[i,3] <- max(.subset2(ts_list[[i]], 4))
    retDt[i,4] <- sum(.subset2(ts_list[[i]], 4)) / length(.subset2(ts_list[[i]], 4))
    retDt[i,5] <- nrow(ts_list[[i]])
  }
  
  # Return the data table.
  return(retDt)
}

##
Write_Spreads_to_CSV <- function(wdir=working_directory,
                                 doi=date_of_interest,
                                 sdir=zip_archives_directory,
                                 sop=storage_prefix,
                                 csv.file=NULL,
                                 data=NULL) {
  
  # Write this data to a new file with PREFIX "SPREADS_" and the original filename
  # Don't write row.names - only takes up more disk space, don't need them here.
  print("WRITING TO NEW CSV.. please wait..")
  
  # storage_directory <- as.Date(Sys.Date())
  storage_directory <- as.Date(doi)
  
  # Create storage directory if it doesn't exist.
  dir.create(file.path(wdir, storage_directory), showWarnings = FALSE)
  
  # Switch to storage directory.
  setwd(file.path(wdir, storage_directory))
  
  # Write spread statistics to new CSV.
  write.csv(data, paste(sop, csv.file, sep=""), row.names = FALSE)
  
  # Now ZIP this file.
  zip(paste(sop, csv.file, ".zip", sep=""), files=paste(sop, csv.file, sep=""))
  
  # Delete raw summaries CSV.
  print("Permanently DELETING SUMMARIES CSV.. please wait..")
  file.remove(paste(sop, csv.file, sep=""))
  
  # ZIP ORIGINAL tick_spreads_ file (make sure RTools is installed!)
  dir.create(file.path(wdir, sdir), showWarnings = FALSE)
  
  # Switch to ZIP_ARCHIVES directory.
  setwd(file.path(wdir, sdir))
  
  # Move raw tick data CSV to ZIP_ARCHIVES
  file.rename(from = paste(wdir, "\\", csv.file, sep=""), to = paste(wdir, "\\", sdir, "\\", csv.file, sep=""))
  
  # Compress (zip) original tick data CSV.
  print("ZIPPING original tick data CSV.. please wait..")
  zip(paste(csv.file, ".zip", sep=""), files=csv.file)
  
  # DELETE ORIGINAL tick_spreads_ file here.
  print("Permanently DELETING original CSV.. please wait..")
  file.remove(csv.file)
  
  # DONE
  print("DONE! .. Next file?")
}

##
Process_Raw_to_Spreads_CSV <- function(csv_list=list()) {
  
  # 3) Loop through csv_list array and perform conversion steps.
  for(csv in csv_list) {
    
    # MQL4 stores days with leading zeros, but not months.
    curr.date <- as.POSIXlt(date_of_interest)
    
    if (grepl(curr.date, csv))
    {
      setwd(working_directory)
      
      print(paste("Opening: ", csv, " for processing.."))
      
      # Load data from CSV into Data Table
      dt <- fread(csv, colClasses = "numeric")
      
      # Split data into lists of spreads by time_milliseconds This allows us to perform
      # calculations on each second of data.
      dt_list <- split(dt, .subset2(dt, "time_milliseconds"))
      
      # Loop through each element in dt_list, calculate statistics
      # and create "day_spreads_by_second" Data Table.
      
      print("Processing TICKS for EACH Second/Millisecond.. please wait..")
      
      day_spreads_by_second <- Calculate_Spreads_by_Second(dt_list)
      
      # Set column names before writing CSV
      # colnames(day_spreads_by_second) <- c("DATETIME", "MIN", "MAX", "AVERAGE", "NUM_TICKS")
      
      # Write to new CSV
      Write_Spreads_to_CSV(wdir=working_directory,
                           doi=date_of_interest,
                           sdir=zip_archives_directory,
                           sop=storage_prefix,
                           csv.file=csv,
                           data=day_spreads_by_second)
    }
    else
    {
      print("....Nothing to do....")
    }
  }
}


###################################################################################
###################################################################################
###################################################################################

if(length(csv_list) == 0) {
  print("....Nothing to do....")
} else {
  Process_Raw_to_Spreads_CSV(csv_list)
}

