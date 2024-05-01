
#define APP_COPYRIGHT ""
#define APP_LINK      ""
#define APP_VERSION   "1.00"
#define APP_DESCRIPTION                                                                            \
   "A trend following expert based Moving averages crossover"
#define APP_COMMENT "2 MAs"
#define APP_MAGIC   147852369

#include "Framework.mqh"

//	Inputs

//	RSI specification
input int                InpFastMAPeriod       = 10;          //	Fast MA period
input int                InpSlowMAPeriod       = 20;          //	Slow MA period
input ENUM_APPLIED_PRICE InpMAAppliedPrice = PRICE_CLOSE;     // MA applied price
input ENUM_MA_METHOD     InpMAAppliedMethod = MODE_SMA;      // MA Smoothing Method

input string InpStartTime;
input string InpStopTime;

input int InpStopLoss = 35;
input int InpTakeProfit = 55;

//	Default inputs
//	I have these in a separate file because I use them all the time
#include <Orchard/Shared/Default Inputs.mqh>

//	The expert does all the work
#include "Expert.mqh"
CExpert *Expert;

//
int      OnInit() {

   Expert =
      new CExpert( new CIndicatorMA( InpFastMAPeriod, InpMAAppliedMethod, InpMAAppliedPrice), // Fast MA
                   new CIndicatorMA( InpSlowMAPeriod, InpMAAppliedMethod, InpMAAppliedPrice ), // Slow MA
                   new CTimeFilter(InpStartTime, InpStopTime), //timefilter
                   InpStopLoss, InpTakeProfit, // SL and TP in points
                   InpVolume, InpTradeComment, InpMagic                   //	Common
           );

   return ( Expert.OnInit() );
}

//
void OnDeinit( const int reason ) {
   delete Expert;
}

//
void OnTick() {
   Expert.OnTick();
}
