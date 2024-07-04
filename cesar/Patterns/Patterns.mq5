//+------------------------------------------------------------------+
//|                                                     Patterns.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"

//---
//+------------------------------------------------------------------+
enum PatternsList
{
   LOWERLOW = 1,
   HIGHERHIGH = 2,
   //REDNOTBREAKING = 3,
};
//+------------------------------------------------------------------+
input PatternsList pattern;
//+------------------------------------------------------------------+
string PatternChoice = "ugh";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (pattern==1) PatternChoice="LOWERCLOSE";
   if (pattern==2) PatternChoice="HIGHERHIGH";
   //if (pattern==CheckPattern(0)) PatternChoice="REDNOTBREAKING";
//---
   Print( "PatternChoice: ", PatternChoice, "\n"
         , "pattern: ", pattern, "\n"
         , "CheckPattern: ", CheckPattern(0));
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
   
  }
//+------------------------------------------------------------------+
bool LowerLow(int lag) {
   double low1 = iLow(_Symbol, _Period, lag);
   double low2 = iLow(_Symbol, _Period, lag+1);
   if ( low1 < low2 ) return true; 
   else return false;
}
//+------------------------------------------------------------------+
bool HigherHigh(int lag) {
   double high1 = iHigh(_Symbol, _Period, lag);
   double high2 = iHigh(_Symbol, _Period, lag+1);
   if ( high1 > high2 ) return true; 
   else return false;
}


//+------------------------------------------------------------------+

bool CheckPattern(int lag) {

   double open1 = iOpen(_Symbol, _Period, lag);
   double open2 = iOpen(_Symbol, _Period, lag+1);
   
   double high1 = iHigh(_Symbol, _Period, lag);
   double high2 = iHigh(_Symbol, _Period, lag+1);
   
   double close1 = iClose(_Symbol, _Period, lag);
   double close2 = iClose(_Symbol, _Period, lag+1);
   
   double low1 = iLow(_Symbol, _Period, lag);
   double low2 = iLow(_Symbol, _Period, lag+1);
   
   if ( PatternChoice=="LOWERCLOSE" ) return (low1<low2);
   if ( PatternChoice=="HIGHERHIGH" ) return (high1>high2);
   //if ( close1 < close2 ) return 1;
   //if ( close1 > close2 ) return 2; 
   //if ( (high1 > high2) ) return 3;
   
   else return false;
}