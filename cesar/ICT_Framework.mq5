//+------------------------------------------------------------------+
//|                                                ICT_Framework.mq5 |
//|                                                           ceezer |
//+------------------------------------------------------------------+
#property copyright "ceezer"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MqlTick tick;
#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
//--- If Not a new bar, do not go further
   if(!IsNewbar()) {return;}

//---
   SymbolInfoTick(_Symbol, tick);

   string today = StringSubstr(TimeToString(tick.time),0,11);
   // à voir ensuite si on skip les 30 premières minutes
   datetime start = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"10:00:00");
   datetime end   = StringToTime(StringSubstr(TimeToString(tick.time),0,11)+"11:00:00");

//--- highs and lows
   double hh1 = iHigh(_Symbol,_Period,1);
   //double hh2 = iHigh(_Symbol,_Period,2);
   double hh3 = iHigh(_Symbol,_Period,3);
   
   double ll1 = iLow(_Symbol,_Period,1);
   //double ll2 = iLow(_Symbol,_Period,2);
   double ll3 = iLow(_Symbol,_Period,3);

//--- conditions
   //--- for a buy limit
   bool buyLimit = ll1 >hh3;
   double buyLimitPrice = ll1;
   double buyLimitStopLoss = ll3;
   double buyLimitTakeProfit = ll1 + (ll1 - ll3);
   
   if(buyLimit && tick.time>start)
   {
      trade.BuyLimit(1, buyLimitPrice, _Symbol,buyLimitStopLoss,buyLimitTakeProfit);
   } 
   //--- for a sell limit
   bool sellLimit = hh1 < ll3;   
   
   

  
//--- Comments && tests 
   string cmnt ="";
   cmnt += "\nbuylimit: "+(string)buyLimit;
   cmnt += "\nbuylimit: "+(string)sellLimit;
   Comment(cmnt);
   
   
   
   //cmnt += "\nstart:"+(string)start;
   //cmnt += "\nend: "+(string)end;
   //cmnt += "\ntime: "+(string)tick.time;
   //bool test = tick.time>start;
   //cmnt += "\nbool: "+(string)test;
   Comment(cmnt);
   //if(tick.time>start && tick.time<end){Comment(cmnt);}
   
   
   
   
   
   
   
  } // end of the OnTick() Function
//+------------------------------------------------------------------+
//|                    Custom functions                              |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+ Get Time for specified bar index    -----------------------------+
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
//- New Bar  --------------------------------------------------------+
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