//+------------------------------------------------------------------+
//|                                          DLabs_CurrencyIndex.mq4 |
//|                                   Copyright 2017, Darwinex Labs. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Darwinex Labs."
#property strict

#property script_show_inputs
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Blue

#include <DLabs_CurrencyIndex.mqh>

//--- input parameters
input CURRENCY currency=EUR;
input string firstDate="2015.01.01";

//--Buffers indexes
double idx[];

datetime firstDateTime;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorShortName("Dlabs_CurrencyIndex [" + names[currency] + "]");

   IndicatorBuffers(1);

   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,idx);
   SetIndexLabel(0,"INDEX");

   firstDateTime=StrToTime(firstDate);

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

   ArraySetAsSeries(idx,false);
   ArraySetAsSeries(time,false);

   int limit;
   if(prev_calculated==0)
     {
      idx[0]=100.0;
      limit=1;
        } else {
      limit=prev_calculated-1;
     }

   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      if(time[i]>firstDateTime)
        {
         double contribution=0;
         for(int j=0;j<size-1;j++)
           {
            int shifti=iBarShift(symbols[currency][j],0,time[i],false);
            double priceClosei=iClose(symbols[currency][j],0,shifti);
            
            int shifti1=iBarShift(symbols[currency][j],0,time[i-1],false);
            double priceClosei1=iClose(symbols[currency][j],0,shifti1);
            if(priceClosei1!=0)
              {
               contribution+=(priceClosei-priceClosei1)/priceClosei1*weights[currency][j]/N;
                 } else {
               Print("Price unavailable @ time: ",Time[i],"symbol: ",symbols[currency][j]);
              }
           }
         idx[i]=idx[i-1]*(1+contribution);
           } else {
         idx[i]=100.0;
        }
     }

   return rates_total;
  }
//+------------------------------------------------------------------+
