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

//double closePrice;
//double openPrice;

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
   Comment(IsTradingDay(now));
//---
   calculateDatetimes();
   SetPrevTime();
   peakBetweenTwoHours(mktYestOpen, mktClose);
//---
   if(now < mktOpen) {
      //ObjectCreate(0, "New Day",OBJ_VLINE,0,iTime(_Symbol,_Period,0),0);
      //ObjectCreate(0, "line up" , OBJ_HLINE, 0, prevHigh, 0);
      ObjectCreate(0, "line up", OBJ_HLINE,0,mktOpen,prevHigh);
      //ObjectCreate(0, "line down" , OBJ_HLINE, 0, prevLow,0);
      ObjectCreate(0, "line down", OBJ_HLINE,0,mktOpen,prevLow);
      return;}
   //if(now > mktOpen) {Print("hour");}

//---
   if(IsNewDay()) {tradeAllowed = true;}
//---
   if(iTime(Symbol(),Period(),0) == mktOpen && tradeAllowed) 
   {
      Print("time is 10");
      double ask = tick.ask;
      double bid = tick.bid;
      if(bid > prevHigh) {
         trade.SellStop(0.1, prevHigh, Symbol(), prevHigh + 30, prevHigh - 30, ORDER_TIME_DAY);
         tradeAllowed = false;
      }
      if(ask < prevLow) {
         trade.BuyStop(0.1, prevLow, Symbol(), prevLow - 30,  prevLow + 30, ORDER_TIME_DAY);
         tradeAllowed = false;
      }
   }
//---   
   int closePos = iBarShift(Symbol(), PERIOD_M30, mktClose);
   closePrice = iOpen(Symbol(), PERIOD_M30, closePos);
   
   int openPos = iBarShift(Symbol(), PERIOD_M30, mktOpen);
   openPrice = iOpen(Symbol(), PERIOD_M30, openPos);
  
//---
//   si heure >= heure ouverture
//      calculer le prix ouverture         
//         siprix à l'ouverture est supérieur à plus haut de hier
//         sell stop au prix le plus haut de la veille
//   
//         si prix à l'ouverture est inférieur à plus bas de la veille
//         buy stop au prix le plus bas de la veille 
//         
//         sinon on ne fait rien
//---
   // faire rectangle entre bougie la plus haute/basse et ouverture
   drawRectangle();


//--- Comments
   comm = "";
   comm += (string)now;   
   comm += "\n";
   comm += (string)mktYestOpen;
   comm += "\n";
   comm += (string)prevHigh;
   comm += "\n";
   comm += (string)prevLow;
   comm += "\n";
   comm += (string)mktClose;
   comm += "\n";
   comm += (string)mktOpen;
   comm += "\n";
   comm += "\n high gap over prev High  ";
   comm += (string)(openPrice > prevHigh);
   //comm += "\n";
   comm += "\n low gap under prev Low  ";
   comm += (string)(openPrice < prevLow);
   //comm += (string)closePrice;
   //comm += "\n";
   //comm += (string)SetPrevTime();
   //comm += "\n";
   //comm += (string)closePos;   
   //Comment(comm);
   
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
//datetime SetPrevTime() { 
void SetPrevTime() { 
//, int hour, int minute) {
   
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
//void drawRectangle(double time1, double price1, double time2, double price2) {   
    //ObjectCreate(0, "rectangle gap", OBJ_RECTANGLE, 0, mktClose, closePrice, mktOpen, openPrice);
    //ObjectCreate(0, "rectangle gap", OBJ_RECTANGLE, 0, time1, price1, time2, price2);
//}
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