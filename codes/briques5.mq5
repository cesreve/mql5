//+------------------------------------------------------------------+
//|                                                      briques.mq5 |
//+------------------------------------------------------------------+
// - horaires corrects pour le DAX:
//    - 12h fermer tous les ordres
//    - 14H fermer toutes les positions
// - stopper les trades quand objectif atteint
// - mettre un TP à 25 pts
// - mettre un magic number
// - BE à 15pts
// - BE si ouvert depuis "trop longtemps"
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

string tradingHour = "NO";

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   
   double Balance          = AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity           = AccountInfoDouble(ACCOUNT_EQUITY); 
   datetime today          = StringToTime((string)now.year +"."+ (string)now.mon+"." + (string)now.day +" [00:00:00]");
  
   Comment(//"OrdersTotal: ", OrdersTotal(),
           //"\nPositionsTotal: ", PositionsTotal(),
           "\nNbSell Stop: ", NumberOfPendingOrders("SELL_STOP"),
           "\nPositionsShort: ", NumberOfPositions("SHORT"),
           //"\nIs Trading (8-17): ", tradingHour,
           "\nTime is: ", iTime(1),
           "\nEquity: ",Equity, 
           "\nBalance: ", Balance,
           "\ntoday: ", today,
           "\nDaily Profit: ", GetDailyProfit(today),
           "\nCurrentProfit: ", GetCurrentProfit());   
                      
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
  
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   
//--- update if trading hour
   IsTradingHour();
   
   
      

//--- set pending orders

   if(now.hour > 8 && now.hour < 13 && CandleSignalSS()>0 && PositionAllowedSS())
   {
      if(trade.SellStop(1, iLow(1)-1, _Symbol, 0, iLow(1)-1-25)) 
      {               
         ulong ticket = trade.ResultOrder();
                  
         // Check if it worked
         if(ticket > 0)
            {
               Print("Ordre placé SS à: ", iLow(1), " Ticket: ", ticket);
            }               
      }   
      
   }
   
   if(now.hour > 8 && now.hour < 13 && CandleSignalBS()>0 && PositionAllowedBS())
   {
      if(trade.BuyStop(1, iHigh(1)+1, _Symbol, 0, iHigh(1)+1)) 
      {               
         ulong ticket = trade.ResultOrder();
                  
         // Check if it worked
         if(ticket > 0)
            {
               Print("Ordre BS placé à: ", iHigh(1) , " Ticket: ", ticket);
            }               
      }   
      
   }
   
//--- modify pending order
   ModifyPendingOrdersSS();
   ModifyPendingOrdersBS();

//--- try to close
   if(PositionsTotal()>0)
   {
      PositionClosing();
   }
   
//--- if hour > 16 close all
   if(now.hour > 12 || GetCurrentProfit()+GetDailyProfit(today) > 50)
   {
      CancelPendingOrders();
      CloseOpennedPosition();
   }
   
} // end of the OnItck() function

//+------------------------------------------------------------------+
int CandleSignalSS()
{
   int signal = 0;   
   for(int i= 2; i<4; i++) {
      if(iHigh(1)>iHigh(i) && iLow(1)>iLow(i))
         {
         signal = 1;
         break;
         }  
      else 
      {
      signal = 0;
      }      
   }
   return(signal);   
} 
//+------------------------------------------------------------------+
int CandleSignalBS()
{
   int signal = 0;   
   for(int i= 2; i<4; i++) {
      if(iHigh(1)<iHigh(i) && iLow(1)<iLow(i))
         {
         signal = 1;
         break;
         }  
      else 
      {
      signal = 0;
      }      
   }
   return(signal);   
} 
//+------------------------------------------------------------------+
string IsTradingHour()
{
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   
   if(now.hour > 8 && now.hour <17)
      {
         tradingHour = "YES";
      }
   else
      {
         tradingHour = "NO";
      }
   return(tradingHour);   
}  
   
