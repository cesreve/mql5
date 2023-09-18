//+------------------------------------------------------------------+
//|                                                 OpenPullBack.mq5 |
//|                                                           ceezer |
//+------------------------------------------------------------------+

//faire un enum levels avec valeurs (associées ?)
//si level suivant franchi poer un ordre stop
//modifier ordre stop si level suivant validé
//sachant que 3 levels seulement: 50 validé par 68 et 38 valide par 50 et 23 validé par 38
//faire 2 vecteurs avec les prix des niveaux et mettre deses ordres stop (ex stop à 23 si 38 touché))
//avec des targets différentes ?
//backtester avant de fair eun truc trop compliqué
// pas necessaire d'avoir une variable de validation de range, on peut tout calculer en direct avec just une condition de temps ou de retracement pour chq tick

#property copyright "ceezer"
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
// Time inputs
//--- range input
input group "==== Range ====";
input int InpStartRangeHour   = 10; // Range Start hour
input int InpStartRangeMinute = 0;  // Range Start minute
input int InpEndRangeHour     = 10; // Range End hour
input int InpEndRangeMinute   = 30; // Range End minute
//--- trades inputs 
input group "==== Trading hours ====";
input int InpStopHour         = 13; // Stop pending orders hour
input int InpStopMinute       = 0;  // Stop pending orders minute
input int InpCloseHour        = 16; // Close all positions hour
input int InpCloseMinute      = 55; // Close all positions minute
//--- strategy parameters
input group "==== Strategy parameters ====";
double input inpRatio = 0.382;
input int InpAmplitudeMin = 15;
input int InpAmplitudeMax = 116;
input int InpDistanceOrdre = 4;
//--- others
input group "==== Expert settings ====";
input int InpMagicNumber = 753;
input double InpLots=0.1; // 


//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;

double rangeHigh = 0;
double rangeLow = 0;
double amplitude = 0;
int highCandle = 0;
int lowCandle = 0;
bool tradeAllowed = false;
string comm = "";

//--- times
int startRangeHour = InpStartRangeHour;
int startRangeMinute = InpStartRangeMinute;
int endRangeHour = InpEndRangeHour;
int endRangeMinute = InpEndRangeMinute;
int stopHour = InpStopHour;
int stopMinute = InpStopMinute;
int closeHour = InpCloseHour;
int closeMinute = InpCloseMinute;

datetime now;
datetime startRange = 0;
datetime endRange   = 0;
datetime stopTime   = 0;
datetime closeTime  = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   now = TimeCurrent();
   calculateDatetimes();
//---
   trade.SetExpertMagicNumber(InpMagicNumber);
//---
 
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   now = TimeCurrent();
//---
   if(IsNewDay()) {
      ObjectCreate(0, "New Day",OBJ_VLINE,0,iTime(_Symbol,_Period,0),0);
      calculateDatetimes();
      closePositions();
      highCandle = 0;
      lowCandle = 0;
      rangeHigh = 0;
      rangeLow = 0;
      tradeAllowed=true;
      }

//---
   if(!(now>=startRange)) {
      return;
      }
//---
   SymbolInfoTick(Symbol(), tick);
//---
   // now > end range
   // price dans le trigger range 
   // si prix pas dans le trigger range on continue à calculer le haut et le bas 
   // si des ordres sont placés ie. tradeAllowed passe à false alors on arrete de calculer le range
   // si amplitude > amplitude max alors on passe le tradeAllowed à false aussi.
   //if(!(now>=stopTime)) {
   //   highBetweenTwoHours(startRange, now);
   //   }
   //highBetweenTwoHours(startRange, now);
   //drawObjetcs();
