//+------------------------------------------------------------------+
//|                                             BreakoutProOrder.mq5 |
//|                                                           ceezer |
//+------------------------------------------------------------------+

//--- à checker parce que BUG
//3 juillet
//11 juillet
//17 juillet

#property copyright "ceezer"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\OrderInfo.mqh>
CTrade trade;
COrderInfo order;                      // pending orders object

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;
double input inpRatio = 0.15;
input int InpMagicNumber = 753;
input double InpLots=0.05;

input int InpAmplitudeMin = 15;
input int InpAmplitudeMax = 70;

input string endHourMinute = "21:45"; //HH:mm

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
   if(!IsNewbar()) {return;}
   //Print("New bar");
   if(IsNewDay()) {closePositions(); tradeAllowed=true; Print("It's a New day");}
//---
   SymbolInfoTick(_Symbol, tick);
//---
   datetime currentCandle = iTime(_Symbol,_Period,1);

   
//---
   string today = StringSubstr(TimeToString(tick.time),0,11);
   datetime heureminutetest = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:00");
   datetime startRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:00");
   datetime endRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:30");
   datetime closeTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"21:45");
//---

   
//---
   if(currentCandle >= endRange && tradeAllowed == true)
   {
      //int startRangePos = iBarShift(_Symbol,_Period,startRange);//---
      double rangeHigh=0;
      double rangeLow=0;
      //highBetweenTwoHours(startRange, iTime(_Symbol,_Period,1),rangeHigh,rangeLow);
      highBetweenTwoHours(startRange, currentCandle, rangeHigh, rangeLow);
      //Print("rangeHigh: ", rangeHigh, " rangeLow: ", rangeLow, " amplitude: ", NormalizeDouble(rangeHigh-rangeLow, 2));
      //Print("heureminutetest ", heureminutetest);
      double amplitude = NormalizeDouble(rangeHigh-rangeLow, 2);
      //ObjectCreate(0,"rangeHigh",OBJ_HLINE,0,0,rangeHigh);
      //ObjectCreate(0,"rangeLow",OBJ_HLINE,0,0,rangeLow);
      if(tick.last < rangeHigh-inpRatio*amplitude && tick.last > rangeLow+inpRatio*amplitude)
      {
         //Print("IN THE ZONE");
         if(OrdersTotal()<1 && amplitude < InpAmplitudeMax && amplitude>InpAmplitudeMin)
         {
            //trade.BuyStop(0.1,rangeHigh,_Symbol,rangeLow,0,ORDER_TIME_DAY,0,"Buy stop on Pro Order Breakout");
            //trade.SellStop(0.1,rangeLow,_Symbol,rangeHigh,0,ORDER_TIME_DAY,0,"Sell stop on Pro Order Breakout");
            //trade.BuyStop(0.1,rangeHigh,_Symbol,0,0,ORDER_TIME_DAY,0,"Buy stop on Pro Order Breakout");
            //trade.SellStop(0.1,rangeLow,_Symbol,0,0,ORDER_TIME_DAY,0,"Sell stop on Pro Order Breakout");
            placeStopOrders(rangeHigh, rangeLow);
            tradeAllowed = false;
         }
      }     
   }
//---
   if(currentCandle == closeTime) {Print("Close time."); closePositions();}
//---
   Comment(currentCandle,
            "\nopen buy stop");

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
   buyStopResult = trade.BuyStop(InpLots,priceHigh,_Symbol,priceLow,0,ORDER_TIME_DAY,0,"Buy stop");
   if(!buyStopResult) {Print(__FUNCTION__,"--> OrderSend error ", trade.ResultComment()); return false;}
   sellStopResult = trade.SellStop(InpLots,priceLow,_Symbol,priceHigh,0,ORDER_TIME_DAY,0,"Sell stop");
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