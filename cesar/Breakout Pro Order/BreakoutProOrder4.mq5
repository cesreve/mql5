//+------------------------------------------------------------------+
//|                                             BreakoutProOrder.mq5 |
//|                                                           ceezer |
//+------------------------------------------------------------------+

//--- à checker parce que BUG
//3 juillet
//11 juillet
//17 juillet
// 2023.01.09 10:31:00   failed buy stop 0.1 [CAC40] at 6867.15 sl: 6853.77 [Invalid price]
// 2023.01.11 10:48:35   failed buy stop 0.1 [CAC40] at 6886.50 sl: 6877.06 [Invalid price]


//ajouter distance ordre
//pas attendre nouvelle barre pour voir si on peut mettre l'ordre
//prendre les 15 ou 30 premieres minutes uniquement pour le range ?
//mettre les horaires en input pour tester 15 ou 30 ou 11h
//calculer le range à partir de  10h

#property copyright "ceezer"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;                    // pending orders object

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;
double input inpRatio = 0.15;
input int InpMagicNumber = 753;
input double InpLots=0.1; // 

input int InpAmplitudeMin = 15;
input int InpAmplitudeMax = 116;
input int InpDistanceOrdre = 4;

input string endHourMinute = "21:45"; //hh:mm
input int InpMaxTradesPerDay = 1; // Maximum trades per day (1 or 2)

double rangeHigh = 0;
double rangeLow = 0;
bool tradeAllowed = false;
string comm = "";
int tradesOpenedToday = 0;
datetime lastTradeDate = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);   
//---
   if(InpMaxTradesPerDay != 1 && InpMaxTradesPerDay != 2)
   {
      Print("Invalid InpMaxTradesPerDay value. It must be either 1 or 2.");
      return INIT_PARAMETERS_INCORRECT;
   }
   //Print(SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN));
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //if(!IsNewbar()) {return;}
   if(IsNewDay()) {
      closePositions();
      rangeHigh = 0;
      rangeLow = 0;
      tradeAllowed=true;
      tradesOpenedToday = 0;
      //Print("It's a New day");
      //ObjectCreate(0, "New Day",OBJ_VLINE,0,iTime(Symbol(),PERIOD_M1,0),0);
      }
//---
   datetime now = TimeCurrent();
   datetime StartTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:00");
   if(!(now>=StartTime)) {
      return;
      }
//---
   SymbolInfoTick(Symbol(), tick);
//---
   //datetime currentCandle = iTime(Symbol(),PERIOD_M1,1);

   
//---
   string today = StringSubstr(TimeToString(tick.time),0,11);
   datetime startRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:00");
   datetime endRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:30");
   
   datetime stopTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"12:00");
   datetime closeTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+endHourMinute);
