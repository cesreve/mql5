//+------------------------------------------------------------------+
//|                                                 session info.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
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


////---
//   MqlDateTime nowStruct;
//   datetime now = TimeCurrent();
//   datetime timespec;
//   TimeToStruct(now, nowStruct);   
//   nowStruct.sec = 0;
//   
//   // start time
//   nowStruct.hour = 23;
//   nowStruct.min = 30;
//   timespec = StructToTime(nowStruct);
//   
//   datetime timespec2  = timespec + 60;
   
   
   


//---
   MqlDateTime timeStruct;
   datetime now = TimeCurrent();
   datetime fromTime;
   datetime toTime;
   TimeToStruct(now, timeStruct);
//---
   //SymbolInfoSessionTrade(Symbol(), (ENUM_DAY_OF_WEEK)timeStruct.day_of_week, 0, fromTime, toTime);

   //fromTime = now +3600;
   //toTime = now +3601;
   SymbolInfoSessionQuote(Symbol(), (ENUM_DAY_OF_WEEK)timeStruct.day_of_week, 1, fromTime, toTime);
   //if(!res) {Print("sss"); }
//---
   string comm = "";
   comm += "\n";
   comm += (string)(fromTime);
   comm += "\n";
   comm += (string)(toTime);
   comm += "\n";
   //comm += (string)(now);
   comm += "\n";
   Comment(comm);
   
  }
//+------------------------------------------------------------------+
