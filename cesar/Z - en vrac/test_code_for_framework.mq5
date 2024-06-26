//+------------------------------------------------------------------+
//|                                                    test_code.mq5 |
//|                                                           ceezer |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ceezer"
#property link      ""
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade Trade;

// test area
#include <Orchard/Frameworks/Framework_3.06/Framework.mqh>
CTimeRange *TimeRange;

//
input double InpStopLoss = 100;
input double InpTakeProfit = 100;
input double InpVolume = 0.1;

bool FirstTradeAllowed ;

input int InpMagicNumber = 13112023;
double stopLoss = 154.115;

// test time range
//input string InpStartTime = "10";
//input string InpEndTime = "11";
input datetime InpStartTime = 10;
input datetime InpEndTime = 11;

datetime startRange;
datetime endRange;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   FirstTradeAllowed = true;
//---
   Trade.SetExpertMagicNumber(InpMagicNumber);
//---
   Print( "INIT: ", EnumToString( (ENUM_SYMBOL_SECTOR)SymbolInfoInteger(Symbol() , SYMBOL_SECTOR) ) );
//---
   //TimeRange = new CTimeRange(startRange, endRange);
   TimeRange = new CTimeRange(InpStartTime , InpStartTime);
   TimeRange.printTest(); 
//---
   return(INIT_SUCCEEDED);

}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if (FirstTradeAllowed) {
      double ask = SymbolInfoDouble( Symbol(), SYMBOL_ASK );
      double bid = SymbolInfoDouble( Symbol(),  SYMBOL_BID );
      
      Trade.Buy(InpVolume, Symbol() , ask, stopLoss, 0, "test_code");
      //OpenTrade( ORDER_TYPE_BUY, double volume, double price, double sl , double tp  )
      //OpenTrade( ORDER_TYPE_SELL, )
      FirstTradeAllowed = false;
   }
   
//---
   if ( IsNewbar() ) { 
      double price = SymbolInfoDouble( Symbol() , SYMBOL_BID);
      if (price < stopLoss) {
         closePositions();
      }
   }
//---
   
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
//+------------------------------------------------------------------+
// ----> Objectif: sur range breakout, ne pas sortir sur une gross fluctuation (exemple 16 avril 2024 USD/JPY)
// checker aussi le spread
// fermer order sans stop loss
// identifier le range
// identifier les prix bordures
// looper dans les trades ouverts et fermer si pour un buy le prix est sous le stop loss
// tester sur le 16 avril 16h30 pour 
