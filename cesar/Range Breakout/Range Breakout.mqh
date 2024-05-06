#define APP_COPYRIGHT "Copyright 2022, cesreve"
#define APP_LINK      "backtestedbots.com"
#define APP_VERSION   "1.00"
#define APP_DESCRIPTION                                                                            \
   "A range Breakout expert"
#define APP_COMMENT "Range Breakout"
#define APP_MAGIC   222222

#include "Framework.mqh"

//	Inputs

//	RSI specification
input int                InpRSIPeriod       = 10;          //	RSI period
input ENUM_APPLIED_PRICE InpRSIAppliedPrice = PRICE_CLOSE; // RSI applied price
input double             InpRSIBuyLevel     = 50;          // Buy above level
input double             InpRSISellLevel    = 50;          // Sell below level
input double             InpTPSLRatio       = 1.5;         // TPSL ratio

//	Default inputs
//	I have these in a separate file because I use them all the time
#include <Orchard/Shared/Default Inputs.mqh>

//	The expert does all the work
#include "Expert.mqh"
CExpert *Expert;

//
int      OnInit() {

   Expert =
      new CExpert( new CIndicatorRSI( InpRSIPeriod, InpRSIAppliedPrice ), // RSI
                        new CIndicatorFractal(),                               // Fractal
                        InpRSIBuyLevel, InpRSISellLevel, InpTPSLRatio, // Various params and TP/SL ratio
                        InpVolume, InpTradeComment, InpMagic           //	Common
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

//
