//+------------------------------------------------------------------+
//|                                                   Stochastic.mq5 |
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
enum SIGNAL_MODE{
   EXIT_CROSS_NORMAL,      // exit cross normal
   ENTRY_CROSS_NORMAL,     // entry cross normal
   EXIT_CROSS_REVERSED,    // exit cross reversed
   ENTRY_CROSS_REVERSED    // entry cross reversed
};

int handle;
double bufferMain[];
MqlTick cT;
CTrade trade;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ====";
static input long InpMagicNumber = 1;                 //magicnumber
static input double InpLotSize = 0.1;                 //lotsize

input group "==== Trading ====";
input SIGNAL_MODE InpSignalMode = EXIT_CROSS_NORMAL;  // signal mode 
input int InpStopLoss = 200;                          // stop loss in points (0=off)
input int InpTakeProfit = 0;                          // take profit in points (0=off)
input bool InpCloseSignal = false;                    // close trades by opposite direction

input group "==== Stochastic ====";
input int InpKPeriod = 21;                            // K period
input int InpUpperLevel = 80;                         // upper level

input group "==== Clear bars filter ====";
input bool InpClearBarsReversed = false;              // reverse clear bar filter
input int InpClearBars = 0;                           // clear bars (0=off)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |  
//+------------------------------------------------------------------+
int OnInit()
  {
//--- ckeck user inputs
   if(!CheckInputs())
     {
      return INIT_PARAMETERS_INCORRECT;
     }

//---
   trade.SetExpertMagicNumber(InpMagicNumber);

//--- create indicator hanlde
   handle = iStochastic(_Symbol,_Period,InpKPeriod,1,3,MODE_SMA,STO_LOWHIGH);
   if(handle==INVALID_HANDLE)
     {
      Alert("Failed to create indicator handle");
      return INIT_FAILED;
     }

//--- set buffer as series
   ArraySetAsSeries(bufferMain, true);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- realese indicator handle
   if(handle!=INVALID_HANDLE)
     {
      IndicatorRelease(handle);
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for bar open tick
   if(!IsNewbar()) {return;}
//--- get current tick
   if(!SymbolInfoTick(_Symbol,cT)) {Print("Faield to get current symbol tick."); return;}
   
//--- get indicator values
   if(CopyBuffer(handle,0,0,3+InpClearBars,bufferMain)!=3+InpClearBars) { Print("Failed to get indicator values."); return;}
   
//--- count  open positions
   int cntBuy, cntSell;
   if(!CountOpenPositions(cntBuy,cntSell)) {Print("Failed to count open positions."); return;}
   
//--- check for buy position
   if(CheckSignal(true, cntBuy) && CheckClearBars(true))
   {
      Print("Open buy position");
      if(InpCloseSignal) {if(!ClosePositions(2)){return;}}
      double sl = InpStopLoss==0 ? 0: cT.bid - InpStopLoss*_Point;
      double tp = InpTakeProfit==0 ? 0 : cT.bid + InpTakeProfit*_Point;
      if(!NormalizePrice(sl)) {return;}
      if(!NormalizePrice(tp)) {return;}
      trade.Buy(InpLotSize,_Symbol,cT.ask,sl,tp,"Stochastic EA");
      //trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotSize,cT.ask,sl,tp,"Stochastic EA");
   }   
//--- check for sell position
   if(CheckSignal(false, cntSell) && CheckClearBars(false))
   {
      Print("Open sell position");
      if(InpCloseSignal) {if(!ClosePositions(1)){return;}}
      double sl = InpStopLoss==0 ? 0: cT.ask + InpStopLoss*_Point;
      double tp = InpTakeProfit==0 ? 0 : cT.ask - InpTakeProfit*_Point;
      if(!NormalizePrice(sl)) {return;}
      if(!NormalizePrice(tp)) {return;}
      trade.Sell(InpLotSize,_Symbol,cT.bid,sl,tp,"Stochastic EA");
      //trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotSize,cT.bid,sl,tp,"Stochastic EA");
   }  
         
  } //--- end of the OnTick() function
  
  
//+------------------------------------------------------------------+
//| Custom functions                                                 |
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
//| all_buy_sell = 2 to close a long trade                           |
//| all_buy_sell = 1 to close a short trade                          |
//+------------------------------------------------------------------+
bool ClosePositions(int all_buy_sell)
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
         if(all_buy_sell==1 && type==POSITION_TYPE_SELL) {continue;} 
         if(all_buy_sell==2 && type==POSITION_TYPE_BUY) {continue;}
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
bool CheckSignal(bool buy_sell, int cntBuySell)
{
   //--- return false if a position is open
   if(cntBuySell>0) {return false;}
   
   //--- check crossovers
   int lowerLevel = 100 - InpUpperLevel;
   bool upperExitCross = bufferMain[1]>=InpUpperLevel && bufferMain[2]<InpUpperLevel;
   bool upperEntryCross = bufferMain[1]<=InpUpperLevel && bufferMain[2]>InpUpperLevel;
   bool lowerExitCross = bufferMain[1]<=lowerLevel && bufferMain[2]>lowerLevel;
   bool lowerEntryCross = bufferMain[1]>=lowerLevel && bufferMain[2]<lowerLevel;
   
   //--- check signal
   switch(InpSignalMode)
   {
      case EXIT_CROSS_NORMAL: return ((buy_sell && lowerExitCross)  || (!buy_sell && upperExitCross));
      case ENTRY_CROSS_NORMAL: return ((buy_sell && lowerEntryCross) || (!buy_sell && upperEntryCross));
      case EXIT_CROSS_REVERSED: return ((buy_sell && upperExitCross) || (!buy_sell && lowerExitCross));
      case ENTRY_CROSS_REVERSED: return ((buy_sell && upperEntryCross) || (!buy_sell && lowerEntryCross));
   } 
   return false;
}
//+------------------------------------------------------------------+ 
bool CheckClearBars(bool buy_sell)
{
   //--- return true if filter is inactige
   if(InpClearBars==0) {return true;}
   
   bool checkLower = ((buy_sell && (InpSignalMode==EXIT_CROSS_NORMAL || InpSignalMode==ENTRY_CROSS_NORMAL))
                       || (!buy_sell && (InpSignalMode==EXIT_CROSS_REVERSED || InpSignalMode==ENTRY_CROSS_REVERSED)));
                       
   for(int i=3; i<(3+InpClearBars);i++)  
   {
       //---check upper level 
      if(!checkLower && ((bufferMain[i-1]>InpUpperLevel && bufferMain[i]<=InpUpperLevel)
                        || (bufferMain[i-1]<InpUpperLevel && bufferMain[i] >=InpUpperLevel)))
         {
             if(InpClearBarsReversed) {return true;}
             else 
             {           
               Print("Clear bars filter prevented ",buy_sell ? "buy" : "sell", " signal. Cross of upper level at index: ",(i-1),"->",i);
               return false;
             }
         }         
       //---check lower level 
      if(checkLower && ((bufferMain[i-1]<(100-InpUpperLevel) && bufferMain[i]>=(100-InpUpperLevel))
                        || (bufferMain[i-1]>(100-InpUpperLevel) && bufferMain[i]<=(100-InpUpperLevel))))
         {
             if(InpClearBarsReversed) {return true;}
             else 
             {           
               Print("Clear bars filter prevented ",buy_sell ? "buy" : "sell", " signal. Cross of lower level at index: ",(i-1),"->",i);
               return false;
             }
         }                  
   }   
   if(InpClearBarsReversed)
   {
      Print("Clear bars filter prevented ",buy_sell ? "buy" : "sell", " signal. No cross detected.");
      return false;
   }                   
   else {return true;}
}
//+------------------------------------------------------------------+
bool CheckInputs()
  {
   if(InpMagicNumber<=0)
     {
      Alert("Wrong input: Magicnumber <=0");
      return false;
     }
   if(InpLotSize<=0 || InpLotSize>10)
     {
      Alert("Wrong input: InpLotSize < 0 or > 10");
      return false;
     }
   if(InpTakeProfit<0)
     {
      Alert("Wrong input: Take profit < 0");
      return false;
     }
   if(!InpCloseSignal && InpStopLoss==0)
     {
      Alert("Wrong input: Close signal incorrect");
      return false;
     }
   if(InpKPeriod <= 0)
     {
      Alert("Wrong input: InpKPeriod < 0");
      return false;
     }
   if(InpUpperLevel <= 50 || InpUpperLevel>=100)
     {
      Alert("Wrong input: InpUpperLever<= 50 or > 100");
      return false;
     }
     
   if(InpClearBars<0)
     {
      Alert("Wrong input: InpClearBars<0");
      return false;
     }
     
   return true;
  }
//+------------------------------------------------------------------+
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
//+-------------------------T H E    E N D---------------------------+