//+------------------------------------------------------------------+
// Position allowed
bool PositionAllowedSS()
{
   bool PosAllowed = false;
   int NbShorts = 0;
   // si pas de positions courte et cours et pas d'ordre SELL_STOP en cours
   if(NumberOfPositions("SHORT")<1 && NumberOfPendingOrders("SELL_STOP")<1) 
   {
      PosAllowed = true;
   }
   // SI position courte ouverte et pas d'ordre en SS en attente
   else if(NumberOfPositions("SHORT")<2 && NumberOfPendingOrders("SELL_STOP")<1)
   {
      for(int i=PositionsTotal(); i>=0; i--)
      {
         ulong ticket = PositionGetTicket(i);   
         if(PositionSelectByTicket(ticket)) 
         {   
            double OpenPrice = PositionGetDouble(POSITION_PRICE_OPEN); 
            double CurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            long PositionType = PositionGetInteger(POSITION_TYPE);
            
            if(PositionType==POSITION_TYPE_SELL)
            {
               NbShorts ++;
               //Print("nb longs: ", NbLongs);
               if(NbShorts<2 && MathAbs(OpenPrice-CurrentPrice) > 60)
               {
                  Print("ready to set a new pending order "+(string)OpenPrice+"   "+(string)CurrentPrice);
                  PosAllowed = true;
               }
               
            }         
         }
      }
   }   
   return(PosAllowed);  
}
//+------------------------------------------------------------------+
// Position allowed SB
bool PositionAllowedBS()
{
   bool PosAllowed = false;
   int NbLong = 0;
   // si pas de positions courte et cours et pas d'ordre SELL_STOP en cours
   if(NumberOfPositions("LONG")<1 && NumberOfPendingOrders("BUY_STOP")<1) 
   {
      PosAllowed = true;
   }
   // SI position courte ouverte et pas d'ordre en SS en attente
   else if(NumberOfPositions("LONG")<2 && NumberOfPendingOrders("BUY_STOP")<1)
   {
      for(int i=PositionsTotal(); i>=0; i--)
      {
         ulong ticket = PositionGetTicket(i);   
         if(PositionSelectByTicket(ticket)) 
         {   
            double OpenPrice = PositionGetDouble(POSITION_PRICE_OPEN); 
            double CurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            long PositionType = PositionGetInteger(POSITION_TYPE);
            
            if(PositionType==POSITION_TYPE_BUY)
            {
               NbLong ++;
               //Print("nb longs: ", NbLongs);
               if(NbLong<2 && MathAbs(OpenPrice-CurrentPrice) > 60)
               {
                  Print("ready to set a new pending order "+(string)OpenPrice+"   "+(string)CurrentPrice);
                  PosAllowed = true;
               }
               
            }         
         }
      }
   }   
   return(PosAllowed);  
}
//+------------------------------------------------------------------+
// Position closing
void PositionClosing() 
{
   for(int i=PositionsTotal(); i>=0; i--)
   {
      // get the position with ticket
      ulong ticket = PositionGetTicket(i);   
      if(PositionSelectByTicket(ticket)) 
      {
         if(PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) > 0)
         {
            double Profit = PositionGetDouble(POSITION_PROFIT);
            trade.PositionClose(ticket);
            Print("Position closed: ",trade.ResultRetcode()," with profit: ", Profit);
         }
      }
   }         
}   
//+------------------------------------------------------------------+
// Cancel orders
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
// Close Position
void CloseOpennedPosition()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      
      if(PositionSelectByTicket(ticket))
      {   
         Print("Poistion closed with profit of: ",PositionGetDouble(POSITION_PROFIT));
         trade.PositionClose(ticket);
         Print("Position closed: ",trade.ResultRetcode());
      }   
   }
}

//+------------------------------------------------------------------+
// Get Total Profit for the day
double GetDailyProfit(datetime jour)
{
   uint        TotalNumberOfDeals=HistoryDealsTotal();
   ulong       TicketNumber = 0;
   long        OrderType, DealEntry;
   double      OrderProfit=0;
   double      TotalProfit=0;
   string      MySymbol="";
   string      PositionDirection="";
   string      MyResult="";   

   
   // get the history
   HistorySelect(jour, TimeCurrent());
   for(uint i=0;i<TotalNumberOfDeals;i++)
   {
      if((TicketNumber=HistoryDealGetTicket(i))>0)
      {
         OrderProfit=HistoryDealGetDouble(TicketNumber, DEAL_PROFIT);
         OrderType=HistoryDealGetInteger(TicketNumber, DEAL_TYPE);
         MySymbol=HistoryDealGetString(TicketNumber, DEAL_SYMBOL);
         DealEntry=HistoryDealGetInteger(TicketNumber, DEAL_ENTRY);
                  
         if(MySymbol==_Symbol)
         {

            if(OrderType==ORDER_TYPE_BUY || OrderType==ORDER_TYPE_SELL)
            {
               // if the order was closed (DealEntry=1)
               if(DealEntry==1)
               {                
                  TotalProfit += OrderProfit;   
               }
            }
         }
         
      }
   }
   return(TotalProfit);   
}

