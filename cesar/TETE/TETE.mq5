//+------------------------------------------------------------------+
//|                                                         TETE.mq5 |
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
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int InpMagicNumber = 13112023;
//--- trades inputs 
input group "==== Trading hours ====";
input int InpStartHour        = 10; // Start hour
input int InpStartMinute      = 0;  // Start minute
input int InpStopHour         = 18; // Stop trading hour
input int InpStopMinute       = 0;  // Stop trading hour minute
input int InpCloseHour        = 22; // Close all positions hour
input int InpCloseMinute      = 55; // Close all positions minute


//--- Strategy parameters
input group "===== Strategy parameters ====";
input int InpMaPeriod            = 100; // MA Period
input int InpDonchianPeriod      = 20;  // Donchian Channel Period
input int InpTakeProfit          = 50;  // Take profit
input int InpStopLoss            = 50;  // Stop Loss
input int InpBreakEvenTreshold   = 25;  // Break even threshold
input int InpExitNumber          = 20;  // Number of candles after exit

//--- days 
input bool Sunday   =false; // Sunday
input bool Monday   =true; // Monday
input bool Tuesday  =true; // Tuesday 
input bool Wednesday=true; // Wednesday
input bool Thursday =true; // Thursday
input bool Friday   =true; // Friday
input bool Saturday =false; // Saturday



//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;
MqlDateTime nowTimeStruct;
int handleMA = 0;
datetime now = 0;
datetime startTime = 0;
datetime stopTime = 0;
datetime closeTime = 0;

bool WeekDays[7];

double ma[];
double close[];

int cntBuy = 0;
int cntSell = 0;

datetime nowTime;

string cmt = "";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber);   
//---
   calculateDatetimes();
   WeekDays_Init();
//--- create moving average handle
   handleMA = iMA(Symbol(), PERIOD_CURRENT,InpMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
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
//---
   if(!IsNewbar()) {return;}
   //else { Print("New bar"); }
   
//---
   now = TimeCurrent();
   TimeToStruct(now, nowTimeStruct);
   SymbolInfoTick(Symbol(), tick);
   if(!WeekDays[nowTimeStruct.day_of_week]) {return;}
   
//---
   SymbolInfoTick(Symbol(), tick);
   calculateDatetimes();
   ma();
   nowTime = TimeCurrent();
   cntBuy = 0;
   cntSell = 0;
   CountOpenPositions();
   closeAfterxCandles(InpExitNumber);

//--- add time conditions
   if( nowTime >= closeTime) {closePositions();}
   if( !(nowTime>= startTime) ) {return;}
   if( nowTime >= stopTime) {return;}
//---
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   double cl = 0;
   cl = iClose(Symbol(), PERIOD_CURRENT, 1);
   
   double ma1 = 0;
   ma1 = ma[0];

   double hh = 0;
   int hbar = iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,20,2);
   datetime hbartime = iTime(Symbol(), PERIOD_CURRENT, hbar);
   hh = iHigh(Symbol(),PERIOD_CURRENT,hbar);
   
   double ll = 0;
   int lbar = iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,20,2);
   datetime lbartime = iTime(Symbol(), PERIOD_CURRENT, lbar);
   ll = iLow(Symbol(),PERIOD_CURRENT,lbar); 
   
   //--- draw highs and lows
   //Print(lbartime);
   ObjectCreate(0, "high prive", OBJ_TREND, 0, hbartime, hh, nowTime, hh);
   ObjectCreate(0, "low price", OBJ_TREND, 0, lbartime, ll, nowTime, ll);
   
   

//--- 
      

//--- Open trade conditions
   if(cl > ma1 && cl < ll && cntBuy == 0) {
         Print("go long");
         trade.Buy(0.1, Symbol(), tick.ask, tick.ask - InpStopLoss, tick.ask +InpTakeProfit);
         // buy
      }
      
   if(cl < ma1 && cl > hh && cntSell == 0) {
         Print("go short");
         trade.Sell(0.1, Symbol(), tick.bid, tick.bid + InpStopLoss, tick.bid - InpTakeProfit);
         // sell
      }   

//--- add breakeven
   if( cntBuy + cntSell  > 0) {setBreakEven();}

//--- add trailing stop ?
   
//--- add time conditions
   

//---
   cmt = "";
   
   
   cmt += (string)startTime;
   cmt += "\n";
   cmt += (string)nowTime;
   cmt += "\n";
   cmt += (string)ll;
   cmt += "\n";
   cmt += (string)cl;
   cmt += "\n";
   cmt += (string)OrderGetInteger(ORDER_TIME_SETUP);
   Comment(cmt);

//---
//si heure ok
//prendre moyenne 
//prendre plus haut et plus bas des 20 dernires periodes
//
//si prix > moyenn
//   si cloture sous plus bas de 20 dernieres 
//      achat
//si prix < moyen
//   si clot au dessu plus haut des 20 derneires perdioes
//      vente      
 
 // calculer la MA 
 // calculer le plus hat des 20 derniers 
 // calculer le plus bas des 20 derneires  
 
 
} //--- end of the on Tick function
  
//+------------------------------------------------------------------+
// ---------            Custom functions            -----------------+

//+------------------------------------------------------------------+
//- Calculate datetimes  --------------------------------------------+
void calculateDatetimes()
{
   //--- convert to times   
   MqlDateTime nowStruct;
   now = TimeCurrent();
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
//+------------------------------------------------------------------+
//- Orders   --------------------------------------------------------+
bool closeAfterxCandles(int x_candles)
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
         PositionGetInteger(POSITION_TIME);
         datetime timeOpen = (datetime)PositionGetInteger(POSITION_TIME);
         //Print(timeOpen);
         if(iBarShift(Symbol(), Period(),timeOpen) > x_candles) 
         {
            trade.PositionClose(ticket);
            if(trade.ResultRetcode()!=TRADE_RETCODE_DONE)
            {
               Print("Failed to close position, ticket: ", (string)ticket, 
                     " result: ", (string)trade.ResultRetcode(), ": ", trade.CheckResultRetcodeDescription());
            }
         }
      }
   }  
   return true;    
}

//+--------------------------------------------------------------------------------------------------------+
//| MA   -----------------------------------------------------------------------------------------------+
void ma()
{
   ArraySetAsSeries(ma, true);
   if(CopyBuffer(handleMA,0,1,1,ma)!=1) { Print("Failed to get iMA values."); }
}
//+--------------------------------------------------------------------------------------------------------+
//| Closing prices   --------------------------------------------------------------------------------------+
void closes() 
{
   if(CopyClose(Symbol(), Period(),1,1,close)!=1) { Print("Failed to get close prices"); }
}
//+------------------------------------------------------------------+
//- days of weeks  --------------------------------------------------+
void WeekDays_Init()
  {
   WeekDays[0]=Sunday;
   WeekDays[1]=Monday;
   WeekDays[2]=Tuesday;
   WeekDays[3]=Wednesday;
   WeekDays[4]=Thursday;
   WeekDays[5]=Friday;
   WeekDays[6]=Saturday;
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
