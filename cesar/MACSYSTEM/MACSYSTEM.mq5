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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum time_unit
  {
    M1 = PERIOD_M1,
    M5 = PERIOD_M5
  };
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int InpMagicNumber = 13112023;

//--- Hours 
input group "==== Trading hours ====";
input int InpStartHour        = 10; // Start hour
input int InpStartMinute      = 0;  // Start minute
input int InpStopHour         = 20; // Stop trading hour
input int InpStopMinute       = 0;  // Stop trading hour minute
input int InpCloseHour        = 22; // Close all positions hour
input int InpCloseMinute      = 55; // Close all positions minute

//--- strategy parameters
input group "==== TIME FRAME ====";
input time_unit InpTframe= M1; // Trailing stop method

//--- indicator parameters
input group "==== Indicator parmaeter ====";
input int InpFastEmaPeriod = 12;
input int InpSlowEmaPeriod = 26;
input int InpSignalPeriod = 9;

//---
input group "==== OTHE ====";
input int InpBreakEvenTreshold = 0;
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+ 
MqlTick tick;
MqlDateTime nowTimeStruct;
//---
string cmt ="";
//---

datetime nowTime = 0;
datetime startTime = 0;
datetime stopTime = 0;
datetime closeTime = 0;

//--- Indicators
int handle;
double macdBuffer[];
double signalBuffer[];
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
   handle = iMACD(Symbol(), (ENUM_TIMEFRAMES)InpTframe ,InpFastEmaPeriod,InpSlowEmaPeriod,InpSignalPeriod,PRICE_CLOSE);
   ArraySetAsSeries(macdBuffer, true);
   ArraySetAsSeries(signalBuffer, true);
   if(handle==INVALID_HANDLE)
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
   IndicatorRelease(handle);
   
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
   if( !(nowTime>= startTime) ) {return;}
   if( nowTime >= stopTime) {return;}
//--- update indicators
   MACD();
//---
   
//--- conditions
   // BUY
   if(macdBuffer[1]>0 && macdBuffer[1]>macdBuffer[2] && macdBuffer[2]<macdBuffer[3]) {Print("signal long");}
   
   //SELL
   if(macdBuffer[1]<0 && macdBuffer[1]<macdBuffer[2] && macdBuffer[2]>macdBuffer[3]) {Print("signal short");}
//---
   double close1 = iClose(Symbol(), Period(), 1);
   
//---
   cmt = "";
   cmt += (string)macdBuffer[1];
   cmt += "\n";
   cmt += (string)macdBuffer[0];
   cmt += "\n";
   cmt += (string)(macdBuffer[1]/close1*1000);
   cmt += "\n";
   cmt += (string)MathAbs(macdBuffer[1]-signalBuffer[1]);
   Comment(cmt);
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
//+------------------------------------------------------------------+
//- MACD   ----------------------------------------------------------+
void MACD()
{
   if(CopyBuffer(handle,0,0,4,macdBuffer)!=4) { Print("Failed to get MACD values."); }
   if(CopyBuffer(handle,1,0,4,signalBuffer)!=4) { Print("Failed to get signal values."); }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+


