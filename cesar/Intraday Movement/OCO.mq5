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

input int InpTradeCounter     = 5;
input int InpTradeGapPoints   = 500;
input int InpSLTPPoints       = 50;
input double InpVolume        = 0.01;


input int InpMagicNumber = 1597412;
//+------------------------------------------------------------------+
//| Variables

int TradeCounter;
double TradeGap;
double SLTP;


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
   TradeGap     = PointsToDouble( InpTradeGapPoints );
   SLTP         = PointsToDouble( InpSLTPPoints );

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

//--- Only trade until counter reaches zero, nombre de trades autorisés 
   if ( TradeCounter <= 0 ) return;
   
//--- on attendd une nouvelle barre
   if(!IsNewBar()) {return;} 

//---
   ulong buyTicket  = OpenOrder( ORDER_TYPE_BUY_STOP,  close1 + amplitude);
   ulong sellTicket = OpenOrder( ORDER_TYPE_SELL_STOP, close1 - amplitude);

   OCOAdd( buyTicket, sellTicket );
   TradeCounter--;
//---
   

} // end of the OnTick() function

//+------------------------------------------------------------------+
//|                        CUSTOM FUNCTIONS                          +
//+------------------------------------------------------------------+
//- Set pending orders  ---------------------------------------------+
ulong OpenOrder( ENUM_ORDER_TYPE type, double price ) {

   //double price;
   double tp;
   double sl;
   if ( type % 2 == ORDER_TYPE_BUY ) {
      price = SymbolInfoDouble( Symbol(), SYMBOL_ASK ) + TradeGap;
      tp    = price + SLTP;
      sl    = price - SLTP;
   }
   else {
      price = SymbolInfoDouble( Symbol(), SYMBOL_BID ) - TradeGap;
      tp    = price - SLTP;
      sl    = price + SLTP;
   }  
   ulong ticket = 0;
   if ( Trade.OrderOpen( Symbol(), type, InpVolume, 0, price, sl, tp, ORDER_TIME_GTC ) ) ticket = Trade.ResultOrder();

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
