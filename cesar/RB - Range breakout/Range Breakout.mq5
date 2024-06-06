//+------------------------------------------------------------------+
//|                                               Range Breakout.mq5 |
//|                                                      version 1.0 |
//|                                                 date: 26/05/2024 |
//+------------------------------------------------------------------+
// Trading RULES
// Detect high and low between start time and end time
// if price breaks enter in position
// close all position at the end of the day (end time)
// can trigger in both side, but only 1 time a day per side
//+------------------------------------------------------------------+
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
input group "==== Strategy parameters ====";
//--- range input
input group "==== Range ====";
input int InpStartRangeHour   = 10; // Range Start hour
input int InpStartRangeMinute = 0;  // Range Start minute
input int InpEndRangeHour     = 10; // Range End hour
input int InpEndRangeMinute   = 30; // Range End minute
//--- trades inputs
input group "==== Trading hours ====";
input int InpStopHour         = 13; // Stop pending orders hour
input int InpStopMinute       = 0;  // Stop pending orders minute
input int InpCloseHour        = 18; // Close all positions hour
input int InpCloseMinute      = 45; // Close all positions minute

//--- others
input group "==== Expert settings ====";
input int InpMagicNumber      = 0;
input double InpLots          = 0.01;
input string InpTradeComment  = "Range Breakout";
input color InpColor          = clrRed;

input double InpMaxAmplitude = 0.85;
input double InpMinAmplitude = 0.10;
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;

double rangeHigh = 0;
double rangeLow = 0;

datetime now;
datetime startRange = 0;
datetime endRange   = 0;
datetime stopTime   = 0;
datetime closeTime  = 0;

bool tradeLongAllowed = false;
bool tradeShortAllowed = false;
bool rangeAllowed = false;
string comm = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   now = TimeCurrent();
   calculateDatetimes();
//---
   trade.SetExpertMagicNumber(InpMagicNumber);
//---
   Print("Starting: ", InpTradeComment, " on ", (string)Symbol() );
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
//---
   if(IsNewDay()) {
      ObjectCreate(0, "New Day",OBJ_VLINE,0,iTime(Symbol(),Period(),0),0);
      calculateDatetimes();
      closePositions();
      rangeHigh = 0;
      rangeLow = 0;
      tradeLongAllowed = true;
      tradeShortAllowed = true;
      rangeAllowed=true;
      }

//---
   if ( !(now >= endRange) ) { return; } // time condition
   highBetweenTwoHours(startRange, endRange); // calculates high and low of range
   if (rangeAllowed) {drawObjetcs();} 
   rangeAllowed = false;
   
   double ask = SymbolInfoDouble( Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble( Symbol(), SYMBOL_BID);
   double amplitude = NormalizeDouble((rangeHigh-rangeLow), 2);
   double maxAmp = ask*InpMaxAmplitude/100;
   double minAmp = ask*InpMinAmplitude/100;
   if ( now < stopTime && amplitude > minAmp && amplitude < maxAmp) {
   //if ( now < stopTime)  {
      if( ask > rangeHigh && tradeLongAllowed ) { 
         if( setOrder(ORDER_TYPE_BUY, ask, 0) ) { tradeLongAllowed = false; }
      }
      else if ( bid < rangeLow && tradeShortAllowed ) 
         if( setOrder(ORDER_TYPE_SELL, bid, 0) ) { tradeShortAllowed = false; }
   }
   
   if (now > closeTime) { closePositions(); }
//---
   comm = "";
   comm += InpTradeComment;
   comm += "\n";
   comm += (string)Symbol();
   comm += "\n";
   comm += (string)startRange;
   comm += "\n";
   comm += (string)endRange;
   comm += "\n";
   comm += (string)closeTime;
   comm += "\n";
   comm += (string)InpLots;
   comm += "\n";
   comm += (string)tradeLongAllowed;
   comm += "\n";
   comm += (string)tradeShortAllowed;
   comm += "\n";   
   comm += "Ask: "+(string)NormalizeDouble(ask, 2);
   comm += "\n";   
   comm += "Max amplitude "+(string)NormalizeDouble((ask*InpMaxAmplitude)/100, 2);
   comm += "\n";   
   comm += "Min amplitude "+(string)NormalizeDouble((ask*InpMinAmplitude)/100, 2);
   comm += "\n";
   comm += "Amplitude range: "+(string)NormalizeDouble((rangeHigh-rangeLow), 2); 

   Comment(comm);

} // end of the OnTick Function 
 
//+------------------------------------------------------------------+
//|                    Custom functions                              |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void setOrder(ENUM_ORDER_TYPE type, double price) {

   if(!setOrder(type, price, 0)) return;
}

