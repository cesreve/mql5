//+------------------------------------------------------------------+
//|                                             BreakoutProOrder.mq5 |
//|                                                           ceezer |
//+------------------------------------------------------------------+

//--- à checker parce que BUG
//3 juillet
//11 juillet
//17 juillet
//ajouter distance ordre
//pas attendre nouvelle barre pour voir si on peut mettre l'ordre
//prendre les 15 ou 30 premieres minutes uniquement pour le range ?

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

bool tradeAllowed = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);   
//---
   Print(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN));
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
   if(IsNewDay()) {closePositions();
                     tradeAllowed=true;
                     Print("It's a New day");
                     ObjectCreate(0, "New Day",OBJ_VLINE,0,iTime(_Symbol,_Period,0),0);
                  }
//---
   SymbolInfoTick(_Symbol, tick);
//---
   datetime currentCandle = iTime(_Symbol,_Period,1);

   
//---
   string today = StringSubstr(TimeToString(tick.time),0,11);
   datetime startRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:00");
   datetime endRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:30");
   
   datetime stopTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"11:00");
   datetime closeTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+endHourMinute);
//---

   
//---
   if(currentCandle >= endRange && currentCandle <= stopTime && tradeAllowed == true)
   //if(currentCandle == endRange && tradeAllowed == true)
   {
      //int startRangePos = iBarShift(_Symbol,_Period,startRange);//---
      double rangeHigh=0;
      double rangeLow=0;
      //highBetweenTwoHours(startRange, iTime(_Symbol,_Period,1),rangeHigh,rangeLow);
      highBetweenTwoHours(startRange, currentCandle, rangeHigh, rangeLow);
      //Print("rangeHigh: ", rangeHigh, " rangeLow: ", rangeLow, " amplitude: ", NormalizeDouble(rangeHigh-rangeLow, 2));
      //Print("heureminutetest ", heureminutetest);
      double amplitude = NormalizeDouble(rangeHigh-rangeLow, 2);
      //double InpAmplitudeMax = NormalizeDouble(tick.last/100, 0);
      //double InpAmplitudeMin = NormalizeDouble(tick.last/800, 0);
      //ObjectCreate(0,"rangeHigh",OBJ_HLINE,0,0,rangeHigh);
      ObjectCreate(0, "rangeHigh", OBJ_TREND, 0, startRange, rangeHigh, endRange, rangeHigh);
      ObjectSetInteger(0, "rangeHigh", OBJPROP_HIDDEN, false );
      ////ObjectSetInteger(0, "rangeHigh", OBJPROP_RAY_RIGHT, true );      
      ObjectCreate(0, "range High", OBJ_TEXT, 0, startRange, rangeHigh );
      ObjectSetString(0, "range High", OBJPROP_TEXT, "range High");
      ObjectSetInteger(0, "range High", OBJPROP_HIDDEN, false );
      //---
      
      //ObjectCreate(0,"rangeLow", OBJ_HLINE, 0, 0, rangeLow);
      ObjectCreate(0,"rangeLow", OBJ_TREND, 0, startRange, rangeLow, endRange, rangeLow);
      ObjectSetInteger(0, "rangeLow", OBJPROP_HIDDEN, false );
      ObjectCreate(0, "range Low", OBJ_TEXT, 0, startRange, rangeLow);
      ObjectSetString(0, "range Low", OBJPROP_TEXT, "range Low");
      ObjectSetInteger(0, "range Low", OBJPROP_HIDDEN, false );
      
      //---
      
      if(tick.last < rangeHigh-inpRatio*amplitude && tick.last > rangeLow+inpRatio*amplitude)
      {
         //Print("IN THE ZONE");
         if(OrdersTotal()<1 && amplitude < InpAmplitudeMax && amplitude>InpAmplitudeMin)
         {
            placeStopOrders(rangeHigh-InpDistanceOrdre, rangeLow+InpDistanceOrdre);
            tradeAllowed = false;
         }
      }     
   }
//---
   if(currentCandle == closeTime) {Print("Close time."); closePositions();}
//---
   Comment(currentCandle);

  } // end of the OnTick() Function
  
//+------------------------------------------------------------------+
//|                    Custom functions                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//- High between 2 hours  -------------------------------------------+
bool highBetweenTwoHours(datetime startTime, datetime endTime, double &rangeHigh, double &rangeLow)
{
   if(!(endTime>startTime)) {Print("endTime must be superior to startTime"); return false;}
   
   else {   
      int startRangePos = iBarShift(_Symbol,_Period,startTime);
      int endRangePos   = iBarShift(_Symbol,_Period,endTime);
      int barCount      = 1 + startRangePos - endRangePos;
      
      rangeHigh = iHigh(_Symbol,_Period,iHighest(_Symbol,_Period,MODE_HIGH,barCount,endRangePos));
      rangeLow  = iLow(_Symbol,_Period,iLowest(_Symbol,_Period,MODE_LOW,barCount,endRangePos));  
      
      return true;
   }
}
//+------------------------------------------------------------------+
//- Place stop orders  ----------------------------------------------+    
bool placeStopOrders(double priceHigh, double priceLow)
{
   bool buyStopResult, sellStopResult  = false;
   datetime closeTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+endHourMinute);
   //buyStopResult = trade.BuyStop(InpLots,priceHigh,_Symbol,priceLow,0,ORDER_TIME_DAY,0,"Buy stop ProOrder");
   buyStopResult = trade.BuyStop(InpLots,priceHigh,_Symbol,priceLow,0,ORDER_TIME_SPECIFIED,closeTime,"Buy stop ProOrder");
   if(!buyStopResult) {Print(__FUNCTION__,"--> OrderSend error ", trade.ResultComment()); return false;}
   sellStopResult = trade.SellStop(InpLots,priceLow,_Symbol,priceHigh,0,ORDER_TIME_DAY,0,"Sell stop ProOrder");
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
   datetime currentTime = iTime(_Symbol, _Period, 0);
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
   datetime currentDay = StringToTime(StringSubstr(TimeToString(iTime(_Symbol,_Period,0)),0,11));
   if(previousDay!=currentDay)
     {
      previousDay=currentDay;
      return true;
     }
   return false;  
  }  