//+------------------------------------------------------------------+ 
// Get current profit
double GetCurrentProfit()
{
   double profit = 0;
   
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);   
      if(PositionSelectByTicket(ticket))
      {   
         profit += PositionGetDouble(POSITION_PROFIT);       
      }   
   } 
   return(profit);
}


// modify pending order
void ModifyPendingOrdersSS()
{
   if(CandleSignalSS()>0 && NumberOfPendingOrders("SELL_STOP")>0)
   {
      for(int i=OrdersTotal()-1; i>=0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         long OrderType=OrderGetInteger(ORDER_TYPE);
         if(OrderSelect(ticket) && OrderType==ORDER_TYPE_SELL_STOP) 
         {
            if(trade.OrderModify(ticket, iLow(1), 0, 0, ORDER_TIME_DAY, 0))
            {
               //Print("pending order modified");
            }
         } 
      }
   }
}
//+------------------------------------------------------------------+ 
// modify pending order
void ModifyPendingOrdersBS()
{
   if(CandleSignalBS()>0 && NumberOfPendingOrders("BUY_STOP")>0)
   {
      for(int i=OrdersTotal()-1; i>=0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         long OrderType=OrderGetInteger(ORDER_TYPE);
         if(OrderSelect(ticket) && OrderType==ORDER_TYPE_BUY_STOP) 
         {
            if(trade.OrderModify(ticket, iHigh(1), 0, 0, ORDER_TIME_DAY, 0))
            {
               //Print("pending order modified");
            }
         } 
      }
   }
}

//+------------------------------------------------------------------+ 
// Compute number of pending orders given the direction (SELL_STOP or BUY_STOP)
int NumberOfPendingOrders(string sens)
{
   int NbSellStop = 0;
   int NbBuyStop = 0;
   int result = 0;
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      long OrderType=OrderGetInteger(ORDER_TYPE);
      if(OrderType==ORDER_TYPE_BUY_STOP)
      {
          NbBuyStop ++;
      }
      else if(OrderType==ORDER_TYPE_SELL_STOP)
      {
         NbSellStop ++;
      }   
   }
   if(sens == "SELL_STOP")
   {
      result = NbSellStop;
   }
   else if(sens =="BUY_STOP")
   {
      result = NbBuyStop;
   } 
   return(result);
}
//+------------------------------------------------------------------+ 
// Compute number of running trades given the direction (LONG or SHORT)
int NumberOfPositions(string sens)
{
   int nlongs = 0;
   int nshorts = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) 
   {
         ulong ticket = PositionGetTicket(i);
         if(ticket>0){
             PositionSelectByTicket(ticket);
             ENUM_POSITION_TYPE posType = PositionGetInteger(POSITION_TYPE);
             if(posType==POSITION_TYPE_BUY)
             {
                nlongs ++;
             }
             else if(posType==POSITION_TYPE_SELL)
             {
               nshorts++;
             }
         }
   }  
   
   if(sens == "LONG")
   {
      return(nlongs);
   }
   else if(sens == "SHORT")
   {
      return(nshorts);
   }
   else
      return -1;
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
   if(copied>0) time=Time[0];
   return(time);
  }

//+------------------------------------------------------------------+ 
//| Get High for specified bar index                                 | 
//+------------------------------------------------------------------+ 
double iHigh(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double High[1];
   double high=0;
   int copied=CopyHigh(symbol,timeframe,index,1,High);
   if(copied>0) high=High[0];
   return(high);
  }
  
//+------------------------------------------------------------------+ 
//| Get Low for specified bar index                                  | 
//+------------------------------------------------------------------+ 
double iLow(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double Low[1];
   double low=0;
   int copied=CopyLow(symbol,timeframe,index,1,Low);
   if(copied>0) low=Low[0];
   return(low);
  }