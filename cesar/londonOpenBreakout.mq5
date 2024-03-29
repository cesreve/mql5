//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
#property copyright "cesreve"
#property link      "https://www.mql5.com"
#property version   "1.00"


//+------------------------------------------------------------------+
//| Import class                                                     |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input string hhmmss = "08:00:00";
input double amplitudeCoefficient = 0.15;


//+------------------------------------------------------------------+
//| Globals                                                                  |
//+------------------------------------------------------------------+
MqlTick tick;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
//MqlTick tick;

   SymbolInfoTick(_Symbol, tick);

   string today = StringSubstr(TimeToString(tick.time),0,11);
   datetime startRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"02:00:00");
   datetime endRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"07:20:00");
   datetime closeRange = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"12:00:00");
   datetime closeTrades = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"22:00:00");

   bool inTimeRange = false;
   if(tick.time>startRange)
     {
      inTimeRange=true;
     }

//---
//int startRangePos = 0;
//int endRangePos= 0;
//int barCount =0;
//int highShift=0;
//int lowShift=0;
//double rangeHigh = 0;
//double rangeLow = 0;

//if(tick.time>endRange)
//{
   int startRangePos = iBarShift(_Symbol,_Period,startRange);
//int endRangePos = iBarShift(_Symbol,_Period,endRange);
   int endRangePos = iBarShift(_Symbol,_Period,iTime(0,_Symbol,_Period));
   int barCount = 1 + startRangePos - endRangePos;
   int highShift = iHighest(_Symbol,_Period,MODE_HIGH,barCount,endRangePos);
   int lowShift = iLowest(_Symbol,_Period,MODE_LOW,barCount,endRangePos);
   double rangeHigh = iHigh(_Symbol,_Period,highShift);
   double rangeLow = iLow(_Symbol,_Period,lowShift);
//}

//--- Comments
   string strComment = "";
   strComment += "\nlast: "+(string)tick.last;
   strComment += "\ntoday: "+today;
   strComment += "\ndatetime: "+(string)tick.time;
   strComment += "\nStart range date: "+(string)startRange;
   strComment += "\nEnd range date:"+ (string)endRange;
   strComment += "\ninTimeRange: "+(string)inTimeRange;
   strComment += "\nstartRangePos: "+(string)startRangePos;
   strComment += "\nendRangePos: "+(string)endRangePos;
   strComment += "\nbarCount: "+(string)barCount;
   strComment += "\nrangeHigh: "+(string)rangeHigh;
   strComment += "\nrangeLow: "+(string)rangeLow;
   strComment += "\niTime: "+(string)iTime(0,_Symbol,_Period);
   strComment += "\niTime: "+StringSubstr(TimeToString(iTime(0, _Symbol, _Period)),11,15);

   Comment(strComment);

   if(tick.time>endRange && tick.time<closeTrades
      && tick.last<rangeHigh-(rangeHigh-rangeLow)*amplitudeCoefficient
      && tick.last>rangeLow+(rangeHigh-rangeLow)*amplitudeCoefficient)
     {
      if(PositionsTotal()<1 && OrdersTotal()<1)
        {
         trade.BuyStop(1, rangeHigh, _Symbol, rangeLow,0); // rangeHigh + (rangeHigh-rangeLow));
         trade.SellStop(1, rangeLow, _Symbol, rangeHigh,0); // rangeLow - (rangeHigh-rangeLow));
        }
     }
// mettre un ordre de vente
// trouver un exemple ou le prix est le plus haut au moment de la fin du range
// pas de take profit, cloturer en fin de journee
// fonction qui cancel un ordre stop si ordre stop ouvert dans l'autre sens ? '
// utiliser HistorySelect pour empecher d'ouvrir un nouvel ordre stop si un a edja été ouvert (cas ou déclenché et stop loss hit avant fin du range et donc ré ouverture de ordre stop).


// pour CAC40 ouverture, utiliser Itime

   if(tick.time > StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"07:20:00")
      && tick.time < StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"09:00:00"))
      {  
         //Print("test count stop orders");
         CountBuyStopOrders();   
      }

   if(tick.time>closeTrades)
     {
      CountBuyStopOrders();
      CloseOpennedPosition();
      CancelPendingOrders();
     }


  } //end OnTick() function

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CountBuyStopOrders()
  {
   
   HistorySelect(StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"00:00:00"), TimeCurrent());
   uint        TotalNumberOfDeals=HistoryDealsTotal();
   ulong       TicketNumber = 0;

   for(uint i=0; i<TotalNumberOfDeals; i++)
     {
      if((TicketNumber=HistoryDealGetTicket(i))>0)
        {

         long OrderType=HistoryDealGetInteger(TicketNumber, DEAL_TYPE);
         Print(TotalNumberOfDeals, "  ", TicketNumber, "  ", OrderType);
         if(OrderType==ORDER_TYPE_BUY_STOP) // || OrderType==ORDER_TYPE_SELL)
           {
            Print(OrderType," ORDER_TYPE_BUY_STOP" );
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOpennedPosition()
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(PositionSelectByTicket(ticket))
        {
         if(trade.PositionClose(ticket))
           {
            Print("Poistion closed with profit of: ",PositionGetDouble(POSITION_PROFIT));
            Print("Position closed: ",trade.ResultRetcode());
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelPendingOrders()
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      trade.OrderDelete(ticket);
      Print("Order deleted: ",trade.ResultRetcode());
     }
  }
//+------------------------------------------------------------------+
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[2];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
