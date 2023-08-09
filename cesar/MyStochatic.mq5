//+------------------------------------------------------------------+
//|                                                  MyStochatic.mq5 |
//|                                                          cesreve |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "cesreve"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;
int handleStochastic;
int handleMA;
MqlTick tick;


enum ENTRY_MODE{  
   ENTRY_CROSS_NORMAL,     // entry cross normal   
   ENTRY_CROSS_REVERSED    // entry cross reversed
};

enum EXIT_MODE{
    EXIT_CROSS_NORMAL,      // exit cross normal
    EXIT_CROSS_REVERSED,    // exit cross reversed
};


//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ====";
static input long InpMagicNumber = 1; 

input group "====  Stochastic ====";
input int InpStochKPeriod = 50;
input int InpStochDPeriod = 5;
input int InpStochSlowing = 10;
input int InpUpperLevel = 80;
//input int InpLowerLevel = 20;

input group "==== Trading ====";
input ENTRY_MODE InpEntryMode = ENTRY_CROSS_NORMAL;  // signal mode 
input ENTRY_MODE InpExitMode = ENTRY_CROSS_NORMAL;
input bool InpReversedSignal = true;

input double InpLotSize = 0.1;
input int InpStopLoss = 0;
input int InpTakeProfit = 0;




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);   

//--- create stochastic hanlde
   handleStochastic = iStochastic(_Symbol,_Period,InpStochKPeriod,InpStochDPeriod,InpStochSlowing,MODE_SMA,STO_LOWHIGH);
   if(handleStochastic==INVALID_HANDLE)
     {
      Alert("Failed to create stochastic handle");
      return INIT_FAILED;
     }
     
//--- create moving average hanlde
   handleMA = iMA(_Symbol,_Period,20,0,MODE_SMA,PRICE_TYPICAL);
   if(handleMA==INVALID_HANDLE)
     {
      Alert("Failed to create moving average handle");
      return INIT_FAILED;
     }
     
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
//--- If Not a new bar, do not go further
   if(!IsNewbar()) {return;}

//--- get current tick
   if(!SymbolInfoTick(_Symbol,tick)) {Print("Faield to get current symbol tick."); return;}

//--- count  open positions
   int cntBuy = 0, cntSell = 0;
   if(!CountOpenPositions(cntBuy,cntSell)) {Print("Failed to count open positions."); return;}

//--- check for close
   if(InpReversedSignal) //--- close function uniquement si ReversedSignal est vrai, il faut utiliser stop loss
   {    
      if(cntBuy>0 && CheckSignal(-1)) {Print("Close long trade"); ClosePosition(1);} 
      if(cntSell>0 && CheckSignal(1)) {Print("Close short trade");ClosePosition(-1);}      
   }


//--- check for buy position
   if(CheckSignal(1.0) && cntBuy<1)
   {
      Print("Open buy position");
      //if(InpCloseSignal) {if(!ClosePositions(2)){return;}}
      double sl = InpStopLoss==0 ? 0 : tick.bid - InpStopLoss*_Point;
      double tp = InpTakeProfit==0 ? 0 : tick.bid + InpTakeProfit*_Point;
      if(!NormalizePrice(sl)) {return;}
      if(!NormalizePrice(tp)) {return;}
      trade.Buy(InpLotSize,_Symbol,tick.ask,sl,tp,"Stochastic EA");
      //trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotSize,cT.ask,sl,tp,"Stochastic EA");
   }   
////--- check for sell position
   if(CheckSignal(-1.0) && cntSell<1)
   {
      Print("Open sell position");
//      if(InpCloseSignal) {if(!ClosePositions(1)){return;}}
      double sl = InpStopLoss==0 ? 0: tick.ask + InpStopLoss*_Point;
      double tp = InpTakeProfit==0 ? 0 : tick.ask - InpTakeProfit*_Point;
      if(!NormalizePrice(sl)) {return;}
      if(!NormalizePrice(tp)) {return;}
      trade.Sell(InpLotSize,_Symbol,tick.bid,sl,tp,"Stochastic EA");
//      //trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotSize,cT.bid,sl,tp,"Stochastic EA");
   }  


//--- Comments
   //Comment("ticksize: ",ticksize, "\npoints: ", _Point, "\nDigits: ", _Digits);
   Comment("\nSignal long: ",(CheckSignal(1)),
            "\nSignal short: ",(CheckSignal(-1)));
      
  } // end of the OnTick() function

//---

  
//+------------------------------------------------------------------+
//|                  Custom functions                                +
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//- direction: 1 for a long, -1 for a short  ----------------------+ 
bool CheckSignal(double direction)
{   
   int lowerLevel = 100 - InpUpperLevel;
   //---  crossovers   
   bool crossInUpper  = getSTOCHASTIC(2, 0) < InpUpperLevel && getSTOCHASTIC(1, 0) > InpUpperLevel;
   bool crossOutUpper = getSTOCHASTIC(2, 0) > InpUpperLevel && getSTOCHASTIC(1, 0) < InpUpperLevel;   
   bool crossInLower  = getSTOCHASTIC(2, 0) > lowerLevel && getSTOCHASTIC(1, 0) < lowerLevel;
   bool crossOutLower = getSTOCHASTIC(2, 0) < lowerLevel && getSTOCHASTIC(1, 0) > lowerLevel;
   
   //---  signal
   switch(InpEntryMode)
   {  
      case ENTRY_CROSS_NORMAL: return ((direction==-1.0 && crossInUpper) || (direction==1.0 && crossInLower));
      case ENTRY_CROSS_REVERSED: return ((direction==-1.0 && crossOutUpper) || (direction==1.0 && crossOutLower));    
   } 
   return false;
}
//+------------------------------------------------------------------+
//- Close position -1.0 for a sell order, 1.0 for a buy order   -----+ 
bool ClosePosition(double direction)
{  
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to get position magic number"); return false;}
      if(magic==InpMagicNumber)
      {
         long type;
         if(!PositionGetInteger(POSITION_TYPE, type)) {Print("Failed to get postion type"); return false;}                  
         if(direction==-1 && type==POSITION_TYPE_BUY) {continue;}
         if(direction==1 && type==POSITION_TYPE_SELL) {continue;}
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
//+------------------------------------------------------------------+
//- Count positions  ------------------------------------------------+
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
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to get position magic number"); return false;}
      if(magic==InpMagicNumber)
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
//- New Bar  --------------------------------------------------------+
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
//- NormalizePrice   ------------------------------------------------+
bool NormalizePrice(double &price)
{
   double tickSize=0;
   
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {Print("Failed to get tick size"); return false;}
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
   
   return true;
}   
//+------------------------------------------------------------------+
//- Stochastic indicator = 0: Signal = 1   --------------------------+
double getSTOCHASTIC(int index, int line)
{
   double stochasticBuffer[];
   ArraySetAsSeries(stochasticBuffer, true);
   if(CopyBuffer(handleStochastic,line,index,1,stochasticBuffer)!=1) { Print("Failed to get iStochastic values."); return -1.0;}
   else return stochasticBuffer[0];
   
}

//+----------------------   T H E    E N D   ------------------------+