//+------------------------------------------------------------------+
//|                                                    timeRange.mq5 |
//|                                                          cesreve |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "cesreve"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                                  |
//+------------------------------------------------------------------+
input long Inpmagic = 1;
input double Inplots = 0.1;

input int InpStopLoss = 150;
input int InpTakeProfit = 200;
input int rangeStart = 290;
input int rangeDuration = 210;
input int rangeClose = 1200;

//+------------------------------------------------------------------+
//| Global variables                                                                  |
//+------------------------------------------------------------------+
struct RANGE_STRUCT
  {
   datetime          start_time; // start of the range
   datetime          end_time; //end of the range
   datetime          close_time; // close time
   double            high; //high of the range
   double            low; // low of the range
   bool              f_entry; // flag if we are inside of the range
   bool              f_high_breakout; // flag if a high breakout occured
   bool              f_low_breakout; // flag if a low breakout occured

                     RANGE_STRUCT() : start_time(0), end_time(0), close_time(0), high(0), low(99999), f_entry(false), f_high_breakout(0), f_low_breakout(0) {};
  };

RANGE_STRUCT range;
MqlTick prevTick, lastTick;
CTrade trade;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(Inpmagic <= 0)
     {
      Alert("Magicnumber <= 0");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(Inplots <= 0 || Inplots> 1)
     {
      Alert("Lots <= 0 or > 1");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpStopLoss<0 || InpStopLoss>1000)
   {
      Alert("Altert Stop loss");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpTakeProfit<0 || InpTakeProfit>1000)
   {
      Alert("Altert take profit");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(rangeStart < 0 || rangeStart >= 1440)
     {
      Alert("Range start < 0 or >= 1440");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(rangeDuration <= 0 || rangeDuration>= 1440)
     {
      Alert("Range duration <= 0 or >= 1440");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(rangeClose < 0 || rangeClose >= 1440 || (rangeStart+rangeDuration) %1440 == rangeClose)
     {
      Alert("Close time < 0 or >= 1440 or end time == close time");
      return INIT_PARAMETERS_INCORRECT;
     }
//set magicnumber  
   trade.SetExpertMagicNumber(Inpmagic);   
     
// calculate new range if parameters changed
   if(_UninitReason==REASON_PARAMETERS) // no position open to add
     {
      CalculateRange();
     }

   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- delete objects
   ObjectsDeleteAll(NULL, "range");

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
// Get current tick
   prevTick = lastTick;
   SymbolInfoTick(_Symbol, lastTick);

// range calculation
   if(lastTick.time >= range.start_time && lastTick.time < range.end_time)
     {
      //flag
      range.f_entry = true;
      //new high
      if(lastTick.ask>range.high)
        {
         range.high = lastTick.ask;
         drawObjects();
        }
      //new low
      if(lastTick.ask<range.low)
        {
         range.low = lastTick.ask;
         drawObjects();
        }

     }// endif
     
     
// close positions
   if(lastTick.time >= range.close_time)
   {
      if(!ClosePositions()) {return;}
   } // end if
   
// calculate new range if...
   if((rangeClose >= 0 && lastTick.time >= range.close_time)  // close time reached
      || (range.f_high_breakout && range.f_low_breakout) // boths flags are true
      || (range.end_time==0) //range not calculated yet
      || (range.end_time != 0 && lastTick.time > range.end_time && !range.f_entry)   // there was a range calculated but no tick inside
      && (CountOpenPositions()==0) )
      //

     {
      CalculateRange();
     }
   // check for breakouts
   CheckBreakouts();

  } //end of Ontick
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void CalculateRange()
  {
   range.start_time = 0;
   range.end_time = 0;
   range.close_time = 0;
   range.high = 0.0;
   range.low = 9999;
   range.f_high_breakout = false;
   range.f_low_breakout = false;
   range.f_entry = false;

// calculate range start time
   int time_cycle = 86400;
   range.start_time = (lastTick.time - (lastTick.time % time_cycle)) + rangeStart*60;
   for(int i=0; i<8; i++)
     {
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      int dow = tmp.day_of_week;
      if(lastTick.time>=range.start_time || dow==6 || dow==0)
        {
         range.start_time+= time_cycle;
        }
     }

//calculate range end time
   range.end_time = range.start_time + rangeDuration*60;
   for(int i=0; i<2; i++)
     {
      MqlDateTime tmp;
      TimeToStruct(range.end_time, tmp);
      int dow = tmp.day_of_week;
      if(dow==6 || dow==0)
        {
         range.end_time += time_cycle;
        }
     }

// calculate range close
   range.close_time = (range.end_time - (range.end_time % time_cycle)) + rangeClose*60;
   for(int i=0; i<3; i++)
     {
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      int dow = tmp.day_of_week;
      if(range.close_time<=range.end_time|| dow==6 || dow==0)
        {
         range.close_time += time_cycle;
        }
     }
// draw objects
   drawObjects();

  } //end CalculateRange
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBreakouts() 
{
   //only if after the end of the range
   if(lastTick.time >= range.end_time && range.end_time>0 && range.f_entry)
   {
      // check for high breakout
      if(!range.f_high_breakout && lastTick.ask >= range.high)
      {
         range.f_high_breakout = true;
         
        
         // calculate stop loss and take profit
         double sl = NormalizeDouble(lastTick.bid - (range.high - range.low)*InpStopLoss*0.01, _Digits);
         double tp = InpTakeProfit == 0 ? 0 : NormalizeDouble(lastTick.bid + (range.high - range.low)*InpTakeProfit*0.01, _Digits);
         // open buy position
         trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, Inplots, lastTick.ask,sl,tp,"time range EA");
      }
      
      // check for low breakout
      if(!range.f_low_breakout && lastTick.bid <= range.low)
      {
         range.f_low_breakout = true;
         
         // calculate stop loss and take profit
         double sl = NormalizeDouble(lastTick.ask + (range.high - range.low)*InpStopLoss*0.01, _Digits);
         double tp = InpTakeProfit == 0 ? 0 : NormalizeDouble(lastTick.ask - (range.high - range.low)*InpTakeProfit*0.01, _Digits);
         
         // open sell position
         trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, Inplots, lastTick.bid,sl,tp, "time range EA");
      }
   } //end if
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int counter=0;
   int total = PositionsTotal();
   for(int i=total-1; i>0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0){Print("fail to get position ticket");}
      if(!PositionSelectByTicket(ticket)){Print("fail to select position by ticket"); return -1;}
      ulong magicnumber;
      if(!PositionGetInteger(POSITION_MAGIC,magicnumber)){Print("fail to ..."); return -1;}
      if(Inpmagic==magicnumber){counter++;}
     
   }
   return counter;
} //end countopenpositions


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ClosePositions()
{
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--) 
   {
      if(total != PositionsTotal()) {total=PositionsTotal(); i=total; continue;} // check if positions have not being closed by other EA at the same time
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {Print("failed");return false;}
      if(!PositionSelectByTicket(ticket)){Print("fail2");return false;}
      long magicnumber;
      if(!PositionGetInteger(POSITION_MAGIC, magicnumber)) {Print("fail3"); return false;}
      if(magicnumber==Inpmagic)
      {
         trade.PositionClose(ticket);
         if(trade.ResultRetcode()!=TRADE_RETCODE_DONE)
         {
            Print("failed"+(string)trade.ResultRetcode()+":"+trade.ResultRetcodeDescription());
            return false;
         }   
      }   
   }   
   
   return true;
} //end closepositions
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawObjects()
  {
//start
   ObjectDelete(NULL, "range start");
   if(range.start_time>0)
     {
      ObjectCreate(NULL, "range start", OBJ_VLINE, 0, range.start_time, 0);
      ObjectSetString(NULL, "range start", OBJPROP_TOOLTIP, "start of the range \n"+ TimeToString(range.start_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range start", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range start", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range start", OBJPROP_BACK, true);
     } //end if

//end time
   ObjectDelete(NULL, "range end");
   if(range.end_time>0)
     {
      ObjectCreate(NULL, "range end", OBJ_VLINE, 0, range.end_time, 0);
      ObjectSetString(NULL, "range end", OBJPROP_TOOLTIP, "end of the range \n"+ TimeToString(range.end_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range end", OBJPROP_COLOR, clrDarkBlue);
      ObjectSetInteger(NULL, "range end", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range end", OBJPROP_BACK, true);
     } //end if

//close time
   ObjectDelete(NULL, "range close");
   if(range.close_time>0)
     {
      ObjectCreate(NULL, "range close", OBJ_VLINE, 0, range.close_time, 0);
      ObjectSetString(NULL, "range close", OBJPROP_TOOLTIP, "close of the range \n"+ TimeToString(range.close_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range close", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(NULL, "range close", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range close", OBJPROP_BACK, true);
     } //end if

//range high
   ObjectsDeleteAll(NULL, "range high");
   if(range.high>0)
     {
      ObjectCreate(NULL, "range high", OBJ_TREND, 0, range.start_time, range.high, range.end_time, range.high);
      ObjectSetString(NULL, "range high", OBJPROP_TOOLTIP, "high of the range \n"+ DoubleToString(range.high,_Digits));
      ObjectSetInteger(NULL, "range high", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range high", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range high", OBJPROP_BACK, true);

      ObjectCreate(NULL, "range high ", OBJ_TREND, 0, range.end_time, range.high, range.close_time, range.high);
      ObjectSetString(NULL, "range high ", OBJPROP_TOOLTIP, "high of the range \n"+ DoubleToString(range.high,_Digits));
      ObjectSetInteger(NULL, "range high ", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range high ", OBJPROP_BACK, true);
      ObjectSetInteger(NULL, "range high ", OBJPROP_STYLE, STYLE_DASH);
     } //end if

//range low
   ObjectsDeleteAll(NULL, "range low");
   if(range.low<999999)
     {
      ObjectCreate(NULL, "range low", OBJ_TREND, 0, range.start_time, range.low, range.end_time, range.low);
      ObjectSetString(NULL, "range low", OBJPROP_TOOLTIP, "low of the range \n"+ DoubleToString(range.low,_Digits));
      ObjectSetInteger(NULL, "range low", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range low", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range low", OBJPROP_BACK, true);

      ObjectCreate(NULL, "range low ", OBJ_TREND, 0, range.end_time, range.low, range.close_time, range.low);
      ObjectSetString(NULL, "range low ", OBJPROP_TOOLTIP, "low of the range \n"+ DoubleToString(range.low,_Digits));
      ObjectSetInteger(NULL, "range low ", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range low ", OBJPROP_BACK, true);
      ObjectSetInteger(NULL, "range low ", OBJPROP_STYLE, STYLE_DASH);
     } //end if

  } // end function
//+------------------------------------------------------------------+
