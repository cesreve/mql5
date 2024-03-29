//+------------------------------------------------------------------+
//|                                            Intraday Movement.mq5 |
//|                  https://www.youtube.com/watch?v=dtPTxa9CS6w     |
//+------------------------------------------------------------------+

#property copyright "Copyright 2013-2022, Orchard Forex"
#property link "https://www.orchardforex.com"
#property link "https://www.youtube.com/watch?v=dtPTxa9CS6w"
#property version "1.00"

//+------------------------------------------------------------------+
//| Inputs

input int InpTradeCounter   = 5;
//input int InpTradeGapPoints = 500;
input int InpSLPoints       = 400;
input int InpTPPoints       = 700;
input double InpVolume      = 0.01;
input double InpMultiplier  = 0.40;

input int InpMagicNumber = 1597412;
//+------------------------------------------------------------------+
//| Variables

int TradeCounter;
//double TradeGap;
double SL;
double TP;

double close1;
double open1;
double high1;
double low1;
double amplitude;
double multiplier;

MqlTick tick;

struct SOCOPair
{
   ulong ticket1;
   ulong ticket2;
   SOCOPair() {}
   SOCOPair( ulong t1, ulong t2 ) {
      ticket1 = t1;
      ticket2 = t2;
   }
};

SOCOPair OCOPairs[];
//+------------------------------------------------------------------+
//| Include

#include <Trade/Trade.mqh>
CTrade Trade;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   TradeCounter = InpTradeCounter;
   //TradeGap     = PointsToDouble( InpTradeGapPoints );
   SL           = PointsToDouble( InpSLPoints );
   TP           = PointsToDouble( InpTPPoints );
   multiplier   = InpMultiplier;
   //tradeAllowed = false;
   
   Print(SL," ",TP);
//---
   Trade.SetExpertMagicNumber(InpMagicNumber);

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

//--- Only trade until counter reaches zero, nombre de trades autorisés 
   //if ( TradeCounter <= 0 ) return;
//---
   SymbolInfoTick(_Symbol, tick);
   datetime currentCandle = iTime(_Symbol,PERIOD_M15,0);
   datetime closeTime = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"21:45");
   
   if(currentCandle > closeTime) {closePositions(); cancelPendingOrders();}
//--- on attendd une nouvelle barre
   if(!IsNewBar()) { return; }
//--- new day ?
   if(!IsNewDay()) { return; }

//---
   close1 = iClose(_Symbol,PERIOD_D1,1);
   open1  = iOpen(_Symbol,PERIOD_D1,1);
   high1  = iHigh(_Symbol,PERIOD_D1,1);
   low1   = iLow(_Symbol,PERIOD_D1,1);
   
   amplitude = (high1 - low1)*multiplier;

//---
//if(tradeAllowed = true)
//{
   ulong buyTicket  = OpenOrder( ORDER_TYPE_BUY_STOP,  close1 + amplitude);
   ulong sellTicket = OpenOrder( ORDER_TYPE_SELL_STOP, close1 - amplitude);
   
   //tradeAllowed = false;
//}
   OCOAdd( buyTicket, sellTicket );
   //TradeCounter--;
//---
   

} // end of the OnTick() function

//+------------------------------------------------------------------+
//|                        CUSTOM FUNCTIONS                          +
//+------------------------------------------------------------------+
//- Set pending orders  ---------------------------------------------+
ulong OpenOrder( ENUM_ORDER_TYPE type, double price ) 
{
   double tp;
   double sl;   
   ulong ticket = 0;
   if ( type == ORDER_TYPE_BUY_STOP) {
      tp    = price + TP;
      sl    = price - SL;
      if(Trade.BuyStop(InpVolume, price, _Symbol, sl, tp,ORDER_TIME_GTC)) {ticket = Trade.ResultOrder();}
   }
   if(type == ORDER_TYPE_SELL_STOP)
   {
      tp    = price - TP;
      sl    = price + SL;
      if(Trade.SellStop(InpVolume, price, _Symbol, sl, tp, ORDER_TIME_GTC)) {ticket = Trade.ResultOrder();}
   }
   return ticket;
}
//+------------------------------------------------------------------+
//- Paring orders together   ----------------------------------------+
void OCOAdd( ulong ticket1, ulong ticket2 ) 
{
   if ( ticket1 <= 0 || ticket2 <= 0 ) return;
   int      count = ArraySize( OCOPairs );
   SOCOPair pair( ticket1, ticket2 );
   ArrayResize( OCOPairs, count + 1 );
   OCOPairs[count] = pair;
}
//+------------------------------------------------------------------+
//- Get info if one order is deleted   ------------------------------+
void OnTradeTransaction( const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result )
{
   if ( trans.type == TRADE_TRANSACTION_ORDER_DELETE ) OCOClose( trans.order );
}
//+------------------------------------------------------------------+
//- Delete an order with the ticket   -------------------------------+
bool CloseOrder( ulong ticket ) { return Trade.OrderDelete( ticket ); }

//+------------------------------------------------------------------+
//- Check the ticket pairing   --------------------------------------+
void OCOClose( ulong ticket ) 
{
   for ( int i = ArraySize( OCOPairs ) - 1; i >= 0; i-- ) {
      if ( OCOPairs[i].ticket1 == ticket ) {
         CloseOrder( OCOPairs[i].ticket2 );
         OCORemove( i );
         return;
      }
      if ( OCOPairs[i].ticket2 == ticket ) {
         CloseOrder( OCOPairs[i].ticket1 );
         OCORemove( i );
         return;
      }
   }
}
//+------------------------------------------------------------------+
//- Remove ticket from structure   ----------------------------------+
void OCORemove( int index ) 
{
   ArrayRemove( OCOPairs, index, 1 );
   return;
}
//+------------------------------------------------------------------+
//- Count open postitions   -----------------------------------------+
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
         if(Trade.PositionClose(ticket)) {Print("Position closed");}
         if(Trade.ResultRetcode()!=TRADE_RETCODE_DONE)
         {
            Print("Failed to close position, ticket: ", (string)ticket, 
                  " result: ", (string)Trade.ResultRetcode(), ": ", Trade.CheckResultRetcodeDescription());
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
         if(orderType==ORDER_TYPE_SELL_LIMIT || orderType==ORDER_TYPE_BUY_LIMIT)
         Print("Delete Order");
         {
            if(!Trade.OrderDelete(ticket)) {Print("Failed to delete order"); return false;}
         }
      }
   }
   return true;   
}
//+------------------------------------------------------------------+
//- Convert into points  --------------------------------------------+
double PointsToDouble( int points ) {
   double point = SymbolInfoDouble( Symbol(), SYMBOL_POINT );
   return ( point * points );
}
//+------------------------------------------------------------------+
//- New Bar  --------------------------------------------------------+
bool IsNewBar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, _Period, 0);
   if(previousTime!=currentTime) { previousTime=currentTime; return true; }
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