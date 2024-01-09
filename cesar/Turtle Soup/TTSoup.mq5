//+------------------------------------------------------------------+
//|                                                     Template.mq5 |
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
CTrade trade;

const string Donchian   = "Examples\\Donchian";
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int InpMagicNumber = 13112023;

//--- Hours 
input group "==== Trading hours ====";
input int InpStartHour        = 10; // Start hour
input int InpStartMinute      = 0;  // Start minute
input int InpStopHour         = 18; // Stop trading hour
input int InpStopMinute       = 0;  // Stop trading hour minute
input int InpCloseHour        = 22; // Close all positions hour
input int InpCloseMinute      = 55; // Close all positions minute

//---
input group "==== ATR ====";
input int InpATRPeriod = 14 ;
input group "==== Donchian ====";
input int InpDonchianPeriod = 5;
input group "==== Fast EMA ====";
input int InpFastEMAPeriod = 21;
input group "==== Slow EMA ====";
input int InpSlowEMAPeriod = 34;

//---
input int InpBreakEvenTreshold = 0;
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+ 
MqlTick tick;
MqlDateTime nowTimeStruct;

datetime nowTime = 0;
datetime startTime = 0;
datetime stopTime = 0;
datetime closeTime = 0;

//--- Indicators
int handleFastEMA;
double bufferFastEMA[];

int handleSlowEMA;
double bufferSlowEMA[];

int handleATR;
double bufferATR[];

int handleDonchian;
double bufferDonchianUP[];
double bufferDonchianDW[];
//---
int cntBuy = 0;
int cntSell = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);   
//---
   calculateDatetimes();   
//--- create indicator hanlde
   handleFastEMA = iMA(Symbol(), Period(), InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);   
   if(handleFastEMA==INVALID_HANDLE)
     {
      Alert("Failed to create fast ma handle");
      return INIT_FAILED;
     }
//---
   handleSlowEMA = iMA(Symbol(), Period(), InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);   
   if(handleSlowEMA==INVALID_HANDLE)
     {
      Alert("Failed to create slow ema handle");
      return INIT_FAILED;
     }
//---
   handleATR = iATR(Symbol(), Period(), InpATRPeriod);   
   if(handleATR==INVALID_HANDLE)
     {
      Alert("Failed to create atr handle");
      return INIT_FAILED;
     }
//---
   handleDonchian = iCustom(Symbol(), Period(), Donchian, 5);   
   if(handleDonchian==INVALID_HANDLE)
     {
      Alert("Failed to Donchian sar handle");
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
   IndicatorRelease(handleFastEMA);
   IndicatorRelease(handleSlowEMA);
   IndicatorRelease(handleATR);
   IndicatorRelease(handleDonchian);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   calculateDatetimes();
   nowTime = TimeCurrent();
   TimeToStruct(nowTime, nowTimeStruct);

//---
   if(!IsNewbar()) {return;}
   
//--- update indicators
   fillBuffers(2);
//---

   
//--- Trading conditions
if(bufferFastEMA[0] > bufferSlowEMA[0] && bufferDonchianDW[0] < bufferDonchianDW[1]) {Print("buy");}

   
  }
//+-----------------    END OF ON TICK FUNCTION    ------------------+



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
// Set to BE   ------------------------------------------------------+
bool setBreakEven()
{
   //double currPrice = 
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {Print("Fail to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)) {Print("Failed to select position"); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to get position magic number"); return false;}
      if(magic==InpMagicNumber) {
         double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         double priceCurrent = PositionGetDouble(POSITION_PRICE_CURRENT);
         double positionSL = PositionGetDouble(POSITION_SL);
         double positionTP = PositionGetDouble(POSITION_TP);
         //if( MathAbs(priceCurrent-priceOpen) > MathAbs(priceCurrent - positionSL) ) {
         if( MathAbs(priceCurrent-priceOpen) > InpBreakEvenTreshold ) {
            trade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_TP) );
         }
         
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

   if ( CopyBuffer( handleFastEMA, 0, 1, valuesRequired, bufferFastEMA ) < valuesRequired ) {
      Print( "Insufficient results from FEMA" );
      return false;
   }
   if ( CopyBuffer( handleSlowEMA, 0, 1, valuesRequired, bufferSlowEMA ) < valuesRequired ) {
      Print( "Insufficient results from slow SEMA" );
      return false;
   }
   if ( CopyBuffer( handleATR, 0, 1, valuesRequired, bufferATR ) < valuesRequired ) {
      Print( "Insufficient results from ATR" );
      return false;
   }
   if ( CopyBuffer( handleDonchian, 1, 1, valuesRequired, bufferDonchianUP ) < valuesRequired ) {
      Print( "Insufficient results from Donchian" );
      return false;
   }
   if ( CopyBuffer( handleDonchian, 2, 1, valuesRequired, bufferDonchianDW ) < valuesRequired ) {
      Print( "Insufficient results from Donchian" );
      return false;
   }
   return true;
}


