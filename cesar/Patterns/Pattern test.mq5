#include <Orchard/Frameworks/Framework_3.06/Framework.mqh>

// Enum for pattern selection
enum ENUM_PATTERN {
    PATTERN_HIGHER_HIGH_CLOSE = 0, // Higher High Close
    PATTERN_LOWER_LOW_CLOSE = 1    // Lower Low Close
};

// Input parameters
input ENUM_PATTERN InpPattern = PATTERN_HIGHER_HIGH_CLOSE; // Pattern to trade
input int InpLookbackPeriod = 3;                           // Lookback period for pattern
input double InpLotSize = 0.1;                             // Lot size
input int InpMagicNumber = 123456;                         // Magic number

// Global variables
CPatterns *Pattern;
CTrade Trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize Pattern object
    Pattern = new CPatterns(_Symbol, PERIOD_CURRENT, InpLookbackPeriod);
    if (Pattern == NULL) {
        Print("Failed to create Pattern object");
        return INIT_FAILED;
    }

    // Set up trade object
    Trade.SetExpertMagicNumber(InpMagicNumber);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up
    if (Pattern != NULL) {
        delete Pattern;
        Pattern = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if we're already in a position
    if (PositionsTotal() > 0) return;

    // Check for the selected pattern
    bool patternDetected = false;
    
    if (InpPattern == PATTERN_HIGHER_HIGH_CLOSE) {
        patternDetected = Pattern.IsHigherHighClose();
    } else if (InpPattern == PATTERN_LOWER_LOW_CLOSE) {
        patternDetected = Pattern.IsLowerLowClose();
    }

    // If pattern is detected, open a position
    if (patternDetected) {
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        
        if (InpPattern == PATTERN_HIGHER_HIGH_CLOSE) {
            double stopLoss = ask * 0.01;
            double takeProfit = ask * 0.015;
            Trade.Buy(InpLotSize, _Symbol, ask, ask - stopLoss, ask + takeProfit, "Higher High Close Pattern");
        } else if (InpPattern == PATTERN_LOWER_LOW_CLOSE) {
            double stopLoss = bid * 0.01;
            double takeProfit = bid * 0.015;
            Trade.Sell(InpLotSize, _Symbol, bid, bid + stopLoss, bid - takeProfit, "Lower Low Close Pattern");
        }
    }
}
