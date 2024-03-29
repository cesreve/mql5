//+------------------------------------------------------------------+
//|                                                     SAR8mACD.mq5 |
//|                                                           ceezer |
//+------------------------------------------------------------------+
// cumuler ordres,
// odres qui restent ouverts super longtemps et qui bloquent le trading
// régler le sizing automatique
// faire le multi TF ?
#property copyright "ceezer"
#property version   "1.00"


#include <Trade\Trade.mqh>
CTrade trade;

input group "MACD";
input int    fast_ma_period         = 12;      // fast_ma_period
input int    slow_ma_period         = 26;      // slow_ma_period
input int    signal_period          = 9;       // signal_period

input group "Moving Average";
input int    ma_period        = 200;          // ma_period
input int    ma_shift         = 0;            // ma_shift

input group "SAR";
input double step             = 0.02;         // step
input double maximum          = 0.2;          // maximum

double point;

#define MA_MAGIC 05092021
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- Define Magic
   trade.SetExpertMagicNumber(MA_MAGIC);

//--- Broker digits
   point = _Point;

   double Digits = _Digits;
   if((_Digits == 3) || (_Digits == 5)) {
      point*=10;
     }

//if(getMA(0, _Symbol)<=0 || getMACD(0, 0, _Symbol)<=0 || getSAR(0, _Symbol)<=0) {
//   return(INIT_FAILED);
//  }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//--- closing positions
   checkPartClose(_Symbol);

//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);

   if(time_0==PrevBars)
      return;
   PrevBars=time_0;

   Comment("signal: ", isSignal(1, _Symbol),
           "\npositions ouvertes: ", symbolPosistionsTotal(_Symbol),
           "\nMACD 1: ", getMACD(0, 1, _Symbol),
           "\nMACD signal 1: ", getMACD(1, 1, _Symbol),
           "\nMA 1: ", getMA(1, _Symbol),
           "\nSAR 1: ", getSAR(1,_Symbol),
           "\nclose 1: ",iClose(_Symbol,_Period,1),
           "\nspread: ", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD),
           "\npip: ",SymbolInfoDouble(_Symbol, SYMBOL_POINT)
          );

   checkForOpen(_Symbol);
  }

//+------------------------------------------------------------------+
// Open position
//+------------------------------------------------------------------+
void checkForOpen(string symbol) {
//Print("exécution de checkForOpen");
   double pip = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   if(symbolPosistionsTotal(symbol)<1 && isSignal(1, symbol)==1.0) {
      Print("normalement ça achete, spread: ",spread);
      trade.Buy(0.55, symbol, ask, getSAR(1, symbol)-spread*pip, 0.0);
     }
   else if(symbolPosistionsTotal(symbol)<1 && isSignal(1, symbol)==-1.0) {
      trade.Sell(0.55, symbol, bid, getSAR(1, symbol)+spread*pip, 0.0);
      Print("normalement ça vend spread: ",spread);
     }
  }

//+------------------------------------------------------------------+
//| checking partial closing                                         |
//+------------------------------------------------------------------+
void checkPartClose(string symbol) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket>0) {
         PositionSelectByTicket(ticket);
         if(PositionGetSymbol(i) == symbol) {
            double posSL = PositionGetDouble(POSITION_SL);
            double posPROPN = PositionGetDouble(POSITION_PRICE_OPEN);
            double posPRCUR = PositionGetDouble(POSITION_PRICE_CURRENT);
            double posVOLUME = PositionGetDouble(POSITION_VOLUME);

            double minVOLUME = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

            ENUM_POSITION_TYPE posType;
            posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if(posSL>0.0) {
               if(MathAbs(posPROPN-posPRCUR) > MathAbs(posSL-posPROPN)) {
                  Print("that should be goud ! ");
                  double newVOL = floor(0.5*posVOLUME*100)/100;
                  Print(newVOL);
                  trade.PositionClosePartial(ticket, newVOL);
                  Print("modify position");
                  trade.PositionModify(ticket, 0.0, 0.0);
                 }
              }
            // si le stop loss n'est pas > à 0 on teste le trailing stop 
            else trailingSAR(ticket, symbol);
           }
        }
     }
  }

