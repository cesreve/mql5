//+------------------------------------------------------------------+
//|                                                         test.mq5 |
//|                                                          cesreve |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "cesreve"
#property link      ""
#property version   "1.00"


//+------------------------------------------------------------------+
//| ENUM Global variables                                            |
//+------------------------------------------------------------------+
enum x{
   A,      
   B,     
   C,   
   D    
};
//---
input x lala = A;


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
     }
//---
   return(INIT_SUCCEEDED);
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

  }
//+------------------------------------------------------------------+
