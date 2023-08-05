//+------------------------------------------------------------------+
//|                                                        notif.mq5 |
//|                                                          cesreve |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "cesreve"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
//---

   sendNotification(_Symbol);
   Comment(bid);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Send notification                                                |
//+------------------------------------------------------------------+
void sendNotification(string symbol)
  {
//string content = "test";
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   string content = StringFormat("Hello, my name is %s. and the bid is %f.", symbol, bid);
   if(SendNotification(content))
     {
      Print("Notification Send ", content);
     }
   else
      if(!SendNotification(content))
        {
         Print("fail");
         Print(GetLastError());
        }

  }
//+------------------------------------------------------------------+
