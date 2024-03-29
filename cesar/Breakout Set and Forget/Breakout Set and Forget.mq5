//+------------------------------------------------------------------+
//|                                      Breakout Set and Forget.mq5 |
//+------------------------------------------------------------------+
//--- Description
/*
Breakout Set and Forget 

Strategy from tradePro on youtube
trade on USDJPY
Find a 24 hour high and low range based on 6pm EST
Entries are at 7 pips above below the range
3 entries above and 3 entries below
Each entry has a 25 pips SL
Seperate tp for each entry, 15, 35, 50

Risk 1% per position - based on the 25 pips SL
total 3% risk perday
Assumed using equity risk

When one  entry target is hit, cancel the opposite

Optional:
break even when the first tp is hit

If one entry target is not hit on a day then it will cleared the next day

*/
#property copyright ""
#property link      ""
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade Trade;
CPositionInfo PositionInfo;
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
// Time Range
input int InpRangeStartHour   = 1; // Range Start hour
input int InpRangeStartMinute = 0; // Range Start minute
input int InpRangeEndHour     = 1; // Range End hour
input int InpRangeEndMinute   = 0; // Range End minute

// Entry inputs
input double InpRangeGapPips     = 7.0;   // Entry gap from outer range pips
input double InpStopLossPips     = 25.0;  // Stop loss pips
input double InpTakeProfit1Pips  = 15.0;  // Take profit 1 in pips
input double InpTakeProfit2Pips  = 35.0;  // Take profit 2 in pips
input double InpTakeProfit3Pips  = 50.0;  // Take profit 3 in pips

// Standard features
input long InpMagic           = 147;            // Magic Number
input string InpTradeComment  = "SnF Breakout"; // Expert comment
input double InpRiskPercent   = 1.0;            //Risk percent

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
double RangeGap = 0; 
double StopLoss = 0;
double TakeProfit1 = 0;
double TakeProfit2 = 0;
double TakeProfit3 = 0;
double Risk = 0.0;

datetime StartTime = 0;
datetime EndTime   = 0;
bool InRange = false;

double BuyEntryPrice = 0;
double SellEntryPrice = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()  {
   
//--- Validate range times
   bool inputsOK = true;

   if(InpRangeStartHour < 0 || InpRangeStartHour > 23) {
      Print("Start hour must be from 0 - 23");
      inputsOK = false;
   }      
   if(InpRangeStartMinute < 0 || InpRangeStartMinute > 59) {
      Print("Start minute must be from 0 - 59");
      inputsOK = false;
   }            
   if(InpRangeEndHour < 0 || InpRangeEndHour > 23) {
      Print("End hour must be from 0 - 23");      
      inputsOK = false;
   }     
   if(InpRangeEndMinute < 0 || InpRangeEndMinute > 59) {
      Print("End minute must be from 0 - 59");
      inputsOK = false;
   }   
   if(InpRangeGapPips < 0) {
      Print("Range Gap must be > 0");
      inputsOK = false;
   }      
   if(InpStopLossPips < 0) {
      Print("Stop loss must be > 0");    
      inputsOK = false;
   }     
   if(InpTakeProfit1Pips < 0) {
      Print("Take profit must be > 0");
      inputsOK = false;
   }  
   if(InpTakeProfit2Pips < 0) {
      Print("Take profit must be > 0");
      inputsOK = false;
   }  
   if(InpTakeProfit3Pips < 0) {
      Print("Take profit must be > 0");
      inputsOK = false;
   }
   
   if(!inputsOK) { return INIT_PARAMETERS_INCORRECT; }

//---
   Risk = InpRiskPercent/100;

//---
   RangeGap = PipsToDouble(InpRangeGapPips);
   StopLoss = PipsToDouble(InpStopLossPips);
   TakeProfit1 = PipsToDouble(InpTakeProfit1Pips);
   TakeProfit2 = PipsToDouble(InpTakeProfit2Pips);
   TakeProfit3 = PipsToDouble(InpTakeProfit3Pips);
   
   BuyEntryPrice = 0;
   SellEntryPrice = 0;
   
   Trade.SetExpertMagicNumber(InpMagic);
//--- first find the setup for the starting time range
   datetime now = TimeCurrent();
   EndTime = SetNextTime(now+60, InpRangeEndHour, InpRangeEndMinute);
   StartTime = SetPrevTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
   InRange = (now >= StartTime && EndTime > now);
   

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
//---
   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   datetime now = TimeCurrent();
   bool currentlyInRange = (StartTime<=now && now<EndTime);
   
   if(InRange && !currentlyInRange) {
      SetTradeEntries();
   }   
   if(now>=EndTime) {
      EndTime = SetNextTime(EndTime+60, InpRangeEndHour, InpRangeEndMinute);
      StartTime = SetPrevTime(EndTime, InpRangeStartHour, InpRangeStartMinute);   
   }   
   InRange = currentlyInRange;
   
   double currentPrice = 0;
   if(BuyEntryPrice > 0) {
      currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      if(currentPrice >= BuyEntryPrice) {
         OpenTrade(ORDER_TYPE_BUY, currentPrice);
         BuyEntryPrice = 0;
         SellEntryPrice = 0;
      }
   }
   if(SellEntryPrice > 0) {
      currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      if(currentPrice <= SellEntryPrice) {
         OpenTrade(ORDER_TYPE_SELL, currentPrice);
         BuyEntryPrice = 0;
         SellEntryPrice = 0;
      }
   }
}

