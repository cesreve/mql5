//+------------------------------------------------------------------+
//|                                                    NightFlat.mq5 |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;
MqlTick tick;
MqlDateTime now;
string comm="";
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ====";
static input long InpMagicNumber = 8533; 

input group "==== Trading ====";
input double InpLotSize = 0.01;
input int InpLevel1     = 150;
input int InpLevel2     = 200;
input int InpLevel3     = 300;
input int InpLevel4     = 350;

input int InpCloseOrdersHour = 2;
input int InpClosePositionsHour = 18;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);  
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
   if(!IsNewBar()) {return;}
//---
   TimeToStruct(TimeCurrent(), now);
   if(!SymbolInfoTick(_Symbol,tick)) {Print("Faield to get current symbol tick."); return;}

//---
   if(now.hour == InpCloseOrdersHour) {cancelPendingOrders();}
   if(now.hour == InpClosePositionsHour) {closePositions();}
//---
   comm = "";
   comm += (string)now.day_of_week;
   comm += "\n";
   comm += (string)iTime(_Symbol,_Period,1);
   comm += "\n";
   
   Comment(comm);
   
   if(now.hour == 23 && now.day_of_week >= 1 && now.day_of_week <= 4) 
      {
         Print("its time ", iTime(_Symbol,_Period,1)," ");
         setPendingOrders(iOpen(_Symbol,_Period,1));
      }
   
  } // --> end of the OnTick() function
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                  Custom functions                                +
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//- Set pending orders  ---------------------------------------------+
bool setPendingOrders(double closePrice)
{
   if(trade.BuyLimit(InpLotSize, closePrice-InpLevel4*_Point,_Symbol,closePrice-InpLevel4*_Point-500*_Point,closePrice,0,0,"Night Flat EA") 
      && trade.BuyLimit(InpLotSize, closePrice-InpLevel3*_Point,_Symbol,closePrice-InpLevel4*_Point-500*_Point,closePrice,0,0,"Night Flat EA") 
      && trade.BuyLimit(InpLotSize, closePrice-InpLevel2*_Point,_Symbol,closePrice-InpLevel4*_Point-500*_Point,closePrice,0,0,"Night Flat EA") 
      && trade.BuyLimit(InpLotSize, closePrice-InpLevel1*_Point,_Symbol,closePrice-InpLevel4*_Point-500*_Point,closePrice,0,0,"Night Flat EA") 
      
      && trade.SellLimit(InpLotSize, closePrice+InpLevel4*_Point,_Symbol,closePrice+InpLevel4*_Point+500*_Point,closePrice,0,0,"Night Flat EA")
      && trade.SellLimit(InpLotSize, closePrice+InpLevel3*_Point,_Symbol,closePrice+InpLevel4*_Point+500*_Point,closePrice,0,0,"Night Flat EA")
      && trade.SellLimit(InpLotSize, closePrice+InpLevel2*_Point,_Symbol,closePrice+InpLevel4*_Point+500*_Point,closePrice,0,0,"Night Flat EA")
      && trade.SellLimit(InpLotSize, closePrice+InpLevel1*_Point,_Symbol,closePrice+InpLevel4*_Point+500*_Point,closePrice,0,0,"Night Flat EA")
      ) {return true;}
   return false;
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
         //long type;
         //if(!PositionGetInteger(POSITION_TYPE, type)) {Print("Failed to get postion type"); return false;}                  
         //if(direction==-1 && type==POSITION_TYPE_BUY) {continue;}
         //if(direction==1 && type==POSITION_TYPE_SELL) {continue;}
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
         {
            if(!trade.OrderDelete(ticket)) {Print("Failed to delete order"); return false;}
         }
      }
   }
   return true;   
}
//+------------------------------------------------------------------+
//- New Bar  --------------------------------------------------------+
bool IsNewBar()
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