//+------------------------------------------------------------------+
// CTrailing stop function
// ajouter le BE avec le price open ou bien avec current profit (qui prends en compte le swap etc...)
//+------------------------------------------------------------------+
void trailingSAR(ulong ticket, string symbol) {
   double sar = getSAR(1, symbol);

// position informations
   PositionSelectByTicket(ticket);
   ENUM_POSITION_TYPE posType;
   double posSL = PositionGetDouble(POSITION_SL);
   double posPRCUR = PositionGetDouble(POSITION_PRICE_CURRENT);
   posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

// conditions
   if(posSL==0.0) {

      if(posType==POSITION_TYPE_BUY && PositionGetDouble(POSITION_PRICE_CURRENT)<sar) {
         trade.PositionClose(ticket);
         Print("clsd B pos TS");
        }
        
      else if(posType==POSITION_TYPE_SELL && PositionGetDouble(POSITION_PRICE_CURRENT)>sar) {
         trade.PositionClose(ticket);
         Print("clsd S pos TS");
        }
     }
  }

//+------------------------------------------------------------------+
// Signal
//+------------------------------------------------------------------+
double isSignal(int index, string symbol) {

   double signal=0;

   if(getMACD(0, index, symbol)>getMACD(1, index, symbol) && // MACD > MACD signal
         iClose(symbol, PERIOD_CURRENT, index)>getMA(index, symbol) && // price close > EMA200
         iClose(symbol, PERIOD_CURRENT, index)>getSAR(index, symbol)) { // price close > SAR
      signal=1.0;
      //Print("signal haussier");
     }
   else if(getMACD(0, index, symbol)<getMACD(1, index, symbol) && // MACD < MACD signal
           iClose(symbol, PERIOD_CURRENT, index)<getMA(index, symbol) && // price close < EMA200
           iClose(symbol, PERIOD_CURRENT, index)<getSAR(index, symbol)) { // price close < SAR
      //Print("signal baissier");
      signal=-1.0;
     }
   return signal;
  }

//+------------------------------------------------------------------+
//| Autolot size                                                     |
//+------------------------------------------------------------------+
double Lotsize(double absoluterisk, double stoploss) {
   double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
   double lots = absoluterisk / (PipValue * (stoploss)/point);
   lots = floor(lots * 100) / 100;

   return lots;
  }

//+------------------------------------------------------------------+
// Position By Symbol and EA
//+------------------------------------------------------------------+
double symbolPosistionsTotal(string symbol) {
   int count = 0;
   long magic = PositionGetInteger(POSITION_MAGIC);
   for(int i=0; i<PositionsTotal(); i+=1) {
      if(PositionGetSymbol(i) == symbol && MA_MAGIC==magic) {
         count+=1;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
// Get MACD values
// 0 - MAIN_LINE, 1 - SIGNAL_LINE.
//+------------------------------------------------------------------+
double getMACD(int ligne, int index, string symbol) {
   double MACDBuffer[];
   ArraySetAsSeries(MACDBuffer, true);
   int MACD;
   if((MACD=iMACD(symbol, _Period, fast_ma_period, slow_ma_period, signal_period, PRICE_CLOSE))==INVALID_HANDLE) {
      Print("Error creating MACD indicator for: ", symbol);
      return(false);
     }

   if(CopyBuffer(MACD, ligne, index, 1,MACDBuffer)) {
      if(ArraySize(MACDBuffer) > 0) {
         return MACDBuffer[0]*10000;
        }
     }
   return -1.0;
  }

//+------------------------------------------------------------------+
// Get MA values
//+------------------------------------------------------------------+
double getMA(int index, string symbol) {
   double MABuffer[];
   ArraySetAsSeries(MABuffer, true);
   int MA;
   if((MA=iMA(symbol, _Period, ma_period, ma_shift, MODE_EMA, PRICE_CLOSE))==INVALID_HANDLE) {
      Print("Error creating MA indicator for: ", symbol);
      return(false);
     }

   if(CopyBuffer(MA, 0, index, 1, MABuffer)) {
      if(ArraySize(MABuffer) > 0) {
         return MABuffer[0];
        }
     }
   return -1.0;
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
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT) {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0) time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
