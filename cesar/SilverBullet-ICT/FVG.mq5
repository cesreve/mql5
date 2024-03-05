//+------------------------------------------------------------------+
//|                                                          FVG.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#include <trade/trade.mqh>

//+------------------------------------------------------------------+
class CFairValueGap : public CObject {
public:
   int direction; //up or dn
   datetime time;
   double high;
   double low;
   
   void draw(datetime timeStart, datetime timeEnd) {
      string objFvg = "SB FVG"+TimeToString(time);
      ObjectCreate(0, objFvg, OBJ_RECTANGLE, 0, time, low, timeStart, high);
      ObjectSetInteger(0, objFvg, OBJPROP_FILL, true);
      ObjectSetInteger(0, objFvg, OBJPROP_COLOR, clrLightGray);
      
      string objTrade = "SB Trade"+TimeToString(time);
      ObjectCreate(0, objTrade, OBJ_RECTANGLE, 0, timeStart, low, timeEnd, high);
      ObjectSetInteger(0, objTrade, OBJPROP_FILL, true);
      ObjectSetInteger(0, objTrade, OBJPROP_COLOR, clrGray);
   }
   
   void drawTradeLevels(double tp, double sl, datetime timeStart, datetime timeEnd) {
      string objTp = "SB TP" + TimeToString(time);
      ObjectCreate(0, objTp, OBJ_RECTANGLE, 0, timeStart, (direction > 0 ? high : low), timeEnd , tp);
      ObjectSetInteger(0, objTp, OBJPROP_FILL, true);
      ObjectSetInteger(0, objTp, OBJPROP_COLOR, clrLightGreen);
      
      string objSl = "SB SL" + TimeToString(time);
      ObjectCreate(0, objSl, OBJ_RECTANGLE, 0, timeStart, (direction > 0 ? high : low), timeEnd , sl);
      ObjectSetInteger(0, objSl, OBJPROP_FILL, true);
      ObjectSetInteger(0, objSl, OBJPROP_COLOR, clrOrange);
   }
};
//+------------------------------------------------------------------+
input double Lots = 0.1;
input double RiskPercent = 0.5;
input int MinTpPoints = 150;

input ENUM_TIMEFRAMES Timeframe = PERIOD_M5;
input int MinFvgPoints = 10;

input int TimeStartHour = 3;
input int TimeEndHour = 4;

CTrade trade;
CFairValueGap* fvg;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectsDeleteAll(0, "SB");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   static int lastDay = 0;
   
   MqlDateTime structTime;
   TimeCurrent(structTime);
   structTime.min = 0;
   structTime.sec = 0;
   
   structTime.hour = TimeStartHour;
   datetime timeStart = StructToTime(structTime);
   
   structTime.hour = TimeEndHour;
   datetime timeEnd = StructToTime(structTime);
   
