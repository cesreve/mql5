//+------------------------------------------------------------------+
//|                                                 MagicPattern.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
//| Defines                                                          |
//+------------------------------------------------------------------+
#define  NR_CONDITIONS 2 //  number of conditions

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
enum MODE {
   OPEN=0, 
   HIGH=1,
   LOW=2,
   CLOSE=3,
   RANGE=4,
   BODY=5,
   RATIO=6,
   VALUE=7   
};

enum INDEX{
  INDEX_0=0,
  INDEX_1=1,
  INDEX_2=2,
  INDEX_3=3
};

enum COMPARE{
   GREATER,
   LESS
};

struct CONDITION{
   bool active;
   MODE modeA;
   INDEX idxA;
   COMPARE comp;
   MODE modeB;
   INDEX idxB;
   double value;
   
   CONDITION(): active(false){};
};

CONDITION con[NR_CONDITIONS]; // condition array
MqlTick currentTick;
CTrade trade;

//+------------------------------------------------------------------+
//| Input                                                            |
//+------------------------------------------------------------------+
static input long InpMagicNumber = 161613102023;
static input double InpLots = 0.1;
input int InpStopLoss = 100;
input int InpTakeProfit = 200;

input group "=== Condition 1 ===";
input bool InpCon1Active = true;
input MODE InpCon1ModeA = OPEN;
input INDEX InputCon1IndexA = INDEX_1;
input COMPARE InpCon1Compare = GREATER;
input MODE InpCon1ModeB = OPEN;
input INDEX InputCon1IndexB = INDEX_1;
input double InpCon1Value = 0;

input group "=== Condition 2 ===";
input bool InpCon2Active = false;
input MODE InpCon2ModeA = OPEN;
input INDEX InputCon2IndexA = INDEX_1;
input COMPARE InpCon2Compare = GREATER;
input MODE InpCon2ModeB = OPEN;
input INDEX InputCon2IndexB = INDEX_1;
input double InpCon2Value = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set input (before we check inputs)
   SetInputs();
   
//--- check inputs
   if(!CheckInputs()) {return INIT_PARAMETERS_INCORRECT;}

//--- set magic number
   trade.SetExpertMagicNumber(InpMagicNumber);
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
   if(!isNewbar()) {return;}
   
//---
   if(!SymbolInfoTick(Symbol(), currentTick)) {Print("Failed to get current tick."); return;}

//---
   int cntBuy, cntSell;
   if(!CountOpenPositions(cntBuy,cntSell)) {Print("Failed to count open positions."); return;}
   
//---
   if(cntBuy==0) {
      // calculate sl and tp
      double sl = InpStopLoss == 0 ? 0 : currentTick.bid - InpStopLoss;
      double tp = InpTakeProfit == 0 ? 0 : currentTick.bid - InpTakeProfit;      
      trade.PositionOpen(Symbol(), ORDER_TYPE_BUY, InpLots, currentTick.ask, sl , tp , "Candle bot");
   }  
   
   if(cntSell==0) {
      // calculate sl and tp
      double sl = InpStopLoss == 0 ? 0 : currentTick.ask + InpStopLoss;
      double tp = InpTakeProfit == 0 ? 0 : currentTick.ask + InpTakeProfit;      
      trade.PositionOpen(Symbol(), ORDER_TYPE_SELL, InpLots, currentTick.ask, sl , tp , "Candle bot");
   
   }
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void SetInputs() {
   // condition 1
   con[0].active =  InpCon1Active;
   con[0].modeA = InpCon1ModeA;
   con[0].idxA = InputCon1IndexA;
   con[0].comp = InpCon1Compare;
   con[0].modeB = InpCon1ModeB;
   con[0].idxB = InputCon1IndexB;
   con[0].value = InpCon1Value;
   
   // condition 1
   con[1].active =  InpCon2Active;
   con[1].modeA = InpCon2ModeA;
   con[1].idxA = InputCon2IndexA;
   con[1].comp = InpCon2Compare;
   con[1].modeB = InpCon2ModeB;
   con[1].idxB = InputCon2IndexB;
   con[1].value = InpCon2Value;
}

bool CheckInputs() {
   
   // magic number
   return true;
}
