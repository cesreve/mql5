//+------------------------------------------------------------------+
//|                                          Kangaroo Tail v1.01.mq5 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Changements:
// utilisation d'ordre directs, supressiond es ordres stop
// ajout d'une heure de fin de trading
// ajout d'une contrainte de spread
// piste, mettres des TP SL en %
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.01"
#property description "Kangaroo Tail trading system\nReversal if a candle is a peak" 


//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int InpMagicNumber = 13112023;
input double InpLots = 0.01;
input string InpTradeComment = "Kangaroo Tail";

//--- Hours 
input group "==== Trading hours ====";
input int InpStopHour        = 18; // Close all positions hour
input int InpStopMinute      = 00; // Close all positions minute

input int InpCloseHour        = 21; // Close all positions hour
input int InpCloseMinute      = 45; // Close all positions minute

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+ 
MqlTick tick;
MqlDateTime nowTimeStruct;

datetime nowTime = 0;
datetime stopTime = 0;
datetime closeTime = 0;
//---
int cntBuy = 0;
int cntSell = 0;

bool longAllowed = false;
bool shortAllowed = false;
//---
string comm;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);   
//---
   calculateDatetimes();
   CountOpenPositions();
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
   comm = "";
   comm += InpTradeComment;
   comm += "\n";
   comm += (string)Symbol();
   comm += "\n";
   comm += (string)closeTime;
   comm += "\n";
   comm += (string)InpLots;
   comm += "\n";
   Comment(comm);
//---
   calculateDatetimes();
   CountOpenPositions();
   nowTime = TimeCurrent();
   TimeToStruct(nowTime, nowTimeStruct);

//---
   if(nowTime >= closeTime) { 
      closePositions(); 
      cancelPendingOrders();
      }

//---
    if(IsNewbar()) { longAllowed = true; shortAllowed = true; }
//--- indicators 
//1
   double high1 = iHigh(Symbol(), Period(), 1);
   double low1 = iLow(Symbol(), Period(), 1);
//2
   double low2 = iLow(Symbol(), Period(), 2);
   double high2 = iHigh(Symbol(), Period(), 2);
//3
   double low3 = iLow(Symbol(), Period(), 3);
   double high3 = iHigh(Symbol(), Period(), 3);
//
   double ask = SymbolInfoDouble( Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble( Symbol(), SYMBOL_BID);
//--- trading conditions
//--- Long setup
   if( low2 < low3 && low2 < low1) {
      if( ask > high1 && longAllowed ) { 
         if(trade.Buy( InpLots, Symbol(), ask, low1, 0, InpTradeComment ))longAllowed = false;
         }
         
      //trade.BuyStop(InpLots, high1, Symbol(), low1, 0, ORDER_TIME_DAY, 0, InpTradeComment);
   }
   
   if( high2 > high3 && high2 > high1 ) {
      if( bid < low1 && shortAllowed ) { 
         if(trade.Sell( InpLots, Symbol(), bid, high1, 0, InpTradeComment)) shortAllowed = false ; 
         }
         
   }
   
//---
   
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
//- Cancel pending orders  ------------------------------------------+
bool cancelPendingOrders()
{
   //Print("start of cancelPendingOders function");
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket<=0) {Print("Fail to get order ticket"); return false;}
      if(!OrderSelect(ticket)) {Print("Failed to select order"); return false;}
      long magic;
      if(!OrderGetInteger(ORDER_MAGIC, magic)) {Print("Failed to get order magic number"); return false;}
      if(magic==InpMagicNumber)
      {
         long orderType;
         if(!OrderGetInteger(ORDER_TYPE, orderType)) {Print("Failed to get order type"); return false;}
         if(orderType==ORDER_TYPE_SELL_STOP || orderType==ORDER_TYPE_BUY_STOP)
         Print("Delete Order");
         {
            if(!trade.OrderDelete(ticket)) {Print("Failed to delete order"); return false;}
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