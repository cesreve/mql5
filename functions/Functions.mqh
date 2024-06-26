//+------------------------------------------------------------------+
//|                                                    functions.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""


void test() { Print("test function from include file"); }


//----- liste des functions que je veux mettre dans ma libraire
// compter les trades ouverts
//int CountOpenPositions(ENUM_POSITION_TYPE positionType, int InpMagicNumber)
//{
//   int cnt = 0;
//   //cntSell = 0;
//   int total = PositionsTotal();
//   for(int i=total-1; i>=0; i--)
//   {
//      ulong ticket = PositionGetTicket(i);
//      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
//      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}
//      long magic;
//      if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to get position magic number"); return false;}
//      if(magic==InpMagicNumber)
//      {
//         long type;
//         if(!PositionGetInteger(POSITION_TYPE, type)) {Print("Failed to get postion type"); return false;}
//         if(positionType==POSITION_TYPE_BUY) {cnt++;}
//         //if(positionType==POSITION_TYPE_SELL) {cntSell++;}
//      }
//   }   
//   return cnt;
//}

// compter les trades ouverts 2
void CountOpenPositions(const string symbol, int &count[])
{
   
   ArrayResize( count, 2 );
   ArrayInitialize( count, 0 );
   
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         long magic;
         if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to get position magic number"); return;}
         if(magic==InpMagicNumber)
            if( PositionGetString(POSITION_SYMBOL)==symbol ) {
               count[(int)PositionGetInteger(POSITION_TYPE)]++;
         }
      }
   }
   return;
}   

// fermer les trades


// placer les horaires


//// nouvelle bougie
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
//
//// nouvelle journée
//+------------------------------------------------------------------+
//- New Day  --------------------------------------------------------+
bool IsNewDay()
  {
   static datetime previousDay = 0;
   datetime currentDay = StringToTime(StringSubstr(TimeToString(iTime(Symbol(),PERIOD_M1,0)),0,11));
   if(previousDay!=currentDay) {
      previousDay=currentDay;
      return true;
     }
   return false;  
  }  
//
//// fermer toutes les positions
bool closePositions()
{
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);  Print("ticket: ", ticket);
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) {
         Print("Failed to get position magic number");
         Print("magic: ", magic, "magic number: ", InpMagicNumber);
         return false;}
      if(magic==InpMagicNumber)
      {
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
//
//// calculates datetimes
//void calculateDatetimes(int InpStartHour, int InpStartMinute)
//{
//   //--- convert to times   
//   MqlDateTime nowStruct;
//   datetime now = TimeCurrent();
//   TimeToStruct(now, nowStruct);   
//   nowStruct.sec = 0;
//   
//   // start time
//   nowStruct.hour = InpStartHour;
//   nowStruct.min = InpStartMinute;
//   startTime = StructToTime(nowStruct);
   
   // stop time
//   nowStruct.hour = InpStopHour;
//   nowStruct.min = InpStopMinute;
//   stopTime = StructToTime(nowStruct);
//   
//   // close time
//   nowStruct.hour = InpCloseHour;
//   nowStruct.min = InpCloseMinute;
//   closeTime = StructToTime(nowStruct);
//}

// setOrders
//void setOrder(ENUM_ORDER_TYPE type, double price) {
//   if(!setOrder(type, price, TakeProfit1)) return;
//   if(!setOrder(type, price, TakeProfit2)) return;
//   if(!setOrder(type, price, TakeProfit3)) return;
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
