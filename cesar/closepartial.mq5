//+------------------------------------------------------------------+
//|                                                 partialclose.mq5 |
//|                                                           ceezer |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ceezer"
#property link      ""
#property version   "1.00"


#include<Trade\Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);

   if(time_0==PrevBars)
      return;
   PrevBars=time_0;


//--- price
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double pip = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

//--- Position
   if(PositionsTotal()<1) {
      trade.Buy(0.5, _Symbol, Ask, Ask-250*pip, 0.0, "INITIAL");
     }
   else if(PositionsTotal()>0) {
      //partialClose();
      
      checkforclose();
      
      checkPartClose();
     }
  }

//+------------------------------------------------------------------+
//| checking partial closing                                         |
//+------------------------------------------------------------------+
void checkPartClose() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket>0) {
         PositionSelectByTicket(ticket);
         double posSL = PositionGetDouble(POSITION_SL);
         double posPROPN = PositionGetDouble(POSITION_PRICE_OPEN);
         double posPRCUR = PositionGetDouble(POSITION_PRICE_CURRENT);
         double posVOLUME = PositionGetDouble(POSITION_VOLUME);

         double minVOLUME = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

         ENUM_POSITION_TYPE posType;
         posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(posSL>0.0) {
            Print("open - current: ",MathAbs(posPROPN-posPRCUR), " stoploss - current: ",MathAbs(posSL-posPROPN));
            //Print("ticket: ",ticket," pos type BUY: ",EnumToString(posType)," price: ",PositionGetDouble(POSITION_PRICE_CURRENT));
            if(MathAbs(posPROPN-posPRCUR) > MathAbs(posSL-posPROPN)) {
               Print("that should be goud ! ");
               double newVOL = floor(0.5*posVOLUME*100)/100;
               Print(newVOL);
               trade.PositionClosePartial(ticket, newVOL);
               Print("modify position");
               trade.PositionModify(ticket, 0.0, 0.0);
               // et là il faut que ça appelle une fonction qui construit un trailing stop sur le SAR
               // à partir du ticket pas de trailing stpo avec position modify, faire une cloture dynamique appelée dans OnTick())
               // quand même ajouter une clause stop loss != 0 pour exécuter le partial
               // pour ouverture position s'assurer que le volume est supériere à 2 fois la volume minimal
              }
           }
         else if(posType==POSITION_TYPE_SELL) {
            Print("ticket: ",ticket," pos type SELL: ",EnumToString(posType));
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| check for close                                        |
//+------------------------------------------------------------------+
void checkforclose() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket>0) {
         PositionSelectByTicket(ticket);
         if(PositionGetDouble(POSITION_SL)==0.0) {
            if(PositionGetDouble(POSITION_PROFIT)>0)
            {
               Print("Ca marche !");
               trade.PositionClose(ticket);
            }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT) {
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


























//   for(int i = PositionsTotal() - 1; i >= 0; i--) {
//      ulong ticket = PositionGetTicket(i);
//      if(ticket>0) {
//         PositionSelectByTicket(ticket);
//         ENUM_POSITION_TYPE posType = PositionGetInteger(POSITION_TYPE);
//         if(posType==POSITION_TYPE_BUY) {
//            nlongs ++;
//           }
//         else if(posType==POSITION_TYPE_SELL) {
//            nshorts++;
//           }
//        }
//     }
////+------------------------------------------------------------------+
//--- close 50% if profit > 50
//+------------------------------------------------------------------+
//void partialClose() {
//   for(int i=0; i<PositionsTotal(); i+=1) {
//      ulong ticket = PositionGetTicket(i);
//      if(PositionSelectByTicket(ticket)) {
//         double profit = PositionGetDouble(POSITION_PROFIT);
//         double volume = PositionGetDouble(POSITION_VOLUME);
//         if(profit > 50 && volume>0.25) {
//            trade.PositionClosePartial(ticket, 0.25);
//            Print("closed half, ticket: ", ticket);
//           }
//        }
//     }
//  }
//+------------------------------------------------------------------+
// voir les order history



//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
