//+------------------------------------------------------------------+
//|                                                   MACD_Trend.mq5 |
//|                                                           ceezer |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ceezer"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

input group "MACD";
input int    fast_ma_period         = 12;      // fast_ma_period
input int    slow_ma_period         = 26;       // slow_ma_period
input int    signal_period          = 9;       // signal_period

input group "Moving Average";
input int    ma_period        = 200;      // ma_period
input int    ma_shift         = 0;       // ma_shift


//input group "fractal";
//input int    ma_period        = 20;      // ma_period
//input int    ma_shift         = 0;       // ma_shift
//input double bbdeviation      = 2;       // bbdeviation
//
//input group "Trade";
//input double inputlot         = 0.1;     // volume
//input int    pipsaveraging    = 25;      // latent loss to reopen in pips



#define MA_MAGIC 05092021
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- Define Magic
   trade.SetExpertMagicNumber(MA_MAGIC);

//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   Comment(
      "MACD MAIN 0: ", getMACD(0, 0),
      "\nMACD MAIN 1: ", getMACD(0, 1),
      "\nMACD MAIN 2: ",getMACD(0, 2),
      "\nMACD SIGNAL 0: ",getMACD(1, 0),
      "\nMACD SIGNAL 1: ",getMACD(1, 1),
      " \n MACD SIGNAL 2: ",getMACD(1, 2),
//"EMA 200 0: ", getMA(0),
      "\nlast fractal up: ", getLastFractal(0),
      "\nlast fractal down: ", getLastFractal(1)
      //"\nsignal: ", CheckForOpen()
   );
   
   if(PositionAllowed())
      CheckForOpen();
   
  }

//+------------------------------------------------------------------+
//| ouverture de position                                            |
//+------------------------------------------------------------------+
string CheckForOpen() {

   MqlRates rt[2];
//--- go trading only for first ticks of new bar
   if(CopyRates(_Symbol,_Period,0,2,rt)!=2) {
      Print("CopyRates of ",_Symbol," failed, no history");
     }

//--- check signals
   ENUM_ORDER_TYPE signal=WRONG_VALUE;
//--- short
// close < EMA200
// MACD > 0, signal >0
// MACD-1 > signal-1 && MACD < signal
   if(rt[1].close<getMA(1) && getMACD(0,1)>=0 && getMACD(1,1)>=0 && getMACD(0,2)>getMACD(1,2) &&  getMACD(0,1)<getMACD(1,1))
      signal=ORDER_TYPE_SELL;    // sell conditions
//--- long
// close > EMA200
// MACD < 0, signal <0
// MACD-1 < signal-1 && MACD > signal
   else {
      if(rt[1].close>getMA(1) && getMACD(0,1)<=0 && getMACD(1,1)<=0 && getMACD(0,2)<getMACD(1,2) &&  getMACD(0,1)>getMACD(1,1))
         signal=ORDER_TYPE_BUY;  // buy conditions
     }
//--- additional checking
   if(signal!=WRONG_VALUE) {
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && Bars(_Symbol,_Period)>100)
         trade.PositionOpen(_Symbol,signal,1,
                            SymbolInfoDouble(_Symbol,signal==ORDER_TYPE_SELL ? SYMBOL_BID:SYMBOL_ASK),
                            signal==ORDER_TYPE_SELL ? getLastFractal(0)*1.001:getLastFractal(1)*0.999,
                            signal==ORDER_TYPE_SELL ? rt[1].close - 1.5*MathAbs(rt[1].close- getLastFractal(0)):rt[1].close + 1.5*MathAbs(rt[1].close - getLastFractal(1)));
                            
     }
      return EnumToString(signal);
     }
     
//+------------------------------------------------------------------+
//--- Is Position Allowed
//+------------------------------------------------------------------+
bool PositionAllowed() {
   bool allowed = false;
   if(PositionsTotal()<1) {
      allowed = true;
     }
   return allowed;
  }
  
//+------------------------------------------------------------------+
// Get MACD values
// 0 - MAIN_LINE, 1 - SIGNAL_LINE.
//+------------------------------------------------------------------+
double getMACD(int ligne, int index) {
   double MACDBuffer[];
   ArraySetAsSeries(MACDBuffer, true);
   int MACD = iMACD(_Symbol, _Period, fast_ma_period, slow_ma_period, signal_period, PRICE_CLOSE);

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
double getMA(int index) {
   double MABuffer[];
   ArraySetAsSeries(MABuffer, true);
   int MA = iMA(_Symbol, _Period, ma_period, ma_shift, MODE_EMA, PRICE_CLOSE);

   if(CopyBuffer(MA, 0, index, 1, MABuffer)) {
      if(ArraySize(MABuffer) > 0) {
         return MABuffer[0];
        }
     }
   return -1.0;
  }

//+------------------------------------------------------------------+
// Get fractals
// 0 - UPPER_LINE, 1 - LOWER_LINE
//+------------------------------------------------------------------+
double getLastFractal(int ligne) {
   double FractalBuffer[];
   double FractalValue = 0;
   ArraySetAsSeries(FractalBuffer, true);
   int Fractals = iFractals(_Symbol, _Period);

   if(CopyBuffer(Fractals, ligne, 1, 20, FractalBuffer)) {
      if(ArraySize(FractalBuffer) > 0) {

         for(int i= 1; i<10; i++) {
            FractalValue = FractalBuffer[i];
            if(FractalValue != EMPTY_VALUE) break;
           }
         return FractalValue;
        }
     }
   return -1.0;
  }

///////////////////////////////////
// conditions pour ouverture :
//--- long
// close > EMA200
// MACD < 0, signal <0
// MACD-1 < signal-1 && MACD > signal
//--- short
// close < EMA200
// MACD > 0, signal >0
// MACD-1 > signal-1 && MACD < signal




///////////////////////////////////
// gerer cloture partielle
// 25% position à 1:1
// B/E à 1:1
// cloture full sur TP à 2:1
// récupération prix fractale
// ajustement stop avec le spread
// verifier que SL "suffisament loin"
// gestion des digits

///////////////////////////////////
// auto lot size