bool setOrder(ENUM_ORDER_TYPE type, double price, double takeProfit) {

   double tp = 0;      
   if(type==ORDER_TYPE_BUY) {
      tp = takeProfit > 0 ? price + takeProfit : 0;
   } else {
      tp = takeProfit > 0 ? price - takeProfit : 0;
   }
   
   double sl = 0;  
   if(type==ORDER_TYPE_BUY) {
      sl = rangeLow;
   } else {
      sl = rangeHigh;
   }  
   
   if(!trade.PositionOpen( Symbol() , type, InpLots, price, sl, tp, InpTradeComment)) {
      PrintFormat("Error opening position, typ=%s, volume=%f, price=%f, sl=%f, tp=%f",
                  EnumToString(type), InpLots, price, sl, tp);
      return false;          
   }
   return true;
}
//- High between 2 hours  -------------------------------------------+
void highBetweenTwoHours(datetime startTime, datetime endTime)
{
   if(!(endTime>=startTime)) {Print("endTime must be superior to startTime");}
   
   else {  
      int startRangePos = iBarShift(Symbol(),PERIOD_M1,startTime);
      int endRangePos   = iBarShift(Symbol(),PERIOD_M1,endTime);
      int barCount      = startRangePos - endRangePos + 1;
     
      rangeHigh = iHigh(Symbol(),PERIOD_M1,iHighest(Symbol(),PERIOD_M1,MODE_HIGH,barCount,endRangePos));
      rangeLow  = iLow(Symbol(),PERIOD_M1,iLowest(Symbol(),PERIOD_M1,MODE_LOW,barCount,endRangePos));
   }
}
//+------------------------------------------------------------------+
//- Close all positions   -------------------------------------------+
bool closePositions()
{
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);      
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to get position magic number"); return false;}
      if(magic==InpMagicNumber)
      {
         trade.PositionClose(ticket);
         if(trade.ResultRetcode()!=TRADE_RETCODE_DONE)
         {
            Print("Failed to close position, ticket: ", (string)ticket,
                  " result: ", (string)trade.ResultRetcode(), ": ", trade.CheckResultRetcodeDescription());
         }
      }
   }  
   return true;    
}
//+------------------------------------------------------------------+
//- Calculate datetimes  --------------------------------------------+
void calculateDatetimes()
{
   //--- convert to times  
   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);  
   nowStruct.sec = 0;
   
   // start time
   nowStruct.hour = InpStartRangeHour;
   nowStruct.min = InpStartRangeMinute;
   startRange = StructToTime(nowStruct);
   
   // end time
   nowStruct.hour = InpEndRangeHour;
   nowStruct.min = InpEndRangeMinute;
   endRange = StructToTime(nowStruct);
   
   // stop time
   nowStruct.hour = InpStopHour;
   nowStruct.min = InpStopMinute;
   stopTime = StructToTime(nowStruct);
   
   // close time
   nowStruct.hour = InpCloseHour;
   nowStruct.min = InpCloseMinute;
   closeTime = StructToTime(nowStruct);
}
//+------------------------------------------------------------------+
//- Draw objects  ---------------------------------------------------+
void drawObjetcs() {
      //--- high border range
      ObjectCreate(0, "rangeHigh", OBJ_TREND, 0, startRange, rangeHigh, now, rangeHigh);
      ObjectSetInteger(0, "rangeHigh", OBJPROP_HIDDEN, false );
      ObjectSetInteger(0, "rangeHigh", OBJPROP_COLOR, InpColor );
      ObjectCreate(0, "rangeHigh next", OBJ_TREND, 0, now, rangeHigh, stopTime, rangeHigh);
      ObjectSetInteger(0, "rangeHigh next", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "rangeHigh next", OBJPROP_STYLE, STYLE_DOT );
      ObjectSetInteger(0, "rangeHigh next", OBJPROP_COLOR, InpColor );
      //text
      ObjectCreate(0, "range high text", OBJ_TEXT, 0, startRange, rangeHigh );
      ObjectSetString(0, "range high text", OBJPROP_TEXT, "range High");
      ObjectSetInteger(0, "range high text", OBJPROP_HIDDEN, false );
      ObjectSetInteger(0, "range high text", OBJPROP_COLOR, InpColor );
     
      //--- low border range
      ObjectCreate(0,"rangeLow", OBJ_TREND, 0, startRange, rangeLow, now, rangeLow);
      ObjectSetInteger(0, "rangeLow", OBJPROP_HIDDEN, false );
      ObjectSetInteger(0, "rangeLow", OBJPROP_COLOR, InpColor );
      ObjectCreate(0, "rangeLow next", OBJ_TREND, 0, now, rangeLow, stopTime, rangeLow);
      ObjectSetInteger(0, "rangeLow next", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "rangeLow next", OBJPROP_STYLE, STYLE_DOT );
      ObjectSetInteger(0, "rangeLow next", OBJPROP_COLOR, InpColor );
      //text
      ObjectCreate(0, "range low text", OBJ_TEXT, 0, startRange, rangeLow);
      ObjectSetString(0, "range low text", OBJPROP_TEXT, "range Low");
      ObjectSetInteger(0, "range low text", OBJPROP_HIDDEN, false );
      ObjectSetInteger(0, "range low text", OBJPROP_COLOR, InpColor );      
}    
//+------------------------------------------------------------------+
//- New Day  --------------------------------------------------------+
bool IsNewDay()
  {
   static datetime previousDay = 0;
   datetime currentDay = StringToTime(StringSubstr(TimeToString(iTime(Symbol(),PERIOD_M1,0)),0,11));
   if(previousDay!=currentDay) {
      previousDay=currentDay;
      return true;
     }
   return false;  
  }  