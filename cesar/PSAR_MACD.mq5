//+------------------------------------------------------------------+
//|                                                    PSAR_MACD.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
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
int handleMACD;
int handleSAR;
MqlTick tick;
string comm="";
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ====";
static input long InpMagicNumber = 753; 

input group "==== Indicators ====";
input int InpMacdFastMa          = 12; //fast_ema_period
input int InpMacdSlowMa          = 26; //slow_ema_period
input int InpMacdSignalPeriod    = 9; //signal_period

input double InpSarStep          = 0.02; //price increment step - acceleration factor
input double InpSarMaximum       = 0.2; //maximum value of step 

input group "==== Trading ====";
input double InpLotSize          = 0.1;
input int InpStopLoss            = 700;
input int InpTakeProfit          = 700;
input int pipsTrailingStopLevel  = 350;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber); 
   
//--- create moving average hanlde
   handleMACD = iMACD(_Symbol,_Period,InpMacdFastMa,InpMacdSlowMa,InpMacdSignalPeriod,PRICE_CLOSE);
   if(handleMACD==INVALID_HANDLE)
     {
      Alert("Failed to create macd handle");
      return INIT_FAILED;
     }   
     
//--- create parabolic sar hanlde
   handleSAR = iSAR(_Symbol, _Period,InpSarStep,InpSarMaximum);
   if(handleSAR==INVALID_HANDLE)
     {
      Alert("Failed to create parabolic sar handle");
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

//--- check for buy position
   if(CheckSignal(1.0) && cntBuy<1)
   {
      Print("Open buy position");
      //if(InpCloseSignal) {if(!ClosePositions(2)){return;}}
      double sl = InpStopLoss==0 ? 0 : tick.bid - InpStopLoss*_Point;
      double tp = InpTakeProfit==0 ? 0 : tick.bid + InpTakeProfit*_Point;
      if(!NormalizePrice(sl)) {return;}
      if(!NormalizePrice(tp)) {return;}
      trade.Buy(InpLotSize,_Symbol,tick.ask,sl,tp,"PSAR_MACD EA");
   }
////--- check for sell position
   if(CheckSignal(-1.0) && cntSell<1)
   {
      Print("Open sell position");
      double sl = InpStopLoss==0 ? 0: tick.ask + InpStopLoss*_Point;
      double tp = InpTakeProfit==0 ? 0 : tick.ask - InpTakeProfit*_Point;
      if(!NormalizePrice(sl)) {return;}
      if(!NormalizePrice(tp)) {return;}
      trade.Sell(InpLotSize,_Symbol,tick.bid,sl,tp,"PSAR_MACD EA");
   }  
  
//--- Comment
   Comment(CheckSignal(1),"\n",
           CheckSignal(-1));
   
  } // end of the OnTick() function
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                  Custom functions                                +
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//- direction: 1 for a long, -1 for a short  ------------------------+ 
bool CheckSignal(double direction)
{
   double close1 = iClose(_Symbol,_Period,1);
   double close2 = iClose(_Symbol,_Period,2);
   
   // pour un long il faut un signal donnée par le sar et que le macd soit bien orienté
   if(direction == 1)
   {
      if(sar(2)>close2 && sar(1)<close1 && macd(1,0)>0) {return true; Print("Buy Signal");}
   } 
   // pour un court il faut un signal donnée par le sar et que le macd soit bien orienté
   if(direction == -1)
   {
      if(sar(2)<close2 && sar(1)>close1 && macd(1,0)<0) {return true; Print("Sell Signal");}
   } 
   return false;
}
////+------------------------------------------------------------------+
////- Count positions  ------------------------------------------------+
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
////+------------------------------------------------------------------+
////- Breakveven stop   -----------------------------------------------+
bool trailingStop(int pipsNumber) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}

      double positionStopLoss = PositionGetDouble(POSITION_SL);
      double positionTakeProfit = PositionGetDouble(POSITION_TP);
      double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double positionCurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      
      if(MathAbs(positionOpenPrice - positionCurrentPrice)/_Point>pipsNumber)
      {
         trade.PositionModify(ticket,positionOpenPrice,positionTakeProfit);
         return true;
      }
  }
  return false;
}  
////+------------------------------------------------------------------+
////- New Bar  --------------------------------------------------------+
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
////+------------------------------------------------------------------+
////- NormalizePrice   ------------------------------------------------+
bool NormalizePrice(double &price)
{
   double tickSize=0;
   
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {Print("Failed to get tick size"); return false;}
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
   
   return true;
}
////+------------------------------------------------------------------+
////- 0 - MAIN_LINE, 1 - SIGNAL_LINE   --------------------------------+
double macd(int index, int line)
{
   double macdBuffer[];
   ArraySetAsSeries(macdBuffer, true);
   if(CopyBuffer(handleMACD,line,index,1,macdBuffer)!=1) { Print("Failed to get iMACD values."); return -1.0;}
   else return macdBuffer[0];   
}
//+------------------------------------------------------------------+
//- Parabolic SAR   -------------------------------------------------+
double sar(int index)
{
   double sarBuffer[];
   ArraySetAsSeries(sarBuffer, true);
   if(CopyBuffer(handleSAR,0,index,1,sarBuffer)!=1) { Print("Failed to get iSAR values."); return -1.0;}
   else return sarBuffer[0];   
}
//+----------------------   T H E    E N D   ------------------------+