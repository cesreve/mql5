//+------------------------------------------------------------------+
//|                                                    breakeven.mq5 |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| Variables                                                        |
//+------------------------------------------------------------------+
int magicNumber = 111;
CTrade trade;
MqlTick tick;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(magicNumber); 
   
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
//--- if not a new bar, do not go further
   if(!IsNewbar()) {return;}

//--- get tick data
   if(!SymbolInfoTick(_Symbol,tick)) {Print("Faield to get current symbol tick."); return;}  
   
//--- count  open positions
   int cntBuy = 0, cntSell = 0;
   if(!CountOpenPositions(cntBuy,cntSell)) {Print("Failed to count open positions."); return;}

//--- open a long position
   //if(cntBuy==0) {trade.Buy(0.1, _Symbol, tick.ask, tick.ask - 900*_Point,tick.bid + 900*_Point, "BUY");}
   if(cntSell==0) {trade.Sell(0.1, _Symbol, tick.bid, tick.bid + 900*_Point, tick.ask - 900*_Point, "SELL");}
//--- check for breakeven
   if(cntBuy+cntSell>0) {trailingStop(200);}
   
   //if(cntBuy>0) {
      //if(trailingStop(350)) { Print("SL set to BE");}}



  } // end of the OnTick() function

//+------------------------------------------------------------------+
//|                  Custom functions                                +


//+------------------------------------------------------------------+
//- Count positions  ------------------------------------------------+
bool CountOpenPositions(int &cntBuy, int &cntSell)
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
      if(magic==magicNumber)
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
//- Count positions  ------------------------------------------------+
bool trailingStop(int pipsLevel) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}
      // get positions infos
      double positionStopLoss = PositionGetDouble(POSITION_SL);
      double positionTakeProfit = PositionGetDouble(POSITION_TP);
      double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double positionCurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      if(positionStopLoss != positionOpenPrice) 
      {
         long type = PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY && (positionCurrentPrice - positionOpenPrice)/_Point > pipsLevel )
         {
            if(trade.PositionModify(ticket,positionOpenPrice,positionTakeProfit)) {Print("SL set to BE"); return true;}
         }
         if(type == POSITION_TYPE_SELL && (positionOpenPrice - positionCurrentPrice)/_Point > pipsLevel )
         {
            if(trade.PositionModify(ticket,positionOpenPrice,positionTakeProfit)) {Print("SL set to BE"); return true;}
         }            
      }
  }
  return false;
}
//+------------------------------------------------------------------+
//- New bar   -------------------------------------------------------+
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
//+----------------------   T H E    E N D   ------------------------+