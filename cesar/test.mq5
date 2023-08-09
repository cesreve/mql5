//+------------------------------------------------------------------+
//|                                                         test.mq5 |
//|                                                          cesreve |
//|                                                                  |
//+------------------------------------------------------------------+
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
   if(!IsNewbar()) {return;}
//---
   if(!SymbolInfoTick(_Symbol,cT)) {Print("Faield to get current symbol tick."); return;}   
//---
   trade.Buy(0.1, _Symbol, cT.ask, cT.ask - 200*_Point, cT.ask + 200*_Point, "BUY");
//---
   int cntBuy, cntSell;
   //Print(cntBuy);
   //Print(cntSell);
   CountOpenPositions(cntBuy,cntSell);
//---
   Comment((string)cT.ask, "\n", _Point, 
            "\nBuys  ", cntBuy,
            "\nSells     ", cntSell            
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