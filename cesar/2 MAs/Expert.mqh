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

   CTimeFilter       *mTimeFilter;
   string            startTime;
   string            stopTime;
   
   CIndicatorMA      *mFastMA;
   CIndicatorMA      *mSlowMA;
   
   double             mStopLoss;
   double             mTakeProfit;

   int count[];

   void               Loop();
   int               OpenTrade( ENUM_ORDER_TYPE type, double sl, double tp);

public:
   CExpert( CIndicatorMA *fastMA, CIndicatorMA *slowMA,
            CTimeFilter *mTimeFilter,
            int stopLoss, int takeProfit,
            double volume, string tradeComment, int magic );
   ~CExpert();
};

//----------
CExpert::CExpert( CIndicatorMA *fastMA, CIndicatorMA *slowMA,
                  CTimeFilter *TimeFilter,
                  int stopLoss, int takeProfit,
                  double volume, string tradeComment, int magic )
   : CExpertBase( volume, tradeComment, magic ) {
//
   mFastMA      = fastMA; // on créé l'indicateur avec le pointeur
   mSlowMA      = slowMA;

   mTimeFilter = TimeFilter;

   mStopLoss     = stopLoss;
   mTakeProfit   = takeProfit;

   mTimeFilter.ValidateString();
   
   mInitResult   = INIT_SUCCEEDED;
}

//----------
CExpert::~CExpert() {

   delete mFastMA;
   delete mSlowMA;
}

//----------
void CExpert::Loop() {

   if ( !mNewBar ) return; // Only trades on open of a new bar

   //--- update indicators
   double mfastMA1 = mFastMA.GetData( 1 );
   double mSlowMA1 = mSlowMA.GetData( 1 );
   double mfastMA2 = mFastMA.GetData( 2 );
   double mSlowMA2 = mSlowMA.GetData( 2 );
   double closePrice = iClose( mSymbol, mTimeframe, 1 ); // last bar close price
   
   datetime now = TimeCurrent();
   mTimeFilter.isInsideRange(now);
   
   //--- count trades -> compter directement
   Trade.PositionCountByType(mSymbol, count);
   
   //--- open order condition
   if ( count[0] < 1 && mTimeFilter.isInsideRange(now) && mfastMA1 > mSlowMA1 && mfastMA2 < mSlowMA2 ) {
      OpenTrade( ORDER_TYPE_BUY, mStopLoss, mTakeProfit );
   }
   else if ( count[1] < 1 && mTimeFilter.isInsideRange(now) && mfastMA1 < mSlowMA1 && mfastMA2 > mSlowMA2 ) {
      OpenTrade( ORDER_TYPE_SELL, mStopLoss, mTakeProfit );
      
   }

   return;
}

//----------
int CExpert::OpenTrade( ENUM_ORDER_TYPE orderType, double stopLoss, double takeProfit ) {

   double openPrice;
   double stopLossPrice;
   double takeProfitPrice;

   //	Calculate the open price, take profit and stop loss prices based on the order type
   //
   if ( orderType == ORDER_TYPE_BUY ) {
      openPrice       = NormalizeDouble( SymbolInfoDouble( Symbol(), SYMBOL_ASK ), Digits() );
      stopLossPrice   = ( stopLoss == 0.0 ) ? 0.0 : NormalizeDouble( openPrice - mStopLoss, Digits() );
      takeProfitPrice = ( takeProfit == 0.0 ) ? 0.0 : NormalizeDouble( openPrice + mTakeProfit, Digits() );
   }
   else if ( orderType == ORDER_TYPE_SELL ) {
      openPrice       = NormalizeDouble( SymbolInfoDouble( Symbol(), SYMBOL_BID ), Digits() );
      stopLossPrice   = ( stopLoss == 0.0 ) ? 0.0 : NormalizeDouble( openPrice + mStopLoss, Digits() );
      takeProfitPrice = ( takeProfit == 0.0 ) ? 0.0 : NormalizeDouble( openPrice - mTakeProfit, Digits() );
   }
   else {
      //	This function only works with type buy or sell
      return ( -1 );
   }

   Trade.PositionOpen( Symbol(), orderType, mOrderSize, openPrice, stopLossPrice, takeProfitPrice, InpTradeComment );

   return ( ( int )Trade.ResultOrder() );
}

