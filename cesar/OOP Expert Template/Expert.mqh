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

   bool               firstTradeAllowed;
   void               Loop();
   void               OpenTrade( ENUM_ORDER_TYPE type, double sl );

public:
   CExpert( CTimeFilter *mTimeFilter, 
            double volume, string tradeComment, int magic );
   ~CExpert();
};

//
CExpert::CExpert( CTimeFilter *TimeFilter,
                  double volume, string tradeComment, int magic )
   : CExpertBase( volume, tradeComment, magic ) {

   firstTradeAllowed = true;
   
   mTimeFilter = TimeFilter;
   
   mInitResult   = INIT_SUCCEEDED;
}

//
CExpert::~CExpert() {

}

//
void CExpert::Loop() {

   if ( !mNewBar ) return; // Only trades on open of a new bar

   datetime now = TimeCurrent();
   Print( mTimeFilter.isInsideRange(now) );
   Print( mTimeFilter.ValidateString() );
   
   if ( mTimeFilter.isInsideRange(now) && firstTradeAllowed ) {
      OpenTrade(ORDER_TYPE_BUY, 0);
      firstTradeAllowed = false;
   }
   
   return;
}

void CExpert::OpenTrade( ENUM_ORDER_TYPE type, double sl ) {

   double price   = ( type == ORDER_TYPE_BUY ) ? SymbolInfoDouble( mSymbol, SYMBOL_ASK )
                                               : SymbolInfoDouble( mSymbol, SYMBOL_BID );
   Trade.PositionOpen( mSymbol, type, mOrderSize, price, 0, 0, mTradeComment );
}

//
