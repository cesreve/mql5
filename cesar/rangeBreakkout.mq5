//+------------------------------------------------------------------+
//|                                               rangeBreakkout.mq5 |
//|                                                          cesreve |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "cesreve"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| Global variables                                                                  |
//+------------------------------------------------------------------+
struct RANGE_STRUCT
  {
   datetime          startTime; // start of the range
   datetime          endTime; //end of the range
   double            rangeHigh; //high of the range
   double            rangeLow; // low of the range
   bool              isInside; // flag if we are inside of the range
   
   RANGE_STRUCT() : startTime(0), endTime(0), rangeHigh(0), rangeLow(10000000), isInside(false) {};
  };

RANGE_STRUCT range;

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
//---
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

//---
   string strComment;
   strComment = "hour: " + (string)now.hour + " minute: " + (string)now.min;
   strComment += "\nhigh: " + (string)range.rangeHigh;
   strComment += "\nlow: " + (string)range.rangeLow;
   //strComment += "\namplitude: " + (string)(rangeHigh- rangeLow);
   //strComment += "\ntime : " + (string)(lastTick.time%86400);
   //strComment += "\nsignal : " + sign;
   Comment(strComment);
   
  }
//+------------------------------------------------------------------+
