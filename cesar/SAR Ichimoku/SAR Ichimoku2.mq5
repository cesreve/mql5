//+------------------------------------------------------------------+
//|                                                 SAR Ichimoku.mq5 |
//|                                                                  |
//| EUROPE: 10h00 -> 18h29                                           |
//| USA:    16h30 -> 22h59                                           |
//| JAPON:  03h00 -> 08h59                                           |
//+------------------------------------------------------------------+
//--- TODO
//close en vecteur
//breakeven
//stop suiveur ou condition de fermeture sur close sous la Kijun
//multi ordres

//--- liste des bugs
//1er février 13h, devrait lancer un signal



#property copyright ""
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ====";
static input long InpMagicNumber = 04092023; 

input group "==== Indicators ====";
input int inpTenkanSen  = 9;  // Tekan Sen Period
input int inpKijunSen   = 26; // Kijun Sen Period
input int inpSenkouSpan = 52; // Senkou Span Period

input double inpSarStep          = 0.02; //price increment step - acceleration factor
input double inpSarMaximum       = 0.2; //maximum value of step 

input group "==== Trading ====";
input double inpLotSize             = 0.1;
input int inpStopLoss               = 700;
input int inpTakeProfit             = 700;
input int inpPipsTrailingStopLevel  = 350;
input int inpBreakevenTreshold      = 50;
input int inpTrendStrengh           = 30;
input bool inpCloseOnKijun          = false;

//--- trades inputs 
input group "==== Trading hours ====";
input int inpStartHour   = 13; // Start trading hour
input int inpStartMinute = 0;  // Start trading minute
input int inpStopHour    = 18; // Stop trading hour
input int inpStopMinute  = 45; // Stop trading minute
input int inpCloseHour   = 18; // Close all positions hour
input int inpCloseMinute = 45; // Close all positions minute
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;
int handleICHIMOKU;
int handleSAR;
MqlTick tick;
string comm="";
bool tradeAllowed = false;
bool closeOnKijun = inpCloseOnKijun;
double tenkan[];
double kijun[];
double sar[];
double close1;
double close2;
int trendStrengh = inpTrendStrengh;

int cntBuy  = 0;
int cntSell = 0;

int startHour   = inpStartHour;
int startMinute = inpStartMinute;
int stopHour    = inpStopHour;
int stopMinute  = inpStopMinute;
int closeHour   = inpCloseHour;
int closeMinute = inpCloseMinute;

datetime now;
datetime startTime = 0;
datetime stopTime  = 0;
datetime closeTime = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagicNumber); 
   
//--- create moving average hanlde
   handleICHIMOKU = iIchimoku(Symbol(), PERIOD_CURRENT, inpTenkanSen, inpKijunSen, inpSenkouSpan);
   if(handleICHIMOKU==INVALID_HANDLE)
     {
      Alert("Failed to create Ichimoku handle");
      return INIT_FAILED;
     }   
     
//--- create parabolic sar hanlde
   handleSAR = iSAR(Symbol(), PERIOD_CURRENT,inpSarStep,inpSarMaximum);
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
   ObjectsDeleteAll(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!IsNewbar()) return;
//--- compute indicators
   SAR();
   kijun();
   tenkan();
   close1 = iClose(Symbol(),PERIOD_CURRENT,1);
   close2 = iClose(Symbol(),PERIOD_CURRENT,2);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
//---
   comm = "";
   //comm += (string)tenkan[0];
   //comm += "\n";
   //comm += (string)tenkan[2];
   //comm += "\n";
   //comm += (string)tenkan[3];
   //comm += "\n";
   //comm += (string)kijun[1];
   //comm += "\n";
   //comm += (string)kijun[2];
   //comm += "\n";
   //comm += (string)kijun[3];
   //comm += "\n";
   //comm += (string)sar[2];
   comm += "\n";
   comm += (string)close2; 
   comm += "\n";
   //comm += (string)sar[1];     
   comm += "\n";
   comm += (string)close1;
   comm += "\n";
   //comm += (string)calculateGap(1);
   comm += "\n";
   //comm += (string)calculateGap(-1);
   comm += "\n";
   comm += (string)isSignal();
   comm += "\n";
   //comm += (string)close[3];
   //comm += (string)isSignal(-1);

   Comment(comm);
   if(isSignal() !=0) { Print("signal");}
//---
   CountOpenPositions();
   if(cntBuy+cntSell == 0) {
      if(isSignal() == 1.0 && calculateGap(1) >= 9 ) {
         Print("long");
         openPosition(ORDER_TYPE_BUY, ask, ask + 1.5*(ask-sar[1]), sar[1] );
      }
      else if(isSignal() == -1.0 && calculateGap(-1) >= 9 ) {
         Print("court");
         openPosition(ORDER_TYPE_SELL, bid, 0, 0 );
         //openPosition(ORDER_TYPE_SELL, bid, bid - 2*(sar[1] - bid), sar[1] );
      }       
   }
//---
   if(cntBuy+cntSell > 0) {
      //checkForClose();
   }
//--- close on kijun
   if(closeOnKijun) {
      closeOnKijun();
   }

  } // end of the OnTick() function)

////+------------------------------------------------------------------+
////+------------          CUSTOM FUNCTIONS               -------------+

////+------------------------------------------------------------------+
////- Open position   -------------------------------------------------+
void openPosition(ENUM_ORDER_TYPE direction, double price, double takeProfit, double stopLoss)
{
   if(direction == ORDER_TYPE_BUY) {
      trade.Buy(0.1, Symbol(),price, stopLoss, takeProfit, "SAR Ichimoku EA");
   }
   else if(direction == ORDER_TYPE_SELL) {
      trade.Sell(0.1, Symbol(),price, stopLoss, takeProfit, "SAR Ichimoku EA");  
   }
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
         if( MathAbs(priceCurrent-priceOpen) > MathAbs(priceCurrent - positionSL) ) {
            trade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_TP) );
         }         
      }
   }
   return true;
}
//+------------------------------------------------------------------+
// Kijun close signal   ---------------------------------------------+
bool closeOnKijun()
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
      long type;
      if(!PositionGetInteger(POSITION_TYPE, type)) {Print("Failed to get postion type"); return false;}
      if(magic==InpMagicNumber) {
         if(type == POSITION_TYPE_BUY) {
            if( close1 < kijun[1] ) {
               trade.PositionClose(ticket);
               if(trade.ResultRetcode()!=TRADE_RETCODE_DONE)
               {
                  Print("Failed to close position, ticket: ", (string)ticket, 
                        " result: ", (string)trade.ResultRetcode(), ": ", trade.CheckResultRetcodeDescription());
               }               
            }         
         }
         else if(type == POSITION_TYPE_SELL) {
            if( close1 > kijun[1] ) {
               trade.PositionClose(ticket);
               if(trade.ResultRetcode()!=TRADE_RETCODE_DONE)
               {
                  Print("Failed to close position, ticket: ", (string)ticket, 
                        " result: ", (string)trade.ResultRetcode(), ": ", trade.CheckResultRetcodeDescription());
               }               
            }         
         }
      }
   }   
   return true;
}
//+------------------------------------------------------------------+
// Signal   ---------------------------------------------------------+
double isSignal()
  {
   double signal=0;
// BUY
   if(   
      sar[2] > close2 // SAR 2 au dessus du price close 2     
      && sar[1] < close1 // SAR 1 au dessous du price close 1
      && tenkan[1] > kijun[1] // Tenkan 1 supérieure à Kijun 1
      //&& tenkan[1] > tenkan[2] // Tenkan 1 supérieure à Tenkan 2
     ) // fin du if
     {signal=1.0;}

// SELL
   else if(
         sar[2] < close2 // SAR 2 au dessous du price close 2
         && sar[1] > close1 // SAR 1 au dessus du price close 1
         && tenkan[1] <= kijun[1] // Tenkan 1 inférieure à Kijun 1
         //&& tenkan[1]  < tenkan[2] // Tenkan 1 inférieure à Tenkan 2
        ) //fin du else if
        {signal=-1.0;}
//return
   return signal;
  }
