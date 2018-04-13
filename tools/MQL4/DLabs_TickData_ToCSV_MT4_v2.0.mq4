//+------------------------------------------------------------------+
//|                                DLabs_TickData_ToCSV_MT4_v2.0.mq4 |
//|                                   Copyright 2018, Darwinex Labs. |
//|                         https://blog.darwinex.com/category/labs/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Darwinex Labs."
#property link      "https://blog.darwinex.com/category/labs/"
#property version   "2.00"
#property strict
#property indicator_chart_window

// Variables
int csv_io_hnd;
MqlTick tick_struct;
string fileName;
string monthStr, dayStr, yearStr;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   /////////////////////////////////////////////
   
   // 11-04-2018: Construct fileName with symbol, and date.
   
   if( Month() < 10 ) 
      monthStr = "0" + DoubleToStr(Month(),0);      
   else 
      monthStr = DoubleToStr(Month(),0);
      
   if ( Day() < 10 ) 
      dayStr = "0" + DoubleToStr(Day(),0);
   else 
      dayStr = DoubleToStr(Day(),0);
      
   yearStr = DoubleToStr(Year(),0);
   
   fileName = Symbol() + "_TickData_" + yearStr + "-" + monthStr + "-" + dayStr + ".csv";  
   
   /////////////////////////////////////////////
   
   // Create CSV file handle in WRITE mode.
   csv_io_hnd = FileOpen(fileName, FILE_CSV|FILE_READ|FILE_WRITE|FILE_REWRITE, ',');
   
   // If creation successful, write CSV header, else throw error
   if(csv_io_hnd > 0)
   {
      if(FileSize(csv_io_hnd) <= 5)
         FileWrite(csv_io_hnd, "time_milliseconds", "bid", "ask", "spread");
         
      // Move to end of file (if it's being written to again)
      FileSeek(csv_io_hnd, 0, SEEK_END);
   }
   else
      Alert("ERROR: Opening/Creating CSV file!");
      
   
   ///////////////////////////////////////////// 
   
   // If CSV file handle is open, write time, bid, ask and spread to it.
   if(csv_io_hnd > 0)
   {
      if(SymbolInfoTick(Symbol(), tick_struct))
      {
         Comment("\n[Darwinex Labs] Tick Data | Bid: " + DoubleToString(tick_struct.bid, 5) 
         + " | Ask: " + DoubleToString(tick_struct.ask, 5) 
         + " | Spread: " + StringFormat("%.05f", NormalizeDouble(MathAbs(tick_struct.bid - tick_struct.ask), 5))
         + "\n\n* Writing tick data to \\MQL4\\Files\\" + fileName
         + "\n(please remove the indicator from this chart to access CSV under \\MQL4\\Files.)"
         );
         FileWrite(csv_io_hnd, tick_struct.time_msc, tick_struct.bid,
                       tick_struct.ask, StringFormat("%.05f", NormalizeDouble(MathAbs(tick_struct.bid - tick_struct.ask), 5)));
                       
         // 11-04-2018: Close file handle so it's accessible to other processes.
         FileClose(csv_io_hnd);
      } 
      else
         Print("ERROR: SymbolInfoTick() failed to validate tick."); 
   }
   
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{  
   // Close CSV file handle if currently open, before exiting.
   if(csv_io_hnd > 0)
      FileClose(csv_io_hnd);
      
   // Clear chart comments
   Comment("");
}