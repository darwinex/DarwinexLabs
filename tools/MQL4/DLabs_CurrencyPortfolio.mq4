//+------------------------------------------------------------------+
//|                                      DLabs_CurrencyPortfolio.mq4 |
//|                                   Copyright 2018, Darwinex Labs. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Darwinex Labs."
#property strict

#property script_show_inputs
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 DodgerBlue

input string Portfolio_Info = "Enter Symbols & Weights (sep. by commas)";

//--- input parameters
input string Portfolio_Assets = "NZDCHF,GBPJPY,AUDUSD,EURCAD";

input string Portfolio_Weights = "-1,1,1,-1";

input string Analysis_Info = "Enter Analysis Start Date Below";
input string StartDate = "2017.01.01";

//--Buffers indexes
double idx[];
string symbolArray[];
string weightArray[];
string portfolioAllocations = "";
int numSymbols = 0;
int numWeights = 0;
datetime firstDateTime;

int yOffset = 20;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   numSymbols = StringSplit(Portfolio_Assets,StringGetCharacter(",",0),symbolArray);
   numWeights = StringSplit(Portfolio_Weights,StringGetCharacter(",",0),weightArray);
      
   // Check Symbols match Weights
   if(numSymbols != numWeights) {
      Alert("No. of Symbols MUST MATCH No. of Weights. Exiting..");
      return(INIT_FAILED);
   }
   
   IndicatorShortName("[Darwinex Labs] Currency Portfolio Constructor");
   IndicatorBuffers(1);

   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,idx);
   SetIndexLabel(0,"PORTFOLIO");

   firstDateTime=StrToTime(StartDate);

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

   PrintOnIndicatorWindow(Portfolio_Assets, Portfolio_Weights, yOffset);
   
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
         for(int j=0;j<numSymbols;j++)
           {
            int shifti=iBarShift(symbolArray[j],0,time[i],false);
            double priceClosei=iClose(symbolArray[j],0,shifti);
            
            int shifti1=iBarShift(symbolArray[j],0,time[i-1],false);
            double priceClosei1=iClose(symbolArray[j],0,shifti1);
            if(priceClosei1!=0)
              {
               contribution+=(priceClosei-priceClosei1)/priceClosei1*StrToDouble(weightArray[j])/SumOfStringArray(weightArray);
                 } else {
               Print("Price Unavailable @ Time: ",Time[i]," | Symbol: ",symbolArray[j]);
              }
           }
         idx[i]=idx[i-1]*(1+contribution);
           } else {
         idx[i]=100.0;
        }
     }

   return rates_total;
  }
  
void PrintOnIndicatorWindow(string strSymbols, string strWeights, int drawYOffset) {
   
   int window_index = ChartWindowFind();
   string currentObject = "";
   
   if (window_index != -1) {
      ObjectDelete("Portfolio_Symbols");
      ObjectDelete("Portfolio_Allocations1");
      ObjectDelete("Portfolio_Allocations2");
      
      currentObject = "Portfolio_Symbols";
      
      ObjectCreate(currentObject,  OBJ_LABEL, window_index, 0, 0);
      ObjectSet(currentObject, OBJPROP_CORNER, 0);
      ObjectSet(currentObject, OBJPROP_XDISTANCE, 10);
      ObjectSet(currentObject, OBJPROP_YDISTANCE, 10+drawYOffset);
      
      StringReplace(strSymbols, ",", ", ");
      ObjectSetText(currentObject, strSymbols, 10, "Times New Roman", DodgerBlue);
      
      
      currentObject = "Portfolio_Allocations1";
      
      ObjectCreate(currentObject,  OBJ_LABEL, window_index, 0, 0);
      ObjectSet(currentObject, OBJPROP_CORNER, 0);
      ObjectSet(currentObject, OBJPROP_XDISTANCE, 10);
      ObjectSet(currentObject, OBJPROP_YDISTANCE, 10+drawYOffset*2);
      ObjectSetText(currentObject, "Portfolio Allocations:", 10, "Times New Roman", White);
      
      
      currentObject = "Portfolio_Allocations2";
      
      ObjectCreate(currentObject,  OBJ_LABEL, window_index, 0, 0);
      ObjectSet(currentObject, OBJPROP_CORNER, 0);
      ObjectSet(currentObject, OBJPROP_XDISTANCE, 10);
      ObjectSet(currentObject, OBJPROP_YDISTANCE, 10+drawYOffset*3);
      ObjectSetText(currentObject, GeneratePortfolioAllocations(weightArray), 10, "Times New Roman", White);
      
   } else {
      // Do nothing
   }
}

double SumOfStringArray ( string& strArray[] ) 
{
   double retSum = 0.0;
   
   for(int i = 0; i < ArraySize(strArray); i++ )
   {
      retSum = retSum + MathAbs(StringToDouble(strArray[i]));
   }
   
   return(retSum);
}

string GeneratePortfolioAllocations(string& strWeightArray[])
{
   string retStr = "";
   double wsum = SumOfStringArray(strWeightArray);
   
   for (int i = 0; i < ArraySize(strWeightArray); i++ )
   {
      retStr = retStr + DoubleToStr(StringToDouble(strWeightArray[i]) / wsum, 3);
      
      if ( i < ArraySize(strWeightArray) - 1 )
      {
         retStr = retStr + ", ";
      }
   }
   
   return(retStr);
}

//+------------------------------------------------------------------+
