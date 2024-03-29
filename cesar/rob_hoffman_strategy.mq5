//+------------------------------------------------------------------+
//|                                         rob_hoffman_strategy.mq5 |
//|                                                          cesreve |
//|                                                                  |
//+------------------------------------------------------------------+


// 45% de la barre pour le retracement -> x% de retracement
// 2 moyennes mobiles,
// "angle" entre les MM, ecart/aire, convergence/divergence ? somme des écarts divisé par prix
// écarts entre prix et MMs
// sortie ?
// ajouter fonction de cancel order stop
// ajustement de d'ordre stop si nouveau signal

#property copyright "cesreve"
#property link      ""
#property version   "1.00"


#include <Trade\Trade.mqh>
CTrade trade;

input group "Fast Moving Average";
input int    fast_ma_period        = 20;          // ma_period
input int    fast_ma_shift         = 0;            // ma_shift

input group "Slow Moving Average";
input int    slow_ma_period        = 50;          // ma_period
input int    slow_ma_shift         = 0;            // ma_shift

input group "Retracement";
input int    retracement_percentage= 45;          // ma_period


double point;

#define MA_MAGIC 01122022

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Define Magic
   trade.SetExpertMagicNumber(MA_MAGIC);

//--- Broker digits
   point = _Point;

   double Digits = _Digits;
   if((_Digits == 3) || (_Digits == 5))
     {
      point*=10;
     }

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

   Comment("MA fast: ", getMA(1, fast_ma_period, fast_ma_shift, _Symbol),
           "\nMA slow: ", getMA(1, slow_ma_period, slow_ma_shift, _Symbol),
           "\nretracement: ", isRetracement(_Symbol, 1),
           "\nTrend: ", trendDirection(_Symbol, 1),
           "\nOrder: ", setOrder(_Symbol, 1)
          );

//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);

   if(time_0==PrevBars)
      return;
   PrevBars=time_0;



   if(PositionsTotal()<1 && OrdersTotal()<1)
     {
      if(setOrder(_Symbol, 1)=="BUY STOP")
        {
         if(trade.BuyStop(1, iHigh(_Symbol,PERIOD_CURRENT,1), _Symbol, iLow(_Symbol,PERIOD_CURRENT,1)-15,iHigh(_Symbol,PERIOD_CURRENT,1)+15))
           {
            ulong ticket = trade.ResultOrder();

            // Check if it worked
            if(ticket > 0)
              {
               Print("Ordre placé BS ",  " Ticket: ", ticket);
              }
           }
        }
     }

   if(OrdersTotal()>0)
     {
      if(trendDirection(_Symbol,1)=="BEAR")
        {
         cancelPendingOrder("BS");
        }
     }
  }

//+------------------------------------------------------------------+
// Get MA values
//+------------------------------------------------------------------+
double getMA(int index, int ma_period, int ma_shift, string symbol)
  {
   double MABuffer[];
   ArraySetAsSeries(MABuffer, true);
   int MA;
   if((MA=iMA(symbol, _Period, ma_period, ma_shift, MODE_EMA, PRICE_CLOSE))==INVALID_HANDLE)
     {
      Print("Error creating MA indicator for: ", symbol);
      return(false);
     }

   if(CopyBuffer(MA, 0, index, 1, MABuffer))
     {
      if(ArraySize(MABuffer) > 0)
        {
         return MABuffer[0];
        }
     }
   return -1.0;
  }

//+------------------------------------------------------------------+
// Retracement indicator
//+------------------------------------------------------------------+
double isRetracement(string symbol, int index)
  {
   double open = iOpen(symbol, PERIOD_CURRENT, index);
   double close = iClose(symbol, PERIOD_CURRENT, index);
   double high = iHigh(symbol, PERIOD_CURRENT, index);
   double low = iLow(symbol, PERIOD_CURRENT, index);

   double z= 0;
   if(trendDirection(symbol, index)=="BULL" && high!=low)
     {
      if(high-MathMax(open,close) >= 0.45*(high-low))
         z = 1.0;
     }
   else
      if(trendDirection(symbol, index)=="BEAR" && high!=low)
        {
         if(MathMin(open, close)-low > 0.45*(high-low))
            z= -1.0;
        }
   return z;
  }

//+------------------------------------------------------------------+
// Trend indicator
//+------------------------------------------------------------------+
string trendDirection(string symbol, int index)
  {
   string direction = NULL;

   if(getMA(index, fast_ma_period, fast_ma_shift, symbol) > getMA(index, slow_ma_period, slow_ma_shift, symbol))
      direction = "BULL";

   else
      direction= "BEAR";

   return direction;
  }

//+------------------------------------------------------------------+
// Order condition functions
//+------------------------------------------------------------------+
string setOrder(string symbol, int index)
  {
   string order = "DO NOTHING";
//buy stop
   if(trendDirection(symbol, index) == "BULL" && isRetracement(symbol,index)>0)
      order = "BUY STOP";

//sell stop
   if(trendDirection(symbol, index) == "BEAR" && isRetracement(symbol,index)<0)
      order = "SELL STOP";

//
   return order;
  }

//+------------------------------------------------------------------+
//| Cancel pending order
//+------------------------------------------------------------------+
void cancelPendingOrder(string orderType)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      long OrderType = OrderGetInteger(ORDER_TYPE);
      if(OrderSelect(ticket) && orderType=="BS" && OrderType==ORDER_TYPE_BUY_STOP)
        {
         if(trade.OrderDelete(ticket))
           {}
        }
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
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
