datetime startTime=0;
datetime closeTime=0;

void calculateDatetimes(int startH, int startM)
{
   calculateDatetimes(startH, startM, 0, 0);
}

void calculateDatetimes(int startH, int startM, int closeH, int closeM) {
   //--- convert to times   
   MqlDateTime nowStruct;
   datetime now = TimeCurrent();
   TimeToStruct(now, nowStruct);   
   nowStruct.sec = 0;
   
   // start time
   nowStruct.hour = InpStartHour;
   nowStruct.min = InpStartMinute;
   startTime = StructToTime(nowStruct);
   
   // close time
   nowStruct.hour = InpCloseHour;
   nowStruct.min = InpCloseMinute;
   closeTime = StructToTime(nowStruct);
   
   //--- print times
   //Print("startTime ",startTime);
   //Print("closeTime ",closeTime);
}


//calculateDatetimes(12, 30);

//
//
//void setOrder(ENUM_ORDER_TYPE type, double price) {
//
//   if(!setOrder(type, price, TakeProfit1)) return;
//   //if(!setOrder(type, price, TakeProfit2)) return;
//   //if(!setOrder(type, price, TakeProfit3)) return;
//}
//bool setOrder(ENUM_ORDER_TYPE type, double price, double takeProfit) {
//
//   double tp = 0;      
//   if(type==ORDER_TYPE_BUY_STOP) {
//      tp = takeProfit > 0 ? price + takeProfit : 0;
//   } else {
//      tp = takeProfit > 0 ? price - takeProfit : 0;
//   }
//   
//   double sl = 0;   
//   if(type==ORDER_TYPE_BUY_STOP) {
//      sl = rangeLow+InpDistanceOrdre;
//   } else {
//      sl = rangeHigh-InpDistanceOrdre;
//   }  
//   
//   if(!trade.OrderOpen(Symbol(), type, vol, price, price, sl, tp, ORDER_TIME_SPECIFIED,stopTime, InpTradeComment)) {
//      PrintFormat("Error opening position, typ=%s, volume=%f, price=%f, sl=%f, tp=%f", 
//                  EnumToString(type), vol, price, sl, tp);
//      return false;          
//   }
//   return true;
//}