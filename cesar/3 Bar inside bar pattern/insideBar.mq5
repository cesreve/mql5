//+------------------------------------------------------------------+
//|                                                     Template.mq5 |
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
input int InpMagicNumber = 6122023;

//--- Hours 
input group "==== Trading hours ====";
input int InpStartHour        = 10; // Start hour
input int InpStartMinute      = 0;  // Start minute
input int InpStopHour         = 18; // Stop trading hour
input int InpStopMinute       = 0;  // Stop trading hour minute
input int InpCloseHour        = 22; // Close all positions hour
input int InpCloseMinute      = 55; // Close all positions minute


//---
input int InpBreakEvenTreshold = 0;
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+ 
MqlTick tick;
MqlDateTime nowTimeStruct;

datetime nowTime = 0;
datetime startTime = 0;
datetime stopTime = 0;
datetime closeTime = 0;

//---
int cntBuy = 0;
int cntSell = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);   
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
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   calculateDatetimes();
   nowTime = TimeCurrent();
   TimeToStruct(nowTime, nowTimeStruct);

//---
   if(!IsNewbar()) {return;};

//--- indicators 
//1
   double close1 = iClose(Symbol(), Period(), 1);
//2
   double close2 = iClose(Symbol(), Period(), 2);
   double low2 = iLow(Symbol(), Period(), 2);
   double high2 = iHigh(Symbol(), Period(), 2);
//3
   double close3 = iClose(Symbol(), Period(), 3);
   double low3 = iLow(Symbol(), Period(), 3);
   double high3 = iHigh(Symbol(), Period(), 3);
//4
   double close4 = iClose(Symbol(), Period(), 4);


//--- Trade conditions long
//if(close1 > close2 && high2 < high3 && low2 > low3 && close3 > close4) {Print("Buy");}
if(close1 > high2 && high2 < high3 && low2 > low3 && close3 > close4) {Print("Buy");}
 
//if(close1 < close2 && high2 < high3 && low2 > low3 && close3 < close4) {Print("Sell");}
if(close1 < low2 && high2 < high3 && low2 > low3 && close3 < close4) {Print("Sell");}
          


  }
//+-----------------    END OF ON TICK FUNCTION    ------------------+



//+------------------------------------------------------------------+
// ---------            Custom functions            -----------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//- Calculate datetimes  --------------------------------------------+
void calculateDatetimes()
{
   //--- convert to times   
   MqlDateTime nowStruct;
   datetime now = TimeCurrent();
   TimeToStruct(now, nowStruct);   
   nowStruct.sec = 0;
   
   // start time
   nowStruct.hour = InpStartHour;
   nowStruct.min = InpStartMinute;
   startTime = StructToTime(nowStruct);
   
   // stop time
   nowStruct.hour = InpStopHour;
   nowStruct.min = InpStopMinute;
   stopTime = StructToTime(nowStruct);
   
   // close time
   nowStruct.hour = InpCloseHour;
   nowStruct.min = InpCloseMinute;
   closeTime = StructToTime(nowStruct);
}

////+------------------------------------------------------------------+
////- Count positions  ------------------------------------------------+
bool CountOpenPositions()
{
   cntBuy = 0;
   cntSell = 0;
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
         long type;
         if(!PositionGetInteger(POSITION_TYPE, type)) {Print("Failed to get postion type"); return false;}
         if(type==POSITION_TYPE_BUY) {cntBuy++;}
         if(type==POSITION_TYPE_SELL) {cntSell++;}
      }
   }   
   return true;
}

//+------------------------------------------------------------------+
// Set to BE   ------------------------------------------------------+
bool setBreakEven()
{
   //double currPrice = 
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to get position magic number"); return false;}
      if(magic==InpMagicNumber) {
         double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         double priceCurrent = PositionGetDouble(POSITION_PRICE_CURRENT);
         double positionSL = PositionGetDouble(POSITION_SL);
         double positionTP = PositionGetDouble(POSITION_TP);
         //if( MathAbs(priceCurrent-priceOpen) > MathAbs(priceCurrent - positionSL) ) {
         if( MathAbs(priceCurrent-priceOpen) > InpBreakEvenTreshold ) {
            trade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_TP) );
         }
         
      }
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
////+------------------------------------------------------------------+
////- New Bar  --------------------------------------------------------+
bool IsNewbar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(Symbol(), Period(), 0);
   if(previousTime!=currentTime)
     {
      previousTime=currentTime;
      return true;
     }
   return false;  
  }


