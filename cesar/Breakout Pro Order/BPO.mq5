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
//--- strategy parameters
input group "==== Strategy parameters ====";
input double inpRatio = 0.30;
input int InpAmplitudeMin = 25;
input int InpAmplitudeMax = 160;
input int InpDistanceOrdre = 5;
input int InpTakeProfit1 = 50;
input int InpTakeProfit2 = 100;
input int InpTakeProfit3 = 0;

//--- others
input group "==== Expert settings ====";
input int InpMagicNumber = 1092023;
input double InpLots     = 0.1;
input string InpTradeComment = "Pro Order";

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;

double rangeHigh = 0;
double rangeLow = 0;
double amplitude = 0;
bool tradeAllowed = false;
bool rangeAllowed = false;
string comm = "";
string tradeComment = InpTradeComment+" - "+(string)Symbol();
//---
double TakeProfit1 = InpTakeProfit1;
double TakeProfit2 = InpTakeProfit2;
double TakeProfit3 = InpTakeProfit3;

double vol = InpLots;

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
      ObjectCreate(0, "New Day",OBJ_VLINE,0,iTime(Symbol(),Period(),0),0);
      calculateDatetimes();
      closePositions();
      rangeHigh = 0;
      rangeLow = 0;
      tradeAllowed=true;
      rangeAllowed=true;
      }

//---
   if(!(now>=startRange)) {
      return;
      }
//---
   SymbolInfoTick(Symbol(), tick);
//---
   
   if(now > startRange && rangeAllowed && (rangeHigh - rangeLow) < InpAmplitudeMax )
   {
      highBetweenTwoHours(startRange, now);
      drawObjetcs();
      if(now >= endRange && now <= stopTime && tradeAllowed)
      {
          if(tick.bid < rangeHigh-inpRatio*amplitude && tick.ask > rangeLow+inpRatio*amplitude)
          {
            setOrder(ORDER_TYPE_BUY_STOP,rangeHigh);
            setOrder(ORDER_TYPE_SELL_STOP,rangeLow);
            tradeAllowed = false;
            rangeAllowed = false;
            Print("Orders placed");          
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

void setOrder(ENUM_ORDER_TYPE type, double price) {

   if(!setOrder(type, price, TakeProfit1)) return;
   if(!setOrder(type, price, TakeProfit2)) return;   
   if(!setOrder(type, price, TakeProfit3)) return;
}

bool setOrder(ENUM_ORDER_TYPE type, double price, double takeProfit) {

   double tp = 0;      
   if(type==ORDER_TYPE_BUY_STOP) {
      tp = takeProfit > 0 ? price + takeProfit : 0;
   } else {
      tp = takeProfit > 0 ? price - takeProfit : 0;
   }
   
   double sl = 0;  
   if(type==ORDER_TYPE_BUY_STOP) {
      sl = rangeLow+InpDistanceOrdre;
   } else {
      sl = rangeHigh-InpDistanceOrdre;
   }  
   
   if(!trade.OrderOpen(Symbol(), type, vol, price, price, sl, tp, ORDER_TIME_SPECIFIED,stopTime, tradeComment)) {
      PrintFormat("Error opening position, typ=%s, volume=%f, price=%f, sl=%f, tp=%f",
                  EnumToString(type), vol, price, sl, tp);
      return false;          
   }
   return true;
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
      if(now >= endRange)
      {
         //border up
         ObjectCreate(0, "price buy", OBJ_TREND, 0, startRange, rangeHigh-inpRatio*amplitude, stopTime, rangeHigh-inpRatio*amplitude);
         ObjectSetInteger(0, "price buy", OBJPROP_HIDDEN, false );
         ObjectSetInteger( 0, "price buy", OBJPROP_COLOR, clrBlue );
         ObjectSetInteger( 0, "price buy", OBJPROP_STYLE, STYLE_DOT );
         //text  
         ObjectCreate(0, "price buy text", OBJ_TEXT, 0, startRange, rangeHigh-inpRatio*amplitude );
         ObjectSetString(0, "price buy text", OBJPROP_TEXT, "high trigger");
         ObjectSetInteger(0, "price buy text", OBJPROP_HIDDEN, false );
         ObjectSetInteger( 0, "price buy text", OBJPROP_COLOR, clrBlue );
         //border down
         ObjectCreate(0, "price sell", OBJ_TREND, 0, startRange, rangeLow+inpRatio*amplitude, stopTime, rangeLow+inpRatio*amplitude);
         ObjectSetInteger(0, "price sell", OBJPROP_HIDDEN, false );
         ObjectSetInteger( 0, "price sell", OBJPROP_COLOR, clrBlue );
         ObjectSetInteger( 0, "price sell", OBJPROP_STYLE, STYLE_DOT );
         //text  
         ObjectCreate(0, "price sell text", OBJ_TEXT, 0, startRange, rangeLow+inpRatio*amplitude);
         ObjectSetString(0, "price sell text", OBJPROP_TEXT, "low trigger");
         ObjectSetInteger(0, "price sell text", OBJPROP_HIDDEN, false );
         ObjectSetInteger( 0, "price sell text", OBJPROP_COLOR, clrBlue );
      }
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