//---

   
//---
   if(now >= endRange && now <= stopTime && tradeAllowed == true && tradesOpenedToday < InpMaxTradesPerDay)
   {
      rangeHigh=0;
      rangeLow=0;
      highBetweenTwoHours(startRange, now);
      double amplitude = NormalizeDouble(rangeHigh-rangeLow, 2);
      
      //--- high border range
      ObjectCreate(0, "rangeHigh", OBJ_TREND, 0, startRange, rangeHigh, now, rangeHigh);
      ObjectSetInteger(0, "rangeHigh", OBJPROP_HIDDEN, false );     
      ObjectCreate(0, "range high text", OBJ_TEXT, 0, startRange, rangeHigh );
      ObjectSetString(0, "range high text", OBJPROP_TEXT, "range High");
      ObjectSetInteger(0, "range high text", OBJPROP_HIDDEN, false );
      //--- low border range
      ObjectCreate(0,"rangeLow", OBJ_TREND, 0, startRange, rangeLow, now, rangeLow);
      ObjectSetInteger(0, "rangeLow", OBJPROP_HIDDEN, false );
      ObjectCreate(0, "range low text", OBJ_TEXT, 0, startRange, rangeLow);
      ObjectSetString(0, "range low text", OBJPROP_TEXT, "range Low");
      ObjectSetInteger(0, "range low text", OBJPROP_HIDDEN, false );
      
      
      //--- trigger zone 
      //border up
      ObjectCreate(0, "price buy", OBJ_TREND, 0, startRange, rangeHigh-inpRatio*amplitude, stopTime, rangeHigh-inpRatio*amplitude);
      ObjectSetInteger(0, "price buy", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price buy", OBJPROP_COLOR, clrYellow );     
      ObjectCreate(0, "price buy text", OBJ_TEXT, 0, startRange, rangeHigh-inpRatio*amplitude );
      ObjectSetString(0, "price buy text", OBJPROP_TEXT, "high trigger");
      ObjectSetInteger(0, "price buy text", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price buy text", OBJPROP_COLOR, clrYellow );
      //border down
      ObjectCreate(0, "price sell", OBJ_TREND, 0, startRange, rangeLow+inpRatio*amplitude, stopTime, rangeLow+inpRatio*amplitude);
      ObjectSetInteger(0, "price sell", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price sell", OBJPROP_COLOR, clrYellow );     
      ObjectCreate(0, "price sell text", OBJ_TEXT, 0, startRange, rangeLow+inpRatio*amplitude);
      ObjectSetString(0, "price sell text", OBJPROP_TEXT, "low trigger");
      ObjectSetInteger(0, "price sell text", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price sell text", OBJPROP_COLOR, clrYellow );
      

      
      //--- place orders conditions      
      if(tick.last < rangeHigh-inpRatio*amplitude && tick.last > rangeLow+inpRatio*amplitude)
      {
         if(OrdersTotal()<1 && amplitude > InpAmplitudeMin && amplitude < InpAmplitudeMax)
         {
            placeStopOrders(rangeHigh-InpDistanceOrdre, rangeLow+InpDistanceOrdre);
            tradeAllowed = false;
            tradesOpenedToday++;
            lastTradeDate = now;
         }
      }     
   }
//---
   if(now >= closeTime) {closePositions();}
//---
   comm = "";
   comm += (string)rangeHigh;
   comm += "\n";
   comm += (string)rangeLow;
   comm += "\n";
   comm += (string)now;
   comm += "\n";
   comm += "Trades opened today: " + (string)tradesOpenedToday;
   comm += "\n";
   Comment(comm);

  } // end of the OnTick() Function
  
//+------------------------------------------------------------------+
//|                    Custom functions                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//- High between 2 hours  -------------------------------------------+
void highBetweenTwoHours(datetime startTime, datetime endTime)
{
   if(!(endTime>startTime)) {Print("endTime must be superior to startTime");}
   
   else {   
      int startRangePos = iBarShift(Symbol(),PERIOD_M1,startTime);
      int endRangePos   = iBarShift(Symbol(),PERIOD_M1,endTime);
      int barCount      = startRangePos - endRangePos + 1;
      
      rangeHigh = iHigh(Symbol(),PERIOD_M1,iHighest(Symbol(),PERIOD_M1,MODE_HIGH,barCount,endRangePos));
      rangeLow  = iLow(Symbol(),PERIOD_M1,iLowest(Symbol(),PERIOD_M1,MODE_LOW,barCount,endRangePos)); 
   }
}
////- High between 2 hours  -------------------------------------------+
//bool highBetweenTwoHours(datetime startTime, datetime endTime, double &rangeHigh, double &rangeLow)
//{
//   if(!(endTime>startTime)) {Print("endTime must be superior to startTime"); return false;}
//   
//   else {   
//      int startRangePos = iBarShift(Symbol(),PERIOD_M1,startTime);
//      int endRangePos   = iBarShift(Symbol(),PERIOD_M1,endTime);
//      int barCount      = startRangePos - endRangePos + 1;
//      
//      rangeHigh = iHigh(Symbol(),PERIOD_M1,iHighest(Symbol(),PERIOD_M1,MODE_HIGH,barCount,endRangePos));
//      rangeLow  = iLow(Symbol(),PERIOD_M1,iLowest(Symbol(),PERIOD_M1,MODE_LOW,barCount,endRangePos));  
//      
//      return true;
//   }
//}
//+------------------------------------------------------------------+
//- Place stop orders  ----------------------------------------------+    
bool placeStopOrders(double priceHigh, double priceLow)
{
   bool buyStopResult, sellStopResult  = false;
   datetime closeTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+endHourMinute);
   buyStopResult = trade.BuyStop(InpLots,priceHigh,Symbol(),priceLow,0,ORDER_TIME_SPECIFIED,closeTime,"Buy stop ProOrder");
   if(!buyStopResult) {Print(__FUNCTION__,"--> OrderSend error ", trade.ResultComment()); return false;}
   sellStopResult = trade.SellStop(InpLots,priceLow,Symbol(),priceHigh,0,ORDER_TIME_SPECIFIED,closeTime,"Sell stop ProOrder");
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
//- New Bar  --------------------------------------------------------+
bool IsNewbar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(Symbol(), PERIOD_M1, 0);
   if(previousTime!=currentTime)
     {
      previousTime=currentTime;
      return true;
     }
   return false;  
  }
//+------------------------------------------------------------------+
//- New Day  --------------------------------------------------------+
bool IsNewDay()
  {
   static datetime previousDay = 0;
   datetime currentDay = StringToTime(StringSubstr(TimeToString(iTime(Symbol(),PERIOD_M1,0)),0,11));
   if(previousDay!=currentDay)
     {
      previousDay=currentDay;
      return true;
     }
   return false;  
  }  