//---
   if(now >= endRange && now <= stopTime && tradeAllowed == true)
   {  
      //---
      highBetweenTwoHours(startRange, now);
      drawObjetcs();
      //--- range validation
      if( highCandle < lowCandle ) {
         Print("bullish range in construction");
         double priceCurrent = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         if(priceCurrent < rangeHigh-(rangeHigh-rangeLow)*0.236) {
            Print("Bullish range validated");
            tradeAllowed = false; //à remplace par un bool pour fixer le range et les objets
         }
      }
      else {
         double priceCurrent = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         if(priceCurrent > rangeLow + (rangeHigh-rangeLow)*0.236) {
            Print("bearish range validated");
            tradeAllowed = false; 
         }
      }  
      
      //--- place orders conditions      
      if(tick.last < rangeHigh-inpRatio*amplitude && tick.last > rangeLow+inpRatio*amplitude)
      {
         if(OrdersTotal()<1 && amplitude > InpAmplitudeMin && amplitude < InpAmplitudeMax)
         {
            placeStopOrders(rangeHigh-InpDistanceOrdre, rangeLow+InpDistanceOrdre);
            tradeAllowed = false;
         }
      }     
   }
//---
//for long position
//if range is validated = true
//calculate price retracement levels
//if price is under 38 but bove 50 (ou bien if price between priceTrigger[1] et priceTrigger[2] set order at priceOpen[1])
//set stop order at 23
//---
   if(now >= closeTime) {closePositions();}
//---
   comm = "";
   comm += (string)rangeHigh;
   comm += "\n";
   comm += (string)rangeLow;
   comm += "\n";
   comm += (string)now;
   comm += "\n";
   comm += "\n";
   Comment(comm);

  } // end of the OnTick() Function
  
