//+------------------------------------------------------------------+
//|                                                 SAR_Ichimoku.mq5 |
//|                                                          cesreve |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "cesreve"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| Paramètres d'entrée                                              |
//+------------------------------------------------------------------+
input group "Ichimoku Kinko Hyo";
input int tenkan_sen_period        = 9;         // Tenkan
input int kijun_sen_period         = 26;          // Kijun

input group "SAR";
input double step             = 0.06;         // step
input double maximum          = 0.2;          // maximum

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   /*
   // Select the symbol and timeframe
   if (!SymbolSelect("EURUSD", true))
   {
     Print("Failed to select the EUR/USD pair. Please ensure it is available in the Market Watch.");
     return INIT_FAILED;
   }

   if (!PeriodSeconds(PERIOD_H1))
   {
     Print("The H1 timeframe is not available for the EUR/USD pair.");
     return INIT_FAILED;
   }
   //---
   */
   return(INIT_SUCCEEDED);

  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);

   if(time_0==PrevBars)
      return;
   PrevBars=time_0;

//---
   Comment(
      "SAR Value: ", getSAR(1,_Symbol), // index, symbol
      "\nTenkan-Sen: ", getIchimoku(0, 1, _Symbol), // line, index, symbol
      "\nKijun-Sen: ", getIchimoku(1, 1, _Symbol), // line, index, symbol
      "\nclose: ", iClose(_Symbol, PERIOD_CURRENT, 1),
      "\nsignal: ", isSignal(1, _Symbol)
   );

   checkForOpen(_Symbol);
   
   if (isSignal(1, _Symbol)!=0)
         {
            sendNotification(_Symbol);
            Print("notification send");
         }

  }

//+------------------------------------------------------------------+
//| Open postion                                                     |
//+------------------------------------------------------------------+
void checkForOpen(string symbol)
  {
//Print("exécution de checkForOpen");
   double pip = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(PositionsTotal() < 1)
     {
      if(isSignal(1, symbol)==1.0)
        {
         Print("normalement ça achete, spread: ",spread, "pip: ",pip);
         trade.Buy(0.55, symbol, ask, getSAR(1, symbol)-spread*pip, 2*ask - getSAR(1, symbol));
         //trade.Buy()
        }
      else
         if(isSignal(1, symbol)==-1.0)
           {
            trade.Sell(0.55, symbol, bid, getSAR(1, symbol)+spread*pip, 2*bid - getSAR(1, symbol));
            Print("normalement ça vend spread: ",spread);
           }

     }
  }

//+------------------------------------------------------------------+
//| Send notification                                                |
//+------------------------------------------------------------------+
void sendNotification(string symbol)
  {
   //string content = "test";
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   string content = StringFormat("Hello, my name is %s. and the bid is %d.", symbol, bid);
   if(!SendNotification(content))
   {
      Print(content);
   }
   
  }

//+------------------------------------------------------------------+
// Signal
//+------------------------------------------------------------------+
double isSignal(int index, string symbol)
  {

   double signal=0;
// BUY
   if(getSAR(index+1, symbol) > iClose(symbol, PERIOD_CURRENT, index+1) // SAR 2 au dessus du price close 2
      && getSAR(index, symbol) < iClose(symbol, PERIOD_CURRENT, index) // SAR 1 au dessous du price close 1
      && getIchimoku(0, index, symbol) >= getIchimoku(1, index, symbol) // Tenkan 1 supérieure à Kijun 1
      && getIchimoku(0, index, symbol) > getIchimoku(0, index+1, symbol) // Tenkan 1 supérieure à Tenkan 2
     ) // fin du if
     {signal=1.0;}

// SELL
   else
      if(getSAR(index+1, symbol) < iClose(symbol, PERIOD_CURRENT, index+1) // SAR 2 au dessous du price close 2
         && getSAR(index, symbol) > iClose(symbol, PERIOD_CURRENT, index) // SAR 1 au dessus du price close 1
         && getIchimoku(0, index, symbol) <= getIchimoku(1, index, symbol) // Tenkan 1 inférieure à Kijun 1
         && getIchimoku(0, index, symbol) < getIchimoku(0, index+1, symbol) // Tenkan 1 inférieure à Tenkan 2
        ) //fin du else if
        {signal=-1.0;}

   return signal;
  }

//+------------------------------------------------------------------+
// Get SAR values
//+------------------------------------------------------------------+
double getSAR(int index, string symbol)
  {
   double SARBuffer[];
   ArraySetAsSeries(SARBuffer, true);
   int SAR;
   if((SAR=iSAR(symbol, _Period, step, maximum))==INVALID_HANDLE)
     {
      Print("Error creating SAR indicator for: ", symbol);
      return(false);
     }

   if(CopyBuffer(SAR, 0, index, 1, SARBuffer))
     {
      if(ArraySize(SARBuffer) > 0)
        {
         return SARBuffer[0];
        }
     }
   return -1.0;
  }

//+--------------------------------------------------------------------------------------------------------+
//| Get value of buffers for the iIchimoku the buffer numbers are the following:                           |
//| 0 - TENKANSEN_LINE, 1 - KIJUNSEN_LINE, 2 - SENKOUSPANA_LINE, 3 - SENKOUSPANB_LINE, 4 - CHIKOUSPAN_LINE |
//+--------------------------------------------------------------------------------------------------------+
double getIchimoku(int line, int index, string symbol)
  {
   double IchimokuBuffer[];
   ArraySetAsSeries(IchimokuBuffer, true);
   int Ichimoku;
   if((Ichimoku=iIchimoku(symbol, _Period, tenkan_sen_period, kijun_sen_period, 52))==INVALID_HANDLE)
     {
      Print("Error creating Ichimoku indicator for: ", symbol);
      return(false);
     }

   if(CopyBuffer(Ichimoku, line, index, 1, IchimokuBuffer))
     {
      if(ArraySize(IchimokuBuffer) > 0)
        {
         return IchimokuBuffer[0];
        }
     }
   return -1.0;
  }

//+------------------------------------------------------------------+
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
