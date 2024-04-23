/*
 * Strategy
 * Moving averages Cross over
 * Open position only between 9h00 and 13h00
 * Close on reverse signal or at the end of the day
 * TimeFrame M5
 */

#include "Framework.mqh"

class CExpert : public CExpertBase {

private:
protected:
// Definitions for compatibility
#ifdef __MQL4__
   #define UPPER_LINE MODE_UPPER
   #define LOWER_LINE MODE_LOWER
#endif

   CIndicatorMA      *mFastMA;
   CIndicatorMA      *mSlowMA;
   double             mFastMAPeriod;
   double             mSlowMAPeriod;
   
   double             mTPSLRatio;

   double             mBuyPrice;
   double             mBuySL;
   double             mSellPrice;
   double             mSellSL;

   void               Loop();
   void               OpenTrade( ENUM_ORDER_TYPE type, double sl );

public:
   CExpert( CIndicatorMA *fastMA, CIndicatorMA *slowMA,      //
            double buyLevel, double sellLevel, double tpslRatio, //
            double volume, string tradeComment, int magic );
   ~CExpert();
};

//
CExpert::CExpert( CIndicatorMA *fastMA, CIndicatorMA *slowMA,     //
                  double buyLevel, double sellLevel, double tpslRatio, //
                  double volume, string tradeComment, int magic )
   : CExpertBase( volume, tradeComment, magic ) {

   mFastMA      = fastMA;
   mSlowMA      = slowMA;

   mRSIBuyLevel  = buyLevel;
   mRSISellLevel = sellLevel;

   mBuyPrice     = 0;
   mSellPrice    = 0;

   mTPSLRatio    = tpslRatio;

   mInitResult   = INIT_SUCCEEDED;
}

//
CExpert::~CExpert() {

   delete mRSI;
   delete mFractal;
}

//
void CExpert::Loop() {

   if ( !mNewBar ) return; // Only trades on open of a new bar

   double mfastMA1 = mFastMA.GetData( 1 );
   double mSlowMA1 = mSlowMA.GetData( 1 );
   double mfastMA2 = mFastMA.GetData( 2 );
   double mSlowMA2 = mSlowMA.GetData( 2 );
   double closePrice = iClose( mSymbol, mTimeframe, 1 ); // last bar close price

   //if ( fractalHi != EMPTY_VALUE ) {
   //   mBuyPrice = fractalHi;
   //   mBuySL    = iLow( mSymbol, mTimeframe, 3 );
   //}
   //if ( fractalLo != EMPTY_VALUE ) {
   //   mSellPrice = fractalLo;
   //   mSellSL    = iHigh( mSymbol, mTimeframe, 3 );
   //}

   if ( mfastMA1 > mSlowMA1 && mfastMA2 < mSlowMA2 ) {
      OpenTrade( ORDER_TYPE_BUY, mBuyPrice - mBuySL );
      mBuyPrice = 0;
   }
   else if ( mfastMA1 > mSlowMA1 && mfastMA2 < mSlowMA2 ) {
      OpenTrade( ORDER_TYPE_SELL, mSellPrice - mSellSL );
      mSellPrice = 0;
   }

   return;
}

void CExpert::OpenTrade( ENUM_ORDER_TYPE type, double sl ) {

   double price   = ( type == ORDER_TYPE_BUY ) ? SymbolInfoDouble( mSymbol, SYMBOL_ASK )
                                               : SymbolInfoDouble( mSymbol, SYMBOL_BID );
   price          = NormalizeDouble( price, Digits() );
   double slPrice = NormalizeDouble( price - sl, Digits() );
   double tpPrice =
      NormalizeDouble( price + ( sl * mTPSLRatio ), Digits() ); //	Same for both buy and sell
   Trade.PositionOpen( mSymbol, type, mOrderSize, price, slPrice, tpPrice, mTradeComment );
}

//
