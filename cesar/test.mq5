//+------------------------------------------------------------------+
//|                                                         test.mq5 |
//|                                                          cesreve |
//|                                                                  |
//+------------------------------------------------------------------+

// trailing stop basé sur sar avec en input le nombre de pips pour qu'il se trigger
// calcul du profit latent en pips (pour par exemple trigger un trailing stop
// compter le nombre d'ordres ouverts
// fermer toutes les postitions
// high low entre 2 dates
// breakeven fonction
// fonction de timedelta %86400
// check if a limit order has been executed to cancel another for example
//test ajout commentaire







#property copyright "cesreve"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| ENUM Global variables                                            |
//+------------------------------------------------------------------+
enum x{
   A,      
   B,     
   C,   
   D,
   E,
   G
};
//---
input x lala = A;
CTrade trade;
MqlTick cT;
double nbLots = 0.1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("test");
   
//---
   int vecteur[3];
   vecteur[0]=2;
   vecteur[1]=0;
   vecteur[2]=3;
   func(vecteur);  
   //string x = "B;
   switch(lala)
     {
      case A:
         Print("CASE A");
         break;
      case B:
         break;
      case C:
         Print("CASE B ou C");
         break;
      default:
         Print("NI A, B ou C");
         break;
      case E:
         Print("euuuhh");
     }
//---
   return(INIT_SUCCEEDED);
  }

 
 //+------------------------------------------------------------------+
 //|                                                                  |
 //+------------------------------------------------------------------+
 //double countPositions()
  
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
   //if(!IsNewbar()) {return;}
//---
   if(!SymbolInfoTick(_Symbol,cT)) {Print("Faield to get current symbol tick."); return;}   
//---

   int cntBuy, cntSell;
   CountOpenPositions(cntBuy,cntSell);
   
   //if(cntBuy==0) {trade.Buy(0.1, _Symbol, cT.ask, cT.ask - 1500*_Point, cT.ask + 1500*_Point, "BUY");}
   if(cntBuy==0) {trade.Buy(0.1, _Symbol, cT.ask, cT.ask - 1500*_Point, 0, "BUY");}
   if(cntBuy > 0 && currentProfit()/_Point > 25) {Print("euh"); trailingStop();}
   //if(cntSell==0) {trade.Sell(0.1, _Symbol, cT.bid, cT.bid + 150*_Point, cT.bid - 150*_Point, "SELL");}
   //long sprd = SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
   //Print(sprd);
//---
   Comment((string)cT.ask
            ,"\nBuys  ", cntBuy
            ,"\nSells     ", cntSell
            ,"\nPoint ", _Point
            ,"\nDigits ", _Digits
            ,"\nBid ", cT.bid
            ,"\nAsk ", cT.ask
            ,"\nBLast ", cT.last
            //,"\nCurrent profit: ",currentProfit()/_Point
            ,"\nCurrent profit: ",NormalizeDouble(currentProfit()/_Point,2)
            );
  } // end of the OnTick function
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CountOpenPositions(int &cntBuy, int &cntSell)
{
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}
      //long magic;
      //if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to get position magic number"); return false;}
      //if(magic==InpMagicNumber)
      {
         long type;
         if(!PositionGetInteger(POSITION_TYPE, type)) {Print("Failed to get postion type"); return false;}
         if(type==POSITION_TYPE_BUY) {cntBuy++;}
         if(type==POSITION_TYPE_SELL) {cntSell++;}
      }
   }
   
   return true;
}
//+------------------------------------------------------------------+
//|               Custom function                                    |
//+------------------------------------------------------------------+
//---
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool trailingStop() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}

      double positionStopLoss = PositionGetDouble(POSITION_SL);
      double positionTakeProfit = PositionGetDouble(POSITION_TP);
      double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double positionCurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      Print(MathAbs(positionOpenPrice - positionCurrentPrice)/_Point);
      //if(MathAbs(positionOpenPrice - positionCurrentPrice)/_Point>pipsNumber)
      //{
         Print("GOOOOO !! sl: ",positionStopLoss," tp: ",positionTakeProfit);
         if(trade.PositionModify(ticket,positionOpenPrice,0)) {return true;}
         
         
      //}
  }
  return false;
} 
//+------------------------------------------------------------------+
//| current profit                                       |
//+------------------------------------------------------------------+
double currentProfit() {
   double profit = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket>0) {
         PositionSelectByTicket(ticket);
         long type;
         PositionGetInteger(POSITION_TYPE, type);
         if(PositionGetSymbol(i) == _Symbol) {
            double posPROPN = PositionGetDouble(POSITION_PRICE_OPEN);
            double posPRCUR = PositionGetDouble(POSITION_PRICE_CURRENT);
            if(type == POSITION_TYPE_BUY) {profit = cT.bid - posPROPN; return cT.bid - posPROPN;}
            //if(type == POSITION_TYPE_SELL) {profit = posPROPN- cT.ask; return NormalizeDouble(posPROPN- cT.ask,2);}
            //if(posPRCUR - posPROPN > 0) {profit = cT.bid - posPROPN;}
            //else if (posPRCUR - posPROPN < 0) {profit = cT.ask - posPROPN;}
            
            }
         }      
      }
   return profit;      
}  
//+------------------------------------------------------------------+
//--- Somme de tous les éléments différents de zéro
int func(int &array[])
  {
   Print("func startin' ");
   int array_size=ArraySize(array);
   int sum=0;
   for(int i=0;i<array_size; i++)
     {
      if(array[i]==0) {Print(i, " = 0");}
      if(array[i]==0) continue;
      //if(array[i]==0) break;
      sum+=array[i];
     }
   Print(sum);  
   return(sum);
  }
//---
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

//+------------------------------------------------------------------+
bool NormalizePrice(double &price)
{
   double tickSize=0;
   
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {Print("Failed to get tick size"); return false;}
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
   
   return true;
}