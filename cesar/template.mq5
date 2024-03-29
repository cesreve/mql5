//+------------------------------------------------------------------+
//|                                            reversal_BB_stoch.mq5 |
//|                                           Copyright 2021, ceezer |
//+------------------------------------------------------------------+
//#property copyright "Copyright 2021, ceezer"

// ctrl + ² pour commenter en bloc
// ctrl + $ pour décommenter

// - horaires corrects pour le DAX et le DJ
// - sur achat/vente sur oscillateur
// - sortie de la BB
// - entrer en position à la volée ou à la fin de la bougie
// - utiliser des ordres stops plutot que au marché ?
// - BE ou bien TP partiel sur la MM20 ?
// - moyennage à la baisse, conditions ?
// - règles TP 

// Récupération données (indicateurs, prix)


//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

string tradingHour = "NO";

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

   Comment(
   "\nTime is: ", iTime(1),
   "\nLow 1 is: ", iLow(1),
   "\nLow 0 is: ", iLow(0),
   "\nHigh 1 is: ", iHigh(1),
   "\nHigh 0 is: ", iHigh(0),
   "\nMilieu 0 is: ", getBollingerBands(0, 2),
   "\nHaut 0 is: ", getBollingerBands(1, 2),
   "\nBas 0 is: ", getBollingerBands(2, 2),
   "\nStoch 2 is: ", getStochastic(0, 2),
   "\nSENS: ", tradingConditions()
   );
   
   
   //--- we work only at the time of the birth of new bar
//   static datetime PrevBars=0;
//   datetime time_0=iTime(0);
//  
//   if(time_0==PrevBars)
//      return;
//   PrevBars=time_0;
   
      if(PositionsTotal() < 1) 
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double lowerBand1 = getBollingerBands(2, 1);
         double lowPrice1 = iLow(1);
         double stoch1 = getStochastic(0, 1);
         // Open BUY condition 
         if(lowPrice1 < lowerBand1 && stoch1 < 20)
         {
            
            // Open buy at ask
            if(trade.Buy(0.1, _Symbol, ask, 0.0, 0.0)) 
            {
               ulong resultTicket = trade.ResultOrder();
               
               // Check for opening
               if(resultTicket > 0)
               {               
                  Print("Buy completed: "+(string)resultTicket);              
               }                    
            }
         
         }
      }   
}
//+------------------------------------------------------------------+



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
  
//+------------------------------------------------------------------+ 
// Get BB indicator values 
// Ligne: 0-Middle, 1-Upper, 2-Lower
// Index: 0-Current                
//+------------------------------------------------------------------+ 
double getBollingerBands(int ligne, int index)
{

   double BBandBuffer[];   
   ArraySetAsSeries(BBandBuffer, true);   
   int BBs = iBands(_Symbol, _Period, 20, 0, 2, PRICE_CLOSE);

   if(CopyBuffer(BBs, ligne, index, 1,BBandBuffer)) {   
      if(ArraySize(BBandBuffer) > 0) {      
         return BBandBuffer[0];      
      }   
   }
   return -1.0;  
}
//+------------------------------------------------------------------+ 
// Get stochastic values     
// 0 - MAIN_LINE, 1 - SIGNAL_LINE.            
//+------------------------------------------------------------------+ 
double getStochastic(int ligne, int index)
{
   double StoBuffer[];   
   ArraySetAsSeries(StoBuffer, true);   
   int Stoch = iStochastic(_Symbol, _Period, 14, 3, 3,MODE_SMA, STO_CLOSECLOSE);

   if(CopyBuffer(Stoch, ligne, index, 1,StoBuffer)) {   
      if(ArraySize(StoBuffer) > 0) {      
         return StoBuffer[0];      
      }   
   }
   return -1.0;  
}
//+------------------------------------------------------------------+
//| Trading Condition                                                |
//+------------------------------------------------------------------+
string tradingConditions()
{
   string direction;
   //--- Sell
   if(getStochastic(0, 1) >= 80 && getStochastic(1, 1)>=80 && iHigh(1)>=getBollingerBands(1, 1))
   {
      direction = "SHORT"; 
   }
   //--- Buy
   else if(getStochastic(0, 1)<=20 && getStochastic(1, 1)<=20 && iLow(1)<=getBollingerBands(2, 1))
   {
      direction = "LONG";
   }
   else direction = "RIEN";
   
   return direction;
}