//+------------------------------------------------------------------+
//|                    Custom functions                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//- High between 2 hours  -------------------------------------------+
void highBetweenTwoHours(datetime startTime, datetime endTime)
{
   if(!(endTime>=startTime)) {Print("endTime must be superior to startTime");}
   
   else {   
      int startRangePos = iBarShift(Symbol(),PERIOD_M1,startTime);
      int endRangePos   = iBarShift(Symbol(),PERIOD_M1,endTime);
      int barCount      = startRangePos - endRangePos + 1;
      
      highCandle = iHighest(Symbol(),PERIOD_M1,MODE_HIGH,barCount,endRangePos);
      lowCandle = iLowest(Symbol(),PERIOD_M1,MODE_LOW,barCount,endRangePos);
      rangeHigh = iHigh(Symbol(),PERIOD_M1,highCandle);
      rangeLow  = iLow(Symbol(),PERIOD_M1,lowCandle); 
      
      amplitude = rangeHigh - rangeLow;
   }
}
//+------------------------------------------------------------------+
//- Calculate datetimes  --------------------------------------------+
void calculateDatetimes()
{
   //--- convert to times   
   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);   
   nowStruct.sec = 0;
   
   // start time
   nowStruct.hour = startRangeHour;
   nowStruct.min = startRangeMinute;
   startRange = StructToTime(nowStruct);
   
   // end time
   nowStruct.hour = endRangeHour;
   nowStruct.min = endRangeMinute;
   endRange = StructToTime(nowStruct);
   
   // stop time
   nowStruct.hour = stopHour;
   nowStruct.min = stopMinute;
   stopTime = StructToTime(nowStruct);
   
   // close time
   nowStruct.hour = closeHour;
   nowStruct.min = closeMinute;
   closeTime = StructToTime(nowStruct);
}
//+------------------------------------------------------------------+
//- Place stop orders  ----------------------------------------------+    
bool placeStopOrders(double priceHigh, double priceLow)
{
   bool buyStopResult, sellStopResult  = false;
   buyStopResult = trade.BuyStop(InpLots,priceHigh,Symbol(),priceLow,0,ORDER_TIME_SPECIFIED,stopTime,"Buy stop ProOrder");
   if(!buyStopResult) {Print(__FUNCTION__,"--> OrderSend error ", trade.ResultComment()); return false;}
   sellStopResult = trade.SellStop(InpLots,priceLow,Symbol(),priceHigh,0,ORDER_TIME_SPECIFIED,stopTime,"Sell stop ProOrder");
   if(!sellStopResult) {Print(__FUNCTION__,"--> OrderSend error ", trade.ResultComment()); return false;}
   
   tradeAllowed = false;
   
   return buyStopResult && sellStopResult; 
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
//- Draw objects  ---------------------------------------------------+
void drawObjetcs() {
      //--- high border range
      ObjectCreate(0, "rangeHigh", OBJ_TREND, 0, startRange, rangeHigh, now, rangeHigh);
      ObjectSetInteger(0, "rangeHigh", OBJPROP_HIDDEN, false );
      ObjectCreate(0, "rangeHigh next", OBJ_TREND, 0, now, rangeHigh, stopTime, rangeHigh);
      ObjectSetInteger(0, "rangeHigh next", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "rangeHigh next", OBJPROP_STYLE, STYLE_DOT );
      //text
      ObjectCreate(0, "range high text", OBJ_TEXT, 0, startRange, rangeHigh );
      ObjectSetString(0, "range high text", OBJPROP_TEXT, "range High");
      ObjectSetInteger(0, "range high text", OBJPROP_HIDDEN, false );
      
      //--- low border range
      ObjectCreate(0,"rangeLow", OBJ_TREND, 0, startRange, rangeLow, now, rangeLow);
      ObjectSetInteger(0, "rangeLow", OBJPROP_HIDDEN, false );
      ObjectCreate(0, "rangeLow next", OBJ_TREND, 0, now, rangeLow, stopTime, rangeLow);
      ObjectSetInteger(0, "rangeLow next", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "rangeLow next", OBJPROP_STYLE, STYLE_DOT );
      //text
      ObjectCreate(0, "range low text", OBJ_TEXT, 0, startRange, rangeLow);
      ObjectSetString(0, "range low text", OBJPROP_TEXT, "range Low");
      ObjectSetInteger(0, "range low text", OBJPROP_HIDDEN, false );      
      
      //--- trigger zone 
      //border up
      ObjectCreate(0, "price buy", OBJ_TREND, 0, startRange, rangeHigh-inpRatio*amplitude, stopTime, rangeHigh-inpRatio*amplitude);
      ObjectSetInteger(0, "price buy", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price buy", OBJPROP_COLOR, clrYellow );
      ObjectSetInteger( 0, "price buy", OBJPROP_STYLE, STYLE_DOT );
      //text   
      ObjectCreate(0, "price buy text", OBJ_TEXT, 0, startRange, rangeHigh-inpRatio*amplitude );
      ObjectSetString(0, "price buy text", OBJPROP_TEXT, "high trigger");
      ObjectSetInteger(0, "price buy text", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price buy text", OBJPROP_COLOR, clrYellow );
      //border down
      ObjectCreate(0, "price sell", OBJ_TREND, 0, startRange, rangeLow+inpRatio*amplitude, stopTime, rangeLow+inpRatio*amplitude);
      ObjectSetInteger(0, "price sell", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price sell", OBJPROP_COLOR, clrYellow );
      ObjectSetInteger( 0, "price sell", OBJPROP_STYLE, STYLE_DOT );
      //text   
      ObjectCreate(0, "price sell text", OBJ_TEXT, 0, startRange, rangeLow+inpRatio*amplitude);
      ObjectSetString(0, "price sell text", OBJPROP_TEXT, "low trigger");
      ObjectSetInteger(0, "price sell text", OBJPROP_HIDDEN, false );
      ObjectSetInteger( 0, "price sell text", OBJPROP_COLOR, clrYellow );
      
      //--- draw fibo 
      if(highCandle < lowCandle && highCandle != 0 && lowCandle != 0) {
         ObjectCreate(0, "fibo long", OBJ_FIBO, 0, iTime(Symbol(),PERIOD_M1,highCandle), rangeHigh, iTime(Symbol(),PERIOD_M1,lowCandle), rangeLow,
            clrRed, STYLE_DASHDOTDOT, 2, false, true, false, false);
                                         //arriereplan, surbrillance, prolong gauche, prolong droite
      }
      else if (highCandle > lowCandle && highCandle != 0 && lowCandle != 0) {
         ObjectCreate(0, "fibo long", OBJ_FIBO, 0, iTime(Symbol(),PERIOD_M1,lowCandle), rangeLow, iTime(Symbol(),PERIOD_M1,highCandle), rangeHigh);
      }
}

//+------------------------------------------------------------------+
//- New Day  --------------------------------------------------------+
bool IsNewDay()
  {
   static datetime previousDay = 0;
   datetime currentDay = StringToTime(StringSubstr(TimeToString(iTime(Symbol(),PERIOD_M1,0)),0,11));
   if(previousDay!=currentDay) {
      Print("new day");
      previousDay=currentDay;
      return true;
     }
   return false;  
  }  