//+------------------------------------------------------------------+
datetime SetNextTime(datetime now, int hour, int minute) {
   
   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);
   
   nowStruct.sec = 0;
   datetime nowTime = StructToTime(nowStruct);
   
   nowStruct.hour = hour;
   nowStruct.min = minute;
   datetime nextTime = StructToTime(nowStruct);
   
   while(nextTime < nowTime || !IsTradingDay(nextTime)) {
      nextTime += 86400;
   }   
   return nextTime;
}
//+------------------------------------------------------------------+
datetime SetPrevTime(datetime now, int hour, int minute) {
   
   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);
   
   nowStruct.sec = 0;
   datetime nowTime = StructToTime(nowStruct);
   
   nowStruct.hour = hour;
   nowStruct.min = minute;
   datetime prevTime = StructToTime(nowStruct);
   
   while(prevTime >= nowTime || !IsTradingDay(prevTime)) {
      prevTime -= 86400;
   }   
   return prevTime;
}
//+------------------------------------------------------------------+
bool IsTradingDay(datetime time) {
   MqlDateTime timeStruct;
   TimeToStruct(time, timeStruct);
   datetime fromTime;
   datetime toTime;
   return SymbolInfoSessionTrade(Symbol(), (ENUM_DAY_OF_WEEK)timeStruct.day_of_week, 0, fromTime, toTime);
}
//+------------------------------------------------------------------+
double PipsToDouble(double pips) {

    return PipsToDouble(Symbol(), pips);
}
//---
double PipsToDouble(string symbol, double pips) {

   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if (digits==3 || digits==5) {
      pips = pips * 10;
      }
   double value = pips * SymbolInfoDouble(symbol, SYMBOL_POINT);   
   return value;      
}
//+------------------------------------------------------------------+
void SetTradeEntries(){
   
   int startBar = iBarShift(Symbol(), PERIOD_M1, StartTime, false);
   int endBar = iBarShift(Symbol(), PERIOD_M1, EndTime-60, false);
   
   double high = iHigh(Symbol(), PERIOD_M1, iHighest(Symbol(), PERIOD_M1, MODE_HIGH,startBar-endBar+1, endBar));
   double low = iLow(Symbol(), PERIOD_M1, iLowest(Symbol(), PERIOD_M1, MODE_LOW,startBar-endBar+1, endBar));
   
   BuyEntryPrice = high + RangeGap;
   SellEntryPrice = low - RangeGap;
}
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE type, double price) {

   if(!OpenTrade(type, price, StopLoss, TakeProfit1)) return;
   if(!OpenTrade(type, price, StopLoss, TakeProfit2)) return;
   if(!OpenTrade(type, price, StopLoss, TakeProfit3)) return;
}
bool OpenTrade(ENUM_ORDER_TYPE type, double price, double stopLoss, double takeProfit) {

   double tp = 0;      
   if(type==ORDER_TYPE_BUY) {
      tp = price + takeProfit;
   } else {
      tp = price - takeProfit;
   }
   
   double sl = 0;   
   if(type==ORDER_TYPE_BUY) {
      sl = price - stopLoss;
   } else {
      sl = price + stopLoss;
   }
   
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   price = NormalizeDouble(price, digits);
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);
   double volume = GetRiskVolume(Risk, MathAbs(price-sl));
   
   if(!Trade.PositionOpen(Symbol(), type, volume, price, sl, tp, InpTradeComment)) {
      PrintFormat("Error opening trade, typ=%s, volume=%f, price=%f, sl=%f, tp=%f", 
                  EnumToString(type), volume, price, sl, tp);
      return false;          
   }
   return true;
}
//+------------------------------------------------------------------+
double GetRiskVolume(double risk, double loss) {
   
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskAmout = risk * equity;
   
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double lossTicks = loss / tickSize;
   
   double volume = riskAmout / (lossTicks * tickValue);
   //volume = NormaliseVolume(volume);
   volume = 0.01;
   
   return volume;      
}  
//+------------------------------------------------------------------+
double NormaliseVolume(double volume) {
   
   if(volume==0) {return 0;}
   
   double max = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double min = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   
   double result = MathRound(volume/step) * step;
   if(result>max) {result = max;}
   if(result<min) {result = min;}
   
   return result;   
}