//+------------------------------------------------------------------+
//- Calculate trend counter   ---------------------------------------+
int calculateGap(double direction)
{
   int counter = 0;
   for(int i=1; i < trendStrengh-2; i++) {
      if( (tenkan[i]-kijun[i])*direction > 0 ) {         
         counter += 1;           
      }
      else break;
   }
   return counter;
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
   nowStruct.hour = startHour;
   nowStruct.min = startMinute;
   startTime = StructToTime(nowStruct);
   
   // stop time
   nowStruct.hour = stopHour;
   nowStruct.min = stopMinute;
   stopTime = StructToTime(nowStruct);
     
   // close time
   nowStruct.hour = closeHour;
   nowStruct.min = closeMinute;
   closeTime = StructToTime(nowStruct);
}
////+------------------------------------------------------------------+
////- New Bar  --------------------------------------------------------+
bool IsNewbar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(Symbol(), _Period, 0);
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
   int digits = 0;
   if(!SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)) {Print("Failed to get digits"); return false;}
   if(!SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE, tickSize)) {Print("Failed to get tick size"); return false;}
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,digits);
   
   return true;
}
//+------------------------------------------------------------------+
//- Parabolic SAR   -------------------------------------------------+
void SAR()
{
   ArraySetAsSeries(sar, true);
   if(CopyBuffer(handleSAR,0,0,3,sar)!=3) { Print("Failed to get iSAR values."); }
}
//+--------------------------------------------------------------------------------------------------------+
//| Tenkan   ----------------------------------------------------------------------------------------------+
void tenkan()
{
   ArraySetAsSeries(tenkan, true);
   if(CopyBuffer(handleICHIMOKU,0,0,trendStrengh,tenkan)!=trendStrengh ) { Print("Failed to get tenkan values."); }
}
//+--------------------------------------------------------------------------------------------------------+
//| Kijun   -----------------------------------------------------------------------------------------------+
void kijun()
{
   ArraySetAsSeries(kijun, true);
   if(CopyBuffer(handleICHIMOKU,1,0,trendStrengh, kijun)!=trendStrengh ) { Print("Failed to get kijun values."); }
}
//+--------------------------------------------------------------------------------------------------------+
//| Closing prices   --------------------------------------------------------------------------------------+
//void closes() 
//{
//   ArraySetAsSeries(close, true);
//   if(CopyClose(Symbol(), PERIOD_M1,0,3,close)!=3) { Print("Failed to get close prices"); }
//}
//+--------------------------------------------------------------------------------------------------------+
//| Ichimoku   --------------------------------------------------------------------------------------------+
//| 0 - TENKANSEN_LINE, 1 - KIJUNSEN_LINE, 2 - SENKOUSPANA_LINE, 3 - SENKOUSPANB_LINE, 4 - CHIKOUSPAN_LINE +
double getIchimoku(int line, int index, string symbol)
  {
   double IchimokuBuffer[];
   ArraySetAsSeries(IchimokuBuffer, true); 
   int Ichimoku;
   if((Ichimoku=iIchimoku(symbol, _Period, inpTenkanSen, inpKijunSen, 52))==INVALID_HANDLE)
     {
      Print("Error creating Ichimoku indicator for: ", symbol);
      return(false);
     }

   if(CopyBuffer(Ichimoku, line, index, 1, IchimokuBuffer))
     {
      if(ArraySize(IchimokuBuffer) > 0)
        {
         return IchimokuBuffer[0];
        }
     }
   return -1.0;
  }

//+----------------------   T H E    E N D   ------------------------+


