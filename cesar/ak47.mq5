
//+------------------------------------------------------------------+
//|                                                     AK-47 EA.mq5 |
//|                           Copyright 2023, Hung_tthanh@yahoo.com. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Hung_tthanh@yahoo.com."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define ExtBotName "AK-47 EA" //Bot Name
#define  Version "1.00"

//Import inputal class
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- introduce predefined variables for code readability
#define Ask    SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define Bid    SymbolInfoDouble(_Symbol, SYMBOL_BID)

//--- input parameters
input string  EASettings         = "---------------------------------------------"; //-------- <EA Settings> --------
input int      InpMagicNumber    = 124656;   //Magic Number
input string  MoneySettings      = "---------------------------------------------"; //-------- <Money Settings> --------
input bool     isVolume_Percent  = true;     //Allow Volume Percent
input double   InpRisk           = 3;        //Risk Percentage of Balance (%)
input string  TradingSettings    = "---------------------------------------------"; //-------- <Trading Settings> --------
input double   Inpuser_lot       = 0.01;     //Lots
input double   InpSL_Pips        = 3.5;      //Stoploss (in Pips)
input double   InpTP_Pips        = 7;        //TP (in Pips) (0 = No TP)
input int      InpMax_slippage   = 3;        //Maximum slippage allow_Pips.
input double   InpMax_spread     = 5;        //Maximum allowed spread (in Point) (0 = floating)
input string   TimeSettings      = "---------------------------------------------"; //-------- <Trading Time Settings> --------
input bool     InpTimeFilter     = true;     //Trading Time Filter
input int      InpStartHour      = 2;        //Start Hour
input int      InpStartMinute    = 30;       //Start Minute
input int      InpEndHour        = 21;       //End Hour
input int      InpEndMinute      = 0;        //End Minute

//--- Variables
int      Pips2Points;    // slippage  3 pips    3=points    30=points
double   Pips2Double;    // Stoploss 15 pips    0.015      0.0150
bool     isOrder = false;
int      slippage;
long     acSpread;
string   strComment = "";

CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
COrderInfo     m_order;                      // pending orders object

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   //3 or 5 digits detection
   //Pip and point
   if(_Digits % 2 == 1) {
      Pips2Double  = _Point*10;
      Pips2Points  = 10;
      slippage = 10* InpMax_slippage;
   }
   else {
      Pips2Double  = _Point;
      Pips2Points  =  1;
      slippage = InpMax_slippage;
   }
    
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
      
   RefreshRates();
//---
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(slippage);
//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
  
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

   if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false) {
      Comment("LazyBot\nTrade not allowed.");
      return;
   }
    
   MqlDateTime structTime;
   TimeCurrent(structTime);
   structTime.sec = 0;
  
   //Set starting time
   structTime.hour = InpStartHour;
   structTime.min = InpStartMinute;      
   datetime timeStart = StructToTime(structTime);
  
   //Set Ending time
   structTime.hour = InpEndHour;
   structTime.min = InpEndMinute;
   datetime timeEnd = StructToTime(structTime);
  
   acSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
  
  
   strComment = "\n" + ExtBotName + " - v." + (string)Version;
   strComment += "\nSever time = " + TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS) + " - " + DayOfWeekDescription(structTime.day_of_week);
   strComment += "\nTrading time = [" + (string)InpStartHour + "h" + (string)InpStartMinute + " --> " +  (string)InpEndHour + "h" + (string)InpEndMinute + "]";
  
   strComment += "\nCurrent Spread = " + (string)acSpread + " Points";
  
   Comment(strComment);
  
   //Update Values
   UpdateOrders();
  
   TrailingStop();
      
   //Dieu kien giao dich theo phien My
   if(InpTimeFilter) {
      if(TimeCurrent() >= timeStart && TimeCurrent() < timeEnd) {
         if(!isOrder) OpenOrder();
      }
   }
   else {
      if(!isOrder) OpenOrder();
   }
  
} //---End fuction

//+------------------------------------------------------------------+
//| CALCULATE SIGNAL AND SEND ORDER                                  |
//+------------------------------------------------------------------+
void OpenOrder(){
  
   ENUM_ORDER_TYPE OrdType = ORDER_TYPE_SELL;//-1;
  
   double TP = 0;
   double SL = 0;
   string comment = ExtBotName;
  
   //Calculate Lots
   double lot1 = CalculateVolume();
  
   if(OrdType == ORDER_TYPE_SELL) {
      double OpenPrice = Bid - NormalizeDouble(InpSL_Pips/2 * Pips2Double, _Digits);
      
      TP = OpenPrice - NormalizeDouble(InpTP_Pips * Pips2Double, _Digits);
      SL = Ask + NormalizeDouble(InpSL_Pips/2 * Pips2Double, _Digits);
        
      if(CheckSpreadAllow()                                             //Check Spread
         && CheckVolumeValue(lot1)                                      //Check volume
         && CheckOrderForFREEZE_LEVEL(ORDER_TYPE_SELL_STOP, OpenPrice)  //Check Dist from openPrice to Bid
         && CheckStopLoss(OpenPrice,  SL, TP)                           //Check Dist from SL, TP to OpenPrice
         && CheckMoneyForTrade(m_symbol.Name(), lot1, ORDER_TYPE_SELL)) //Check Balance khi lenh cho duoc Hit
      {
         if(!m_trade.SellStop(lot1, OpenPrice, m_symbol.Name(), SL, TP, ORDER_TIME_GTC, 0, comment))
         Print(__FUNCTION__,"--> OrderSend error ", m_trade.ResultComment());
      }
   }
   else if(OrdType == ORDER_TYPE_BUY) {
      double OpenPrice = Ask + NormalizeDouble(InpSL_Pips/2 * Pips2Double, _Digits);
      SL = Bid - NormalizeDouble(InpSL_Pips/2 * Pips2Double, _Digits);
      
      if(CheckSpreadAllow()                                             //Check Spread
         && CheckVolumeValue(lot1)                                      //Check volume
         && CheckOrderForFREEZE_LEVEL(ORDER_TYPE_BUY_STOP, OpenPrice)   //Check Dist from openPrice to Bid
         && CheckStopLoss(OpenPrice,  SL, TP)                           //Check Dist from SL, TP to OpenPrice        
         && CheckMoneyForTrade(m_symbol.Name(), lot1, ORDER_TYPE_BUY))  //Check Balance khi lenh cho duoc Hit
      {
         if(!m_trade.BuyStop(lot1, OpenPrice, m_symbol.Name(), SL, TP, ORDER_TIME_GTC, 0, comment))// use "ORDER_TIME_GTC" when expiration date = 0
         Print(__FUNCTION__,"--> OrderSend error ", m_trade.ResultComment());
      }
   }
  
}
//+------------------------------------------------------------------+
//| TRAILING STOP                                                    |
//+------------------------------------------------------------------+
void TrailingStop() {

   double SL_in_Pip = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) {    // selects the orders by index for further access to its properties        
         if((m_position.Magic() == InpMagicNumber) && (m_position.Symbol() == m_symbol.Name())) {
            // For Buy oder
            if(m_position.PositionType() == POSITION_TYPE_BUY) {
               //--Calculate SL when price changed
               SL_in_Pip = NormalizeDouble(Bid - m_position.StopLoss(), _Digits) / Pips2Double;
               if(SL_in_Pip > InpSL_Pips) {
                  double newSL = NormalizeDouble(Bid - InpSL_Pips * Pips2Double, _Digits);
                  
                  if(!m_trade.PositionModify(m_position.Ticket(), newSL, m_position.TakeProfit())) {
                     Print(__FUNCTION__,"--> OrderModify error ", m_trade.ResultComment());
                     continue;  
                  }
               }
            }

            //For Sell Order
            else if(m_position.PositionType() == POSITION_TYPE_SELL) {
               //--Calculate SL when price changed
               SL_in_Pip = NormalizeDouble(m_position.StopLoss() - Bid, _Digits) / Pips2Double;
               if(SL_in_Pip > InpSL_Pips){
                  double newSL = NormalizeDouble(Bid + (InpSL_Pips) * Pips2Double, _Digits);
                  if(!m_trade.PositionModify(m_position.Ticket(), newSL, m_position.TakeProfit())) {
                     Print(__FUNCTION__,"--> OrderModify error ", m_trade.ResultComment());
                     //continue;  
                  }
               }
            }
         }
      }
   }
  
   //--- Modify pending order  
   for(int i=OrdersTotal()-1; i>=0; i--) {// returns the number of current orders
      if(m_order.SelectByIndex(i)) {      // selects the pending order by index for further access to its properties
         if(m_order.Symbol() == m_symbol.Name() && m_order.Magic()==InpMagicNumber) {
            if(m_order.OrderType() == ORDER_TYPE_BUY_STOP) {
               SL_in_Pip = NormalizeDouble(Bid - m_order.StopLoss(), _Digits) / Pips2Double;
                  
               if(SL_in_Pip < InpSL_Pips/2) {
                  double newOP = NormalizeDouble(Bid + (InpSL_Pips/2) * Pips2Double, _Digits);
                  double newTP =  NormalizeDouble(newOP + InpTP_Pips * Pips2Double, _Digits);
                  double newSL = NormalizeDouble(Bid - (InpSL_Pips/2) * Pips2Double, _Digits);                  
                  
                  if(!m_trade.OrderModify(m_order.Ticket(), newOP, newSL, newTP, ORDER_TIME_GTC,0)) {
                     Print(__FUNCTION__,"--> Modify PendingOrder error!", m_trade.ResultComment());
                     continue;  
                  }              
               }
            }
            else if(m_order.OrderType() == ORDER_TYPE_SELL_STOP) {
               SL_in_Pip = NormalizeDouble(m_order.StopLoss() - Ask, _Digits) / Pips2Double;
              
               if(SL_in_Pip < InpSL_Pips/2){
                  double newOP = NormalizeDouble(Ask - (InpSL_Pips/2) * Pips2Double, _Digits);
                  double newTP =  NormalizeDouble(newOP - InpTP_Pips * Pips2Double, _Digits);
                  double newSL = NormalizeDouble(Ask + (InpSL_Pips/2) * Pips2Double, _Digits);
                  
                  if(!m_trade.OrderModify(m_order.Ticket(), newOP, newSL, newTP, ORDER_TIME_GTC,0)) {
                     Print(__FUNCTION__,"--> Modify PendingOrder error!", m_trade.ResultComment());
                     //continue;  
                  }              
               }
            }
            
         }
      }
    }    
}

// ------------------------------------------------------------------------------------------------
// UPDATE ORDERS
// ------------------------------------------------------------------------------------------------
void UpdateOrders() {

   isOrder = false;
  
   for(int i = PositionsTotal() - 1; i >= 0; i--) {        
      if(m_position.SelectByIndex(i)) {    // selects the orders by index for further access to its properties
         isOrder = true;
      }
   }
  
   for(int i=OrdersTotal()-1;i>=0;i--) {// returns the number of current orders
      if(m_order.SelectByIndex(i)) {    // selects the pending order by index for further access to its properties
         if(m_order.Symbol() == m_symbol.Name() && m_order.Magic()==InpMagicNumber) {
            isOrder = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| CALCULATE VOLUME                                                 |
//+------------------------------------------------------------------+
// We define the function to calculate the position size and return the lot to order.
double CalculateVolume() {

   double LotSize = 0;

   if(isVolume_Percent == false) {
      LotSize = Inpuser_lot;
     }
   else {
      LotSize = (InpRisk) * m_account.FreeMargin();
      LotSize = LotSize /100000;
      double n = MathFloor(LotSize/Inpuser_lot);
      //Comment((string)n);
      LotSize = n * Inpuser_lot;
      
      if(LotSize < Inpuser_lot)
         LotSize = Inpuser_lot;

      if(LotSize > m_symbol.LotsMax()) LotSize = m_symbol.LotsMax();

      if(LotSize < m_symbol.LotsMin()) LotSize = m_symbol.LotsMin();
   }
    
//---
   return(LotSize);
}


//+------------------------------------------------------------------+
//| CHECK ST AND TP                                                  |
//+------------------------------------------------------------------+
bool CheckStopLoss_Takeprofit(ENUM_ORDER_TYPE type,double price, double SL)
{
//--- get the SYMBOL_TRADE_STOPS_LEVEL level
   int stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level!=0)
     {
         PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must"+
            " not be nearer than %d points from the closing price",stops_level,stops_level);
     }
    
     int freeze_level = (int)SymbolInfoInteger(_Symbol,  SYMBOL_TRADE_FREEZE_LEVEL);
//---
   bool SL_check=false,TP_check=false, check = false;
//--- check only two order types
   switch(type)
     {
         //--- Buy operation
         case ORDER_TYPE_BUY_STOP:
         {
         //--- check the StopLoss
         //   SL_check=(Bid-SL>stops_level*_Point);
         //if(!SL_check)
         //   PrintFormat("For order %s StopLoss=%.5f must be less than %.5f"+
         //               " (Bid=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
         //               EnumToString(type),SL,Bid-stops_level*_Point,Bid,stops_level);
                        
        //--- check the distance from the opening price to the activation price
        check = ((price-Ask) > freeze_level*_Point);
            //--- return the result of checking
         return(check);
         }
      //--- Sell operation
      case ORDER_TYPE_SELL_STOP:
         {
         //--- check the StopLoss
      //   SL_check = (SL-Ask>stops_level*_Point);
      //if(!SL_check)
      //      PrintFormat("For order %s StopLoss=%.5f must be greater than %.5f "+
      //      " (Ask=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
      //         EnumToString(type),SL,Ask+stops_level*_Point,Ask,stops_level);
         //--- check the distance from the opening price to the activation price
            check = ((Bid-price)>freeze_level*_Point);

         //--- return the result of checking
         return(check);
}
         break;
     }
//--- a slightly different function is required for pending orders
   return false;
   }
  
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume)//,string &description)
{
//--- minimal allowed volume for trade operations
  double min_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(volume < min_volume)
     {
      //description = StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      //description = StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   int ratio = (int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      //description = StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f", volume_step,ratio*volume_step);
      return(false);
     }
    
//--- check volume limit
//   double limit_volume= SymbolInfoDouble (_Symbol, SYMBOL_VOLUME_LIMIT);
//
//   if (limit_volume> 0 && limit_volume - AllVolumes - volume <= 0)
//      {
//         //PrintFormat("%.2f - %.2f",max_volume , dlot);
//         return false ;
//      }
      
   //description="Correct volume value";
   return(true);
}


//+------------------------------------------------------------------+
//| CHECK ST AND TP                                                  |
//+------------------------------------------------------------------+
bool CheckOrderForFREEZE_LEVEL(ENUM_ORDER_TYPE type, double price)
{
   int freeze_level = (int)SymbolInfoInteger(_Symbol,  SYMBOL_TRADE_FREEZE_LEVEL);//MarketInfo(Symbol(),MODE_FREEZELEVEL);
   int stop_level = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
  
   bool check = false;
  
//--- check only two order types
   switch(type)
     {
      //--- Buy operation
      case ORDER_TYPE_BUY_STOP:
      {
         //--- check the distance from the opening price to the activation price
         check = ((price-Ask) > MathMax(freeze_level, stop_level) *_Point);
         //--- return the result of checking
         return(check);
      }
      //--- Sell operation
      case ORDER_TYPE_SELL_STOP:
      {
         //--- check the distance from the opening price to the activation price
         check = ((Bid-price) > MathMax(freeze_level, stop_level) * _Point);

         //--- return the result of checking
         return(check);
      }
      break;
     }
//--- a slightly different function is required for pending orders
   return false;
}
  
//+------------------------------------------------------------------+
//| CHECK MONEY FOR TRADE                                            |
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type) {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      Print("Error in ",__FUNCTION__," code=",m_trade.ResultComment());
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",m_trade.ResultComment());
      return(false);
     }
   //--- checking successful
   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckSpreadAllow() {

   if(InpMax_spread != 0) {
      if(acSpread > InpMax_spread) {
         Print(__FUNCTION__," > current Spread = " + (string)acSpread + " > greater than user Spread!...");
         return false;
      }
   }
  
   return true;
}

//+------------------------------------------------------------------+
//|CHECK SL AND TP FOR PENDING ORDER                                 |
//+------------------------------------------------------------------+

bool CheckStopLoss(double price, double SL, double TP)
{
//--- get the SYMBOL_TRADE_STOPS_LEVEL level
   int stops_level = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level != 0)
     {
      PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must"+
                  " not be nearer than %d points from the closing price", stops_level, stops_level);
     }
//---
   bool SL_check = true;
   bool TP_check = true;
  
   if(SL != 0)
   {
      //--- check the StopLoss
      SL_check = MathAbs(price - SL) > (stops_level * _Point);
   }
  
   if(TP != 0)
   {
      //--- check the Takeprofit
      TP_check = MathAbs(price - TP) > (stops_level * _Point);
   }
      //--- return the result of checking
      return(TP_check&&SL_check);  
}

//+------------------------------------------------------------------+
//| Day Of Week Description                                          |
//+------------------------------------------------------------------+
string DayOfWeekDescription(const int day_of_week)
  {
   string text="";
   switch(day_of_week)
     {
      case  0:
         text="Sunday";
         break;
      case  1:
         text="Monday";
         break;
      case  2:
         text="Tuesday";
         break;
      case  3:
         text="Wednesday";
         break;
      case  4:
         text="Thursday";
         break;
      case  5:
         text="Friday";
         break;
      case  6:
         text="Saturday";
         break;
      default:
         text="Another day";
         break;
     }
//---
   return(text);
}
  
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(Ask==0 || Bid==0)
      return(false);
//---
   return(true);
  }
