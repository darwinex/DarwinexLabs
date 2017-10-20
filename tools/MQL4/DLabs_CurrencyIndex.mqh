//+------------------------------------------------------------------+
//|                                          DLabs_CurrencyIndex.mqh |
//|                                   Copyright 2017, Darwinex Labs. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Darwinex Labs."
#property strict

enum CURRENCY
  {
   EUR=0,
   USD=1,
   GBP=2,
   JPY=3,
   AUD=4,
   NZD=5,
   CHF=6,
   CAD=7
  };

int N=7;

string symbols[8][7]=
  {
   "EURUSD","EURGBP","EURAUD","EURNZD","EURJPY","EURCHF","EURCAD",
   "EURUSD","GBPUSD","AUDUSD","NZDUSD","USDJPY","USDCHF","USDCAD",
   "EURGBP","GBPUSD","GBPAUD","GBPNZD","GBPJPY","GBPCHF","GBPCAD",
   "EURJPY","USDJPY","AUDJPY","NZDJPY","GBPJPY","CHFJPY","CADJPY",
   "EURAUD","AUDUSD","AUDJPY","AUDNZD","GBPAUD","AUDCHF","AUDCAD",
   "EURNZD","NZDUSD","AUDNZD","NZDJPY","GBPNZD","NZDCHF","NZDCAD",
   "EURCHF","NZDCHF","AUDCHF","CHFJPY","GBPCHF","USDCHF","CADCHF",
   "EURCAD","USDCAD","AUDCAD","NZDCAD","GBPCAD","CADCHF","CADJPY"
  };

double weights[8][7]=
  {
   1,1,1,1,1,1,1,
   -1,-1,-1,-1,1,1,1,
   -1,1,1,1,1,1,1,
   -1,-1,-1,-1,-1,-1,-1,
   -1,1,1,1,-1,1,1,
   -1,1,-1,1,-1,1,1,
   -1,-1,-1,1,-1,-1,-1,
   -1,-1,-1,-1,-1,1,1
  };

string names[] = {"EUR","USD","GBP","JPY","AUD","NZD","CHF","CAD"};

int size=8;
int instrumentsSize=28;