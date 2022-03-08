//+------------------------------------------------------------------+
//|                                               multi_currency.mq5 |
//|                                             https://www.mql5.com |
//--- objectif:
// ouvirir trades sur plusiers symboles (GBP/USD, EUR/JPY)

//+------------------------------------------------------------------+
#property copyright "ceezer"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;


double point;
string symboles[] = {"GBPUSD", "EURJPY"};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
// Broker digits
   point = _Point;

   double Digits = _Digits;
   if((_Digits == 3) || (_Digits == 5)) {
      point*=10;
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

//---
   Comment(_Symbol);

//--- on boucle dans les symboles
   for (int i=0; i<ArraySize(symboles); i+=1) {

      //--- position opening
      if(symbolPosistionsTotal(symboles[i])<1) {
         //--- get symbol data
         double close = iClose(1, symboles[i]);            
         double sar = getSAR(1, symboles[i]);
         double pip = SymbolInfoDouble(symboles[i], SYMBOL_POINT);

         if(close>sar && sar>0) {
            trade.Buy(0.1, symboles[i], SymbolInfoDouble(symboles[i], SYMBOL_ASK), close-1100*pip, close+500*pip);
           }
         else if(close<sar && sar>0) {
            trade.Sell(0.1, symboles[i], SymbolInfoDouble(symboles[i], SYMBOL_BID), close+1100*pip, close-500*pip);
           }

        }
     }
  }
//+------------------------------------------------------------------+
// Posiition By Symbol
//+------------------------------------------------------------------+
double symbolPosistionsTotal(string symbol) {
   int count = 0;
   for(int i=0; i<PositionsTotal(); i+=1) {
      if(PositionGetSymbol(i) == symbol) {
         count+=1;
        }
     }
     return count;
  }

//+------------------------------------------------------------------+
// Get SAR values
//+------------------------------------------------------------------+
double getSAR(int index, string symbol) {
   double SARBuffer[];
   ArraySetAsSeries(SARBuffer, true);
   int SAR;
   if((SAR=iSAR(symbol, _Period, 0.02, 0.2))==INVALID_HANDLE) {
      Print("Error creating SAR indicator for: ", symbol);
      return(false);
     }

   if(CopyBuffer(SAR, 0, index, 1, SARBuffer)) {
      if(ArraySize(SARBuffer) > 0) {
         return SARBuffer[0];
        }
     }
   return -1.0;
  }
//+------------------------------------------------------------------+ 
//| Get Close for specified bar index                                | 
//+------------------------------------------------------------------+ 
double iClose(const int index,string symbol,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double Close[1];
   double close=0;
   int copied=CopyClose(symbol,timeframe,index,1,Close);
   if(copied>0) close=Close[0];
   return(close);
  }
