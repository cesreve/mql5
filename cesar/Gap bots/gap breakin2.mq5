//+------------------------------------------------------------------+
//|                                                     gapclose.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
// Time inputs
//--- range inputs
input group "==== Hours ====";
input int InpMktCloseHour    = 17; // Market Close hour
input int InpMktCloseMinute  = 30; // Market Close minute
input int InpMktOpenHour     = 10; // Market Open hour
input int InpMktOpenMinute   = 00; // Market Open minute

//--- trade inputs
input int InpStopLoss   = 30; // stop loss
input int InpTakeProfit = 30; // take profit
input int InpGapTresh   = 15; // gap treshold
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;
MqlDateTime nowTimeStruct;
//--- times
int mktCloseHour     = InpMktCloseHour;
int mktCloseMinute   = InpMktCloseMinute;
int mktOpenHour      = InpMktOpenHour;
int mktOpenMinute    = InpMktOpenMinute;


datetime now;
datetime mktClose    = 0;
datetime mktOpen     = 0;
datetime mktYestOpen = 0;

double openPrice = 0;
double closePrice = 0;
double prevHigh = 0;
double prevLow = 0;

bool tradeAllowed = true;

string comm = "";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   calculateDatetimes();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   now = TimeCurrent();
   TimeToStruct(now, nowTimeStruct);
   SymbolInfoTick(Symbol(), tick);
//---
   calculateDatetimes();
   SetPrevTime();
   peakBetweenTwoHours(mktYestOpen, mktClose);
//---
   if(now < mktOpen) {
      ObjectCreate(0, "line up", OBJ_HLINE,0,mktOpen,prevHigh);
      ObjectCreate(0, "line down", OBJ_HLINE,0,mktOpen,prevLow);
      return;}

//---
   if(IsNewDay()) {tradeAllowed = true;}
   
//---
   if(iTime(Symbol(),Period(),0) == mktOpen && tradeAllowed) 
   {
      //Print("time is 10");
      double ask = tick.ask;
      double bid = tick.bid;
      double gap = 0;
      if(prevLow - ask > InpGapTresh) {
         gap = prevLow - ask;
         Print(gap);
         trade.BuyStop(5, prevLow, Symbol(), prevLow - InpStopLoss,  prevLow + InpTakeProfit, ORDER_TIME_DAY);         
         }
      if(bid - prevHigh > InpGapTresh) {
         gap = bid - prevHigh;
         Print(gap);
         trade.SellStop(5, prevHigh, Symbol(), prevHigh + InpStopLoss, prevHigh - InpTakeProfit, ORDER_TIME_DAY);
      }
      tradeAllowed = false;
   }
//---   
   int closePos = iBarShift(Symbol(), PERIOD_M30, mktClose);
   closePrice = iOpen(Symbol(), PERIOD_M30, closePos);
   
   int openPos = iBarShift(Symbol(), PERIOD_M30, mktOpen);
   openPrice = iOpen(Symbol(), PERIOD_M30, openPos);
  
//---
   drawRectangle();
   
  }  /// ------> end of the OnTick function

//+------------------------------------------------------------------+
//- Calculate datetimes  --------------------------------------------+
void calculateDatetimes()
{
   //--- convert to times   
   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);   
   nowStruct.sec = 0;
   
   // close
   nowStruct.hour = mktCloseHour;
   nowStruct.min = mktCloseMinute;
   mktClose = StructToTime(nowStruct);
   
   // open 
   nowStruct.hour = mktOpenHour;
   nowStruct.min = mktOpenMinute;
   mktOpen = StructToTime(nowStruct);
      
}

//+------------------------------------------------------------------+
//- Set times   -----------------------------------------------------+
void SetPrevTime() { 
   
   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);
   
   nowStruct.sec = 0;
   datetime nowTime = StructToTime(nowStruct);
   
   nowStruct.hour = mktCloseHour;
   nowStruct.min  = mktCloseMinute;
   mktClose = StructToTime(nowStruct);
   
   while(mktClose >= nowTime || !IsTradingDay(mktClose)) {
      mktClose -= 86400;
   }
   MqlDateTime prevDay;
   TimeToStruct(mktClose, prevDay);
   prevDay.hour = mktOpenHour;
   prevDay.min  = mktOpenMinute;
   mktYestOpen = StructToTime(prevDay);
   
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
//- High between 2 hours  -------------------------------------------+
void peakBetweenTwoHours(datetime startTime, datetime endTime)
{
   if(!(endTime>=startTime)) {Print("endTime must be superior to startTime");}
   
   else {   
      int startRangePos = iBarShift(Symbol(),PERIOD_M30,startTime);
      int endRangePos   = iBarShift(Symbol(),PERIOD_M30,endTime);
      int barCount      = startRangePos - endRangePos + 1;
      
      prevHigh = iHigh(Symbol(),PERIOD_M30,iHighest(Symbol(),PERIOD_M30,MODE_HIGH,barCount,endRangePos));
      prevLow  = iLow(Symbol(),PERIOD_M30,iLowest(Symbol(),PERIOD_M30,MODE_LOW,barCount,endRangePos)); 
      
   }
}
//+------------------------------------------------------------------+
//- Draw rectangles   -----------------------------------------------+
void drawRectangle() {

   if(mktOpen > mktClose) {
      if(openPrice > closePrice) {
         ObjectCreate(0, "rectangle gap", OBJ_RECTANGLE, 0, mktClose, closePrice, mktOpen, openPrice);
         ObjectSetInteger(0, "rectangle gap", OBJPROP_BACK, true);
         ObjectSetInteger(0, "rectangle gap", OBJPROP_FILL, true);
         ObjectSetInteger(0, "rectangle gap", OBJPROP_COLOR, clrGreen);
         }
      if(openPrice < closePrice) {
         ObjectCreate(0, "rectangle gap", OBJ_RECTANGLE, 0, mktClose, closePrice, mktOpen, openPrice);
         ObjectSetInteger(0, "rectangle gap", OBJPROP_BACK, true);
         ObjectSetInteger(0, "rectangle gap", OBJPROP_FILL, true);
         ObjectSetInteger(0, "rectangle gap", OBJPROP_COLOR, clrRed);
         }
   }
}
//+------------------------------------------------------------------+
//- New Day  --------------------------------------------------------+
bool IsNewDay()
  {
   static datetime previousDay = 0;
   datetime currentDay = StringToTime(StringSubstr(TimeToString(iTime(Symbol(),PERIOD_M1,0)),0,11));
   if(previousDay!=currentDay) {
      Print("new day");
      previousDay=currentDay;
      return true;
     }
   return false;  
  }  