//---
   if(TimeCurrent() >= timeStart && TimeCurrent() < timeEnd) {
      if(lastDay != structTime.day_of_year) {
         delete fvg;
         
         for(int i = 1; i < 100; i++) {
            if( (iLow(Symbol(), Timeframe, i) - iHigh(Symbol(), Timeframe, i+2) ) > MinFvgPoints*Point() ) { // fvg UP
               fvg = new CFairValueGap();
               fvg.direction = 1;
               fvg.time = iTime(Symbol(), Timeframe, i+1);
               fvg.high = iLow(Symbol(), Timeframe, i);
               fvg.low = iHigh(Symbol(), Timeframe, i+2);
            }
            
            if( (iLow(Symbol(), Timeframe, i+2) - iHigh(Symbol(), Timeframe, i) ) > MinFvgPoints*Point() ) { // fvg DN
               fvg = new CFairValueGap();
               fvg.direction = -1;
               fvg.time = iTime(Symbol(), Timeframe, i+1);
               fvg.high = iLow(Symbol(), Timeframe, i);
               fvg.low = iHigh(Symbol(), Timeframe, i+2);
            }
         }
      }
   }
  
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| indicator                                                        |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                          BHG.mq5 |
//|                                          Choppy Market Aspirator |
//+------------------------------------------------------------------+
//#property indicator_chart_window
//#property indicator_buffers 2
//#property indicator_plots 2
//
//#property indicator_label1 "FVG_UP"
//#property indicator_label2 "FVG_DN"
//
//
//#include <arrays/arrayobj.mqh>
////+------------------------------------------------------------------+
//enum ENUM_FVG_TYPE {
//   FVG_UP,
//   FVG_DN
//};
//
//class CFairValueGap : public CObject {
//public:
//   ENUM_FVG_TYPE type;
//   datetime time;
//   double high;
//   double low;
//   
//   void draw(datetime time2) {
//      string objName = "fvg"+TimeToString(time);
//      if(ObjectFind(0, objName) < 0) {
//         ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time, high, time2, low);
//         ObjectSetInteger(0, objName, OBJPROP_FILL, true);
//         ObjectSetInteger(0, objName, OBJPROP_COLOR, (type == FVG_UP ? clrLightBlue : clrOrange));
//      }
//      ObjectSetInteger(0, objName, OBJPROP_TIME, 1, time2);
//   }
//};
////--- inputs
//input int FvgMinPoints = 1;
//input int FvgMaxPoints = 100000000;
//input int FvgMaxLength = 20;
//
//CArrayObj gaps;
//
//double fvgHigh[];
//double fvgLow[];
//
//
////+------------------------------------------------------------------+
////| Custom indicator initialization function                         |
////+------------------------------------------------------------------+
//int OnInit()
//  {
////--- 
//   SetIndexBuffer(0, fvgHigh, INDICATOR_DATA);
//   SetIndexBuffer(1, fvgLow, INDICATOR_DATA);
//   
//   ArraySetAsSeries(fvgHigh, true);
//   ArraySetAsSeries(fvgLow, true);  
//   
////---
//   return(INIT_SUCCEEDED);
//   
//  }
////+------------------------------------------------------------------+
////| Custom indicator de-initialization function                      |
////+------------------------------------------------------------------+
//void OnDeinit(const int reason) {
//   ObjectsDeleteAll(0,"fvg");
//}
//
////+------------------------------------------------------------------+
////| Custom indicator iteration function                              |
////+------------------------------------------------------------------+
//int OnCalculate(const int rates_total,
//                const int prev_calculated,
//                const datetime &time[],
//                const double &open[],
//                const double &high[],
//                const double &low[],
//                const double &close[],
//                const long &tick_volume[],
//                const long &volume[],
//                const int &spread[]) {
//
//   ArraySetAsSeries(time, true);
//   ArraySetAsSeries(high, true);
//   ArraySetAsSeries(low, true);
//   
////---
//   int limit = rates_total - prev_calculated;
//   if(limit > rates_total - 2) limit = rates_total - 3;
//   
//   for(int i = limit; i>= 1; i--) {
//      
//      bool isFvgUp = (low[i] - high[i+2] > FvgMinPoints * _Point && low[i] - high[i+2]< FvgMaxPoints * _Point);
//      bool isFvgDn = (low[i+2] - high[i] > FvgMinPoints * _Point && low[i+2] - high[i] < FvgMaxPoints * _Point);
//      
//      if(isFvgUp || isFvgDn) {
//         CFairValueGap* fvg = new CFairValueGap();
//         fvg.type = isFvgUp ? FVG_UP : FVG_DN;
//         fvg.time = time[i+1]; //time[i+2];
//         fvg.high = isFvgUp ? low[i] : low[i+2];
//         fvg.low = isFvgUp ? high[i+2] : high[i];
//         
//         //fvg.draw(time[i] + PeriodSeconds(PERIOD_CURRENT)*FvgMaxLength);
//         
//         gaps.Add(fvg);
//         
//         fvgHigh[i+1] = fvg.high;
//         fvgLow[i+1] = fvg.low;
//      }
//      
//      for(int j = gaps.Total()-1; j >= 0; j--) {
//         CFairValueGap* fvg = gaps.At(j);
//         
//         fvg.draw(time[i]);
//         if(time[i] > fvg.time + PeriodSeconds(PERIOD_CURRENT) * FvgMaxLength) gaps.Delete(j);
//         else if(fvg.type == FVG_UP && low[i] <= fvg.low) gaps.Delete(j);
//         else if(fvg.type == FVG_DN && high[i] >= fvg.high) gaps.Delete(j);
//         //else fvg.draw(time[i]);
//      }
//      
//      
//   }
//  
////--- return value of prev_calculated for next call
//   return(rates_total);
//  }


