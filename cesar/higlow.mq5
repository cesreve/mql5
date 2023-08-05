//+------------------------------------------------------------------+
//|                                                       higlow.mq5 |
//|                                                          cesreve |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "cesreve"
#property link      "https://www.mql5.com"
#property version   "1.00"


//
//---
//+------------------------------------------------------------------+
//| Import class                                                     |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
CTrade trade;


//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input string hhmmss = "08:00:00";

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
  
   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   
   datetime t1 = StringToTime(StringSubstr(TimeToString(iTime(0, _Symbol, _Period)),0,11)+"06:00:00");
   
   //if(t1>tick.time) {return;}
   
   
   MqlDateTime lastBar, currBar, nowTime;
   TimeToStruct(TimeCurrent(), nowTime);
   TimeToStruct(iTime(0, _Symbol, _Period), currBar);
   TimeToStruct(iTime(1, _Symbol, _Period), lastBar);
   
   string strComment = "";
   strComment += (string)tick.time;
   strComment += "\n"+ (string)tick.time_msc;
   //strComment += "\n"+StringSubstr(TimeToString(iTime(0, _Symbol, _Period)),0,11)+"00:03:00";
   //datetime datestart = StringToTime(StringSubstr(TimeToString(iTime(0, _Symbol, _Period)),0,11)+"00:03:00");

   //Comment(tick.time, "\n", TimeToString(iTime(0, _Symbol, _Period), TIME_DATE|TIME_MINUTES),"\n",nowTime.hour, "\n", currBar.hour,  "\n",lastBar.hour);
   
   ////Comment(now.day,"  ", now.hour,"  ", now.min);
   //string   s           = Symbol();
   //ENUM_TIMEFRAMES p    = _Period;
   //datetime t1 = StringToTime(StringSubstr(TimeToString(iTime(0, _Symbol, _Period)),0,11)+"03:00:00");
   //datetime t2 = iTime(0, _Symbol, _Period);
   ////datetime t2          = now;
   //int      t1_shift    = iBarShift(_Symbol,_Period,t1);
   //int      t2_shift    = iBarShift(_Symbol,_Period,t2);
   //int      bar_count   = t1_shift-t2_shift;
   //int      high_shift  = iHighest(_Symbol,_Period,MODE_HIGH,bar_count,t2_shift);
   //int      low_shift   = iLowest(_Symbol,_Period,MODE_LOW,bar_count,t2_shift);
   //double   high        = iHigh(_Symbol,_Period,high_shift);
   //double   low         = iLow(_Symbol,_Period,low_shift);
   //Print(t1," -> ",t2,":: High = ",high," Low = ",low);   
   //Comment(t1," -> ",t2,":: High = ",high," Low = ",low);
   //strComment += "\ndatetime start: "+StringSubstr(TimeToString(iTime(0, _Symbol, _Period)),0,11)+"00:03:00";
   //strComment += "\nbar_count: "+ (string)bar_count;
   //strComment += "\nhigh: "+ (string)high;
   //strComment += "\nlow: "+ (string)low;
   //strComment += "\nhigh: "+(string)rangeBorders(1);
   //strComment += "\nlow: "+(string)rangeBorders(-1);
   strComment += "\n"+(string)t1;
   strComment += "\n"+(string)(t1>tick.time);
   Comment(strComment);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double rangeBorders(double side) //, string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
{
   double border = 0;
   //MqlDateTime lastBar, currBar, nowTime;
   //TimeToStruct(TimeCurrent(), nowTime);
   
   datetime t1 = StringToTime(StringSubstr(TimeToString(iTime(0, _Symbol, _Period)),0,11)+hhmmss);
   datetime t2 = iTime(0, _Symbol, _Period);
   int      t1_shift    = iBarShift(_Symbol,_Period,t1);
   int      t2_shift    = iBarShift(_Symbol,_Period,t2);
   int      bar_count   = t1_shift-t2_shift;
   int      high_shift  = iHighest(_Symbol,_Period,MODE_HIGH,bar_count,t2_shift);
   int      low_shift   = iLowest(_Symbol,_Period,MODE_LOW,bar_count,t2_shift);
   double   high        = iHigh(_Symbol,_Period,high_shift);
   double   low         = iLow(_Symbol,_Period,low_shift);
   if(side == 1){return high;}
   else if (side == -1){return low;}
   else {return 0;}
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
