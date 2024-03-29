//+------------------------------------------------------------------+
//|                                           Breakout Pro Order.mq5 |
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
CTrade Trade; 

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
// Time Range
input int InpRangeStartHour   = 10; // Range Start hour
input int InpRangeStartMinute = 0;  // Range Start minute
input int InpRangeEndHour     = 10; // Range End hour
input int InpRangeEndMinute   = 30; // Range End minute
input int InpCloseHour        = 21; // Closing hour
input int InpCloseMinute      = 55; // Closing minute

// Entry inputs
input double InpDistanceOrdre    = 4.0;    // Entry gap from inner range pips
input double InpAmplitudeMax     = 100.0;  // Range maximum amplitude
input double InpAmplitudeMin     = 15.0;   // Range minimum amplitude
input double InpRetracementRatio = 0.35;   // Range retracement percentage

// Standard features
input long InpMagic           = 11147;                      // Magic Number
input string InpTradeComment  = "Breakout Pro Order CAC40"; // Expert comment
input double InpLots          = 0.1;                        // Position size
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
bool TradeAllowed = false;
datetime StartTime =0;
datetime EndTime = 0;
datetime CloseTime=0;
double rangeHigh = 0;
double rangeLow = 0;

double BuyEntryPrice = 0;
double SellEntryPrice = 0;

string cmnt = "";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
  
//--- magic
   Trade.SetExpertMagicNumber(InpMagic);
   

//---
   BuyEntryPrice = 0;
   SellEntryPrice = 0;

//--- 
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

//--- convert to times   
   MqlDateTime nowStruct;
   datetime now = TimeCurrent();
   TimeToStruct(now, nowStruct);
   
   nowStruct.sec = 0;
   
   // start time
   nowStruct.hour = InpRangeStartHour;
   nowStruct.min = InpRangeStartMinute;
   StartTime = StructToTime(nowStruct);
   
   // end time
   nowStruct.hour = InpRangeEndHour;
   nowStruct.min = InpRangeEndMinute;
   EndTime = StructToTime(nowStruct);
   
   // close time
   nowStruct.hour = InpCloseHour;
   nowStruct.min = InpCloseMinute;
   CloseTime = StructToTime(nowStruct);
   
//---
   // close orders when time passed

//---
   if(iTime(Symbol(), PERIOD_CURRENT,0) == StartTime) {
      ObjectCreate(0, "New Day",OBJ_VLINE,0,iTime(Symbol(),PERIOD_CURRENT,0),0);
   }

  
//---
   // Close  positions when time passed
   if(now > CloseTime) {closePositions();} 
//---
   // calculate range
   if(now > EndTime) {
      highBetweenTwoHours(StartTime, EndTime);
   }
//---

   // place orders if condition met
   // add retracement
   // add amplitude
   // add distance ordre
   //double amplitude = rangeHigh - rangeLow;
   //double delta = amplitude*InpRetracementRatio;
   ////---
   //double LastPrice = SymbolInfoDouble(Symbol(), SYMBOL_LAST);
   //if(LastPrice <= rangeHigh && LastPrice >= rangeLow && now > EndTime) {
   //   PlaceOrders(rangeHigh, rangeLow);
   //}
   
//---  Commentaires
   cmnt ="";
   cmnt += (string)now;
   cmnt += "\n";
   cmnt += (string)rangeHigh;
   cmnt += "\n";
   cmnt += (string)rangeLow;
   
   Comment(cmnt);

//
// à parttir du moment où on a dépassé l'heure de fin de range on calcule le range
// vérifier si le cours à suffisament retracé
// si le cours à suffisament retracé, mettre les ordres
// voir pour mettre un OCO
   
  } // end of the OnTick() function

//+------------------------------------------------------------------+
//- Place stop orders   ---------------------------------------------+
 
//+------------------------------------------------------------------+
//- High between 2 hours  -------------------------------------------+
bool highBetweenTwoHours(datetime startTime, datetime endTime)
{
   if(!(endTime>startTime)) {Print("endTime must be superior to startTime"); return false;}
   
   else {   
      int startRangePos = iBarShift(Symbol(),PERIOD_M1,startTime);
      int endRangePos   = iBarShift(Symbol(),PERIOD_M1,endTime);
      int barCount      = 1 + startRangePos - endRangePos;
      
      rangeHigh = iHigh(Symbol(),PERIOD_M1,iHighest(Symbol(),PERIOD_M1,MODE_HIGH,barCount,endRangePos));
      rangeLow  = iLow(Symbol(),PERIOD_M1,iLowest(Symbol(),PERIOD_M1,MODE_LOW,barCount,endRangePos));  
      
      return true;
   }
}
//+------------------------------------------------------------------+
//- Place stop orders  ----------------------------------------------+    
bool PlaceOrders(double priceHigh, double priceLow)
{
   bool buyStopResult, sellStopResult  = false;
   //datetime closeTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+endHourMinute);
   //buyStopResult = trade.BuyStop(InpLots,priceHigh,_Symbol,priceLow,0,ORDER_TIME_DAY,0,"Buy stop ProOrder");
   buyStopResult = Trade.BuyStop(InpLots,priceHigh,_Symbol,priceLow,0,ORDER_TIME_SPECIFIED,CloseTime,"Buy stop ProOrder");
   if(!buyStopResult) {Print(__FUNCTION__,"--> OrderSend error ", Trade.ResultComment()); return false;}
   sellStopResult = Trade.SellStop(InpLots,priceLow,_Symbol,priceHigh,0,ORDER_TIME_SPECIFIED,CloseTime,"Sell stop ProOrder");
   if(!sellStopResult) {Print(__FUNCTION__,"--> OrderSend error ", Trade.ResultComment()); return false;}
   
   TradeAllowed = false;
   
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
      if(magic==InpMagic)
      {
         Trade.PositionClose(ticket);
         if(Trade.ResultRetcode()!=TRADE_RETCODE_DONE)
         {
            Print("Failed to close position, ticket: ", (string)ticket, 
                  " result: ", (string)Trade.ResultRetcode(), ": ", Trade.CheckResultRetcodeDescription());
         }
      }
   }  
   return true;    
}