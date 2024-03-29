//+------------------------------------------------------------------+
//|                                       BreakoutProOrder DJI30.mq5 |
//|                                                           ceezer |
//+------------------------------------------------------------------+
#property copyright "ceezer"
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
//--- range input
input group "==== Range ====";
input int InpStartRangeHour   = 16; // Range Start hour
input int InpStartRangeMinute = 30;  // Range Start minute
input int InpEndRangeHour     = 17; // Range End hour
input int InpEndRangeMinute   = 00; // Range End minute
//--- trades inputs 
input group "==== Trading hours ====";
input int InpStopHour         = 20; // Stop pending orders hour
input int InpStopMinute       = 00;  // Stop pending orders minute
input int InpCloseHour        = 22; // Close all positions hour
input int InpCloseMinute      = 55; // Close all positions minute
//--- strategy parameters
input group "==== Strategy parameters ====";
double input inpRatio = 0.15;
input int InpAmplitudeMin = 50;
input int InpAmplitudeMax = 250;
input int InpDistanceOrdre = 8;
//--- others
input group "==== Expert settings ====";
input int InpMagicNumber = 5092023;
input double InpLots     = 0.01;

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;

double rangeHigh = 0;
double rangeLow = 0;
double amplitude = 0;
bool tradeAllowed = false;
string comm = "";

//--- times
int startRangeHour = InpStartRangeHour;
int startRangeMinute = InpStartRangeMinute;
int endRangeHour = InpEndRangeHour;
int endRangeMinute = InpEndRangeMinute;
int stopHour = InpStopHour;
int stopMinute = InpStopMinute;
int closeHour = InpCloseHour;
int closeMinute = InpCloseMinute;

datetime now;
datetime startRange = 0;
datetime endRange   = 0;
datetime stopTime   = 0;
datetime closeTime  = 0;

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
      calculateDatetimes();
      closePositions();
      rangeHigh = 0;
      rangeLow = 0;
      tradeAllowed=true;
      }
//---
   if(!(now>=startRange)) {
      return;
      }
//---
   if(iTime(Symbol(),PERIOD_M1,0)==startRange) {
      ObjectCreate(0, "Start",OBJ_VLINE,0,startRange,0);
      }      
//---
   SymbolInfoTick(Symbol(), tick);
//---
   if(now >= endRange && now <= stopTime && tradeAllowed == true)
   {  
      //---
      highBetweenTwoHours(startRange, now);
      drawObjetcs();
      //--- place orders conditions      
      if(tick.last < rangeHigh-inpRatio*amplitude && tick.last > rangeLow+inpRatio*amplitude)
      {
         if(amplitude > InpAmplitudeMin && amplitude < InpAmplitudeMax)
         {
            placeStopOrders(rangeHigh-InpDistanceOrdre, rangeLow+InpDistanceOrdre);
            tradeAllowed = false;
         }
      }     
   }
//---
   if(now >= closeTime) {closePositions();}

  } // end of the OnTick() Function
  
//+------------------------------------------------------------------+
//|                    Custom functions                              |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
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
      
      amplitude = rangeHigh - rangeLow;
   }
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
   nowStruct.hour = startRangeHour;
   nowStruct.min = startRangeMinute;
   startRange = StructToTime(nowStruct);
   
   // end time
   nowStruct.hour = endRangeHour;
   nowStruct.min = endRangeMinute;
   endRange = StructToTime(nowStruct);
   
   // stop time
   nowStruct.hour = stopHour;
   nowStruct.min = stopMinute;
   stopTime = StructToTime(nowStruct);
   
   // close time
   nowStruct.hour = closeHour;
   nowStruct.min = closeMinute;
   closeTime = StructToTime(nowStruct);
}
//+------------------------------------------------------------------+
//- Place stop orders  ----------------------------------------------+    
bool placeStopOrders(double priceHigh, double priceLow)
{
   bool buyStopResult, sellStopResult  = false;
   buyStopResult = trade.BuyStop(InpLots,priceHigh,Symbol(),priceLow,0,ORDER_TIME_SPECIFIED,stopTime,"Buy stop ProOrder");
   if(!buyStopResult) {Print(__FUNCTION__,"--> OrderSend error ", trade.ResultComment()); return false;}
   sellStopResult = trade.SellStop(InpLots,priceLow,Symbol(),priceHigh,0,ORDER_TIME_SPECIFIED,stopTime,"Sell stop ProOrder");
   if(!sellStopResult) {Print(__FUNCTION__,"--> OrderSend error ", trade.ResultComment()); return false;}
   
   tradeAllowed = false;
   
   return buyStopResult && sellStopResult; 
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
//- Draw objects  ---------------------------------------------------+
void drawObjetcs() {
      //--- high border range
      ObjectCreate(0, "rangeHigh", OBJ_TREND, 0, startRange, rangeHigh, now, rangeHigh);
      ObjectSetInteger(0, "rangeHigh", OBJPROP_HIDDEN, false );
      ObjectCreate(0, "rangeHigh next", OBJ_TREND, 0, now, rangeHigh, stopTime, rangeHigh);
      ObjectSetInteger(0, "rangeHigh next", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "rangeHigh next", OBJPROP_STYLE, STYLE_DOT );
      //text
      ObjectCreate(0, "range high text", OBJ_TEXT, 0, startRange, rangeHigh );
      ObjectSetString(0, "range high text", OBJPROP_TEXT, "range High");
      ObjectSetInteger(0, "range high text", OBJPROP_HIDDEN, false );
      
      //--- low border range
      ObjectCreate(0,"rangeLow", OBJ_TREND, 0, startRange, rangeLow, now, rangeLow);
      ObjectSetInteger(0, "rangeLow", OBJPROP_HIDDEN, false );
      ObjectCreate(0, "rangeLow next", OBJ_TREND, 0, now, rangeLow, stopTime, rangeLow);
      ObjectSetInteger(0, "rangeLow next", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "rangeLow next", OBJPROP_STYLE, STYLE_DOT );
      //text
      ObjectCreate(0, "range low text", OBJ_TEXT, 0, startRange, rangeLow);
      ObjectSetString(0, "range low text", OBJPROP_TEXT, "range Low");
      ObjectSetInteger(0, "range low text", OBJPROP_HIDDEN, false );      
      
      //--- trigger zone 
      //border up
      ObjectCreate(0, "price buy", OBJ_TREND, 0, startRange, rangeHigh-inpRatio*amplitude, stopTime, rangeHigh-inpRatio*amplitude);
      ObjectSetInteger(0, "price buy", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price buy", OBJPROP_COLOR, clrYellow );
      ObjectSetInteger( 0, "price buy", OBJPROP_STYLE, STYLE_DOT );
      //text   
      ObjectCreate(0, "price buy text", OBJ_TEXT, 0, startRange, rangeHigh-inpRatio*amplitude );
      ObjectSetString(0, "price buy text", OBJPROP_TEXT, "high trigger");
      ObjectSetInteger(0, "price buy text", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price buy text", OBJPROP_COLOR, clrYellow );
      //border down
      ObjectCreate(0, "price sell", OBJ_TREND, 0, startRange, rangeLow+inpRatio*amplitude, stopTime, rangeLow+inpRatio*amplitude);
      ObjectSetInteger(0, "price sell", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price sell", OBJPROP_COLOR, clrYellow );
      ObjectSetInteger( 0, "price sell", OBJPROP_STYLE, STYLE_DOT );
      //text   
      ObjectCreate(0, "price sell text", OBJ_TEXT, 0, startRange, rangeLow+inpRatio*amplitude);
      ObjectSetString(0, "price sell text", OBJPROP_TEXT, "low trigger");
      ObjectSetInteger(0, "price sell text", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price sell text", OBJPROP_COLOR, clrYellow );  
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