//+------------------------------------------------------------------+
//|                                                FalseBreakout.mq5 |
//|                                                          Cesreve |
//|                                               Backtestedbots.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+ RESTE à FAIRE
// ajouter SL et TP en pourcentage
// ajouter SL et TP en points
// ajouter un indicateur et test les conditions ( ex: ATR au dessus/dessous de xvaleur )
//+------------------------------------------------------------------+
#property copyright "Cesreve"
#property link      "Backtestedbots.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Orchard\Frameworks\Framework_3.06\Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int InpMagicNumber = 0;

//--- general parameters
input group "==== General Parameers ====";
input string InpComment = "FalseBreakout";

//--- Hours 
input group "==== Trading hours ====";
input int InpStartHour        = 10; // Start hour
input int InpStartMinute      = 0;  // Start minute
input int InpStopHour         = 18; // Stop trading hour
input int InpStopMinute       = 0;  // Stop trading hour minute
input int InpCloseHour        = 21; // Close all positions hour
input int InpCloseMinute      = 55; // Close all positions minute

//--- lot Size 
input group "==== Lot Size ====";
input double InpLots = 0.01;
//--- strategy parameters 
input group "==== strategy parameters  ====";
input double InpTriggerTreshold = 0.15;
// ajouter input des indicateurs
//input int InpRSIPeriod = 15;

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+ 
MqlTick tick;
MqlDateTime nowTimeStruct;
//--- times
datetime nowTime = 0;
datetime startTime = 0;
datetime stopTime = 0;
datetime closeTime = 0;

//--- Indicators
int handleSAR;
double bufferSAR[];

int handleRSI;
double bufferRSI[];
//--- levels
double prevLow = 0;
double prevHigh = 0;

//--- orders
bool tradeAllowed = false;
int cntBuy = 0;
int cntSell = 0;

//--- comments
string cmmt = "";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);   
//---
   calculateDatetimes();
//--- create SAR hanlde
   handleSAR = iSAR(_Symbol, PERIOD_D1, 0.1, 0.1);
   ArraySetAsSeries( bufferSAR, true );
   if(handleSAR==INVALID_HANDLE)
     {
      Alert("Failed to create parabolic RSI handle");
      return INIT_FAILED;
     } 
//--- create RSI hanlde
   //handleRSI = iRSI(_Symbol, PERIOD_D1, InpRSIPeriod, PRICE_CLOSE);
   //ArraySetAsSeries( bufferRSI, true );
   //if(handleRSI==INVALID_HANDLE)
   //  {
   //   Alert("Failed to create parabolic RSI handle");
   //   return INIT_FAILED;
   //  }  

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(handleSAR);
   IndicatorRelease(handleRSI);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- datetime calculations
   calculateDatetimes();
//--- update indicators
   fillBuffers(2);
//---    
   drawObjetcs();
//---
   if( IsNewDay() ) { closePositions(); tradeAllowed = true; }
//---
// stratégieet RESTE à FAIRE
// conditions sur les horaires 
// ajuster les éléments graphiques (fonction drawObjects)
// prendre le plus bas et le plus haut de la veille (utiliser daily bars ?)
// si prix inférieur à prevLow - prevLow*0.15/100 -> buy stop sur prevLow
// si prix supérieur à prevHigh + prevHigh*0.15/100 -> sell stop sur prevHigh

//--- Time now
   nowTime = TimeCurrent();
   TimeToStruct(nowTime, nowTimeStruct);
//---
   if(nowTime >= closeTime) {closePositions();}  
//--- Levels 
   prevLow = iLow(_Symbol, PERIOD_D1, 1);
   prevHigh = iHigh(_Symbol, PERIOD_D1, 1);
//--- Prices
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
//--- set Orders
   if( nowTime >= startTime ) {
      //--- Buy
      if( (ask < (prevLow - prevLow*InpTriggerTreshold/100) ) && tradeAllowed ) {
         if( trade.BuyStop(InpLots, prevLow, _Symbol, 0, 0, ORDER_TIME_SPECIFIED_DAY, stopTime, InpComment) ) { 
            tradeAllowed = false; }
     }
     //--- Sell
      if( (bid > (prevHigh + prevHigh*InpTriggerTreshold/100) ) && tradeAllowed ) {
         if( trade.SellStop(InpLots, prevHigh, _Symbol, 0, 0, ORDER_TIME_SPECIFIED_DAY, stopTime, InpComment) ) { 
            tradeAllowed = false; }
     }
   }
//---comments
   cmmt = "";
   cmmt += "low level: ";
   cmmt += "\n";
   cmmt += string(NormalizeDouble(prevLow, 2));
   cmmt += "high level: ";
   cmmt += "\n";
   cmmt += string(NormalizeDouble(prevHigh, 2));
   cmmt += "Lotsiez: ";
   cmmt += (string)InpLots;
   
   
//+-----------------    END OF ON TICK FUNCTION    ------------------+

}

//+------------------------------------------------------------------+
// ---------            Custom functions            -----------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//- Calculate datetimes  --------------------------------------------+
void calculateDatetimes()
{
   //--- convert to times   
   MqlDateTime nowStruct;
   datetime now = TimeCurrent();
   TimeToStruct(now, nowStruct);   
   nowStruct.sec = 0;
   
   // start time
   nowStruct.hour = InpStartHour;
   nowStruct.min = InpStartMinute;
   startTime = StructToTime(nowStruct);
   
   // stop time
   nowStruct.hour = InpStopHour;
   nowStruct.min = InpStopMinute;
   stopTime = StructToTime(nowStruct);
   
   // close time
   nowStruct.hour = InpCloseHour;
   nowStruct.min = InpCloseMinute;
   closeTime = StructToTime(nowStruct);
}

////+------------------------------------------------------------------+
////- Count positions  ------------------------------------------------+
bool CountOpenPositions()
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
//- Close all positions   -------------------------------------------+
bool closePositions()
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
////+------------------------------------------------------------------+
////- New Bar  --------------------------------------------------------+
bool IsNewbar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(Symbol(), Period(), 0);
   if(previousTime!=currentTime)
     {
      previousTime=currentTime;
      return true;
     }
   return false;  
  }
//+------------------------------------------------------------------+
//| indicators                                                       |
//+------------------------------------------------------------------+
// Load values from the indicators into buffers
bool fillBuffers( int valuesRequired ) {

   if ( CopyBuffer( handleSAR, 0, 0, valuesRequired, bufferSAR ) < valuesRequired ) {
      Print( "Insufficient results from SAR" );
      return false;
   }
   //if ( CopyBuffer( handleRSI, 0, 0, valuesRequired, bufferRSI ) < valuesRequired ) {
   //   Print( "Insufficient results from RSI" );
   //   return false;
   //}

   return true;
}
//+------------------------------------------------------------------+
//- New Day  --------------------------------------------------------+
bool IsNewDay()
  {
   static datetime previousDay = 0;
   datetime currentDay = StringToTime(StringSubstr(TimeToString(iTime(Symbol(),PERIOD_M1,0)),0,11));
   if(previousDay!=currentDay) {
      previousDay=currentDay;
      return true;
     }
   return false;  
  } 
//+------------------------------------------------------------------+
//- Draw objects  ---------------------------------------------------+
void drawObjetcs() {
      //--- high border range
      ObjectCreate(0, "prevHigh", OBJ_TREND, 0, startTime, prevHigh, nowTime, prevHigh);
      ObjectSetInteger(0, "prevHigh", OBJPROP_HIDDEN, false );
      //ObjectCreate(0, "prevHigh next", OBJ_TREND, 0, nowTime, prevHigh, stopTime, prevHigh);
      //ObjectSetInteger(0, "prevHigh next", OBJPROP_HIDDEN, false );
      //ObjectSetInteger( 0, "prevHigh next", OBJPROP_STYLE, STYLE_DOT );
      //text
      ObjectCreate(0, "range high text", OBJ_TEXT, 0, startTime, prevHigh );
      ObjectSetString(0, "range high text", OBJPROP_TEXT, "range High");
      ObjectSetInteger(0, "range high text", OBJPROP_HIDDEN, false );
      
      //--- low border range
      ObjectCreate(0,"prevLow", OBJ_TREND, 0, startTime, prevLow, nowTime, prevLow);
      ObjectSetInteger(0, "prevLow", OBJPROP_HIDDEN, false );
      //ObjectCreate(0, "prevLow next", OBJ_TREND, 0, nowTime, prevLow, stopTime, prevLow);
      //ObjectSetInteger(0, "prevLow next", OBJPROP_HIDDEN, false );
      //ObjectSetInteger( 0, "prevLow next", OBJPROP_STYLE, STYLE_DOT );
      //text
      ObjectCreate(0, "range low text", OBJ_TEXT, 0, startTime, prevLow);
      ObjectSetString(0, "range low text", OBJPROP_TEXT, "range Low");
      ObjectSetInteger(0, "range low text", OBJPROP_HIDDEN, false );     
   }    