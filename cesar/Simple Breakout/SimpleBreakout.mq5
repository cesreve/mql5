#include <Orchard/Frameworks/Framework_3.06/Framework.mqh>

// Input parameters
input double InpLotSize = 0.1;  // Lot size for trading
input int InpMagicNumber = 123456;  // Magic number for trades
input int InpOpenHour = 5;  // Hour to start opening positions (0-23)
input int InpCloseHour = 22;  // Hour to close positions (0-23)
input double InpStopLossPercent = 1.0;  // Stop Loss percentage
input double InpTakeProfitPercent = 2.0;  // Take Profit percentage

// Stochastic indicator parameters
input int InpStochasticKPeriod = 5;  // Stochastic K period
input int InpStochasticDPeriod = 3;  // Stochastic D period
input int InpStochasticSlowing = 3;  // Stochastic slowing

// Global variables
CTradeCustom Trade;
datetime LastBarTime = 0;
double YesterdayHigh = 0;
double YesterdayLow = 0;
bool LongPositionOpened = false;
bool ShortPositionOpened = false;
CIndicatorStochastic* Stochastic = NULL;
double YesterdayStochasticMain = 0;
double YesterdayStochasticSignal = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set the magic number for the trade object
    Trade.SetExpertMagicNumber(InpMagicNumber);

    // Validate input
    if (InpCloseHour < 0 || InpCloseHour > 23) {
        Print("Invalid InpCloseHour. Please enter a value between 0 and 23.");
        return INIT_PARAMETERS_INCORRECT;
    }
    if (InpOpenHour < 0 || InpOpenHour > 23) {
        Print("Invalid InpOpenHour. Please enter a value between 0 and 23.");
        return INIT_PARAMETERS_INCORRECT;
    }
    if (InpStopLossPercent <= 0 || InpTakeProfitPercent <= 0) {
        Print("Invalid Stop Loss or Take Profit percentage. Please enter positive values.");
        return INIT_PARAMETERS_INCORRECT;
    }

    // Initialize Stochastic indicator with daily timeframe
    Stochastic = new CIndicatorStochastic(_Symbol, PERIOD_D1, InpStochasticKPeriod, InpStochasticDPeriod, InpStochasticSlowing, MODE_SMA, STO_LOWHIGH);
    if (Stochastic == NULL) {
        Print("Failed to create Stochastic indicator. Error code: ", GetLastError());
        return INIT_FAILED;
    }

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up any objects or resources if needed
    if (Stochastic != NULL) {
        delete Stochastic;
        Stochastic = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if it's a new day
    if (IsNewDay()) {
        // Update yesterday's high and low
        UpdateYesterdayHighLow();
        // Reset position flags
        LongPositionOpened = false;
        ShortPositionOpened = false;
        // Update yesterday's Stochastic values
        YesterdayStochasticMain = Stochastic.GetData(0, 1);
        YesterdayStochasticSignal = Stochastic.GetData(1, 1);
        
        // Display previous day's information in Comment
        string comment = StringFormat("Previous Day - High: %.5f, Low: %.5f\nStochastic Main: %.2f, Stochastic Signal: %.2f",
                                      YesterdayHigh, YesterdayLow, 
                                      YesterdayStochasticMain, YesterdayStochasticSignal);
        Comment(comment);
    }

    // Check if it's time to close positions
    if (IsCloseTime()) {
        CloseAllPositions();
    }
    else if (IsOpenTime()) {
        // Check for breakouts and open positions
        CheckAndOpenPositions();
    }
}

//+------------------------------------------------------------------+
//| Check if it's a new day                                          |
//+------------------------------------------------------------------+
bool IsNewDay()
{
    datetime currentBarTime = iTime(_Symbol, PERIOD_D1, 0);
    if (currentBarTime != LastBarTime) {
        LastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check if it's time to close positions                            |
//+------------------------------------------------------------------+
bool IsCloseTime()
{
    MqlDateTime now;
    TimeToStruct(TimeCurrent(), now);
    return (now.hour >= InpCloseHour);
}

//+------------------------------------------------------------------+
//| Check if it's time to open positions                             |
//+------------------------------------------------------------------+
bool IsOpenTime()
{
    MqlDateTime now;
    TimeToStruct(TimeCurrent(), now);
    return (now.hour >= InpOpenHour && now.hour < InpCloseHour);
}

//+------------------------------------------------------------------+
//| Update yesterday's high and low                                  |
//+------------------------------------------------------------------+
void UpdateYesterdayHighLow()
{
    YesterdayHigh = iHigh(_Symbol, PERIOD_D1, 1);
    YesterdayLow = iLow(_Symbol, PERIOD_D1, 1);
}

//+------------------------------------------------------------------+
//| Check for breakouts and open positions                           |
//+------------------------------------------------------------------+
void CheckAndOpenPositions()
{
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Calculate Stop Loss and Take Profit levels
    double stopLoss = NormalizeDouble(currentAsk * InpStopLossPercent / 100, _Digits);
    double takeProfit = NormalizeDouble(currentAsk * InpTakeProfitPercent / 100, _Digits);

    // Check for long position
    if (!LongPositionOpened && currentAsk > YesterdayHigh && !HasOpenPosition(POSITION_TYPE_BUY) && 
        YesterdayStochasticMain > YesterdayStochasticSignal) {
        double sl = NormalizeDouble(currentAsk - stopLoss, _Digits);
        double tp = NormalizeDouble(currentAsk + takeProfit, _Digits);
        if (Trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, currentAsk, sl, tp, __FILE__)) {
            LongPositionOpened = true;
        }
    }

    // Check for short position
    if (!ShortPositionOpened && currentBid < YesterdayLow && !HasOpenPosition(POSITION_TYPE_SELL) && 
        YesterdayStochasticMain < YesterdayStochasticSignal) {
        double sl = NormalizeDouble(currentBid + stopLoss, _Digits);
        double tp = NormalizeDouble(currentBid - takeProfit, _Digits);
        if (Trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, currentBid, sl, tp, __FILE__)) {
            ShortPositionOpened = true;
        }
    }
}

//+------------------------------------------------------------------+
//| Check if there's an open position of the specified type          |
//+------------------------------------------------------------------+
bool HasOpenPosition(ENUM_POSITION_TYPE positionType)
{
    int positionCounts[2];
    Trade.PositionCountByType(_Symbol, positionCounts);
    return positionCounts[positionType] > 0;
}

//+------------------------------------------------------------------+
//| Close all open positions                                         |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    Trade.PositionCloseByType(_Symbol, POSITION_TYPE_BUY);
    Trade.PositionCloseByType(_Symbol, POSITION_TYPE_SELL);
}