//+------------------------------------------------------------------+
//|                                              TurtleSoupEA.mq5    |
//|                        Copyright 2024, Your Name                 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.02"
#property strict
#include <Trade\Trade.mqh>
CTrade trade;
// Input parameters
input int      FastEMAPeriod = 10;     // Fast EMA period
input int      SlowEMAPeriod = 20;     // Slow EMA period
input int      ATRPeriod     = 20;     // ATR period for stop loss calculation
input double   ATRMultiplier = 3.0;    // ATR multiplier for stop loss
input int      MagicNumber   = 12345;  // Magic number for this EA
input double   RiskAmount    = 100.0;  // Risk amount in account currency

// Global variables
int handle_fast_ema, handle_slow_ema, handle_atr;
datetime last_bar_time;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize indicator handles
    handle_fast_ema = iMA(_Symbol, PERIOD_M30, FastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
    handle_slow_ema = iMA(_Symbol, PERIOD_M30, SlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
    handle_atr = iATR(_Symbol, PERIOD_M30, ATRPeriod);
    
    if(handle_fast_ema == INVALID_HANDLE || handle_slow_ema == INVALID_HANDLE || handle_atr == INVALID_HANDLE)
    {
        Print("Failed to create indicator handles");
        return INIT_FAILED;
    }
    
    // Set the magic number for the trade object
    trade.SetExpertMagicNumber(MagicNumber);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    IndicatorRelease(handle_fast_ema);
    IndicatorRelease(handle_slow_ema);
    IndicatorRelease(handle_atr);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if it's a new bar
    if(last_bar_time == iTime(_Symbol, PERIOD_M30, 0)) return;
    last_bar_time = iTime(_Symbol, PERIOD_M30, 0);
    
    // Check time filter and close positions if after 22:00
    datetime current_time = TimeCurrent();
    MqlDateTime time_struct;
    TimeToStruct(current_time, time_struct);
    
    if(time_struct.hour >= 22)
    {
        CloseAllPositions();
        return;
    }
    
    if(time_struct.hour < 6 || time_struct.hour >= 22) return;
    
    // Get indicator values
    double fast_ema[], slow_ema[], atr[];
    CopyBuffer(handle_fast_ema, 0, 0, 2, fast_ema);
    CopyBuffer(handle_slow_ema, 0, 0, 2, slow_ema);
    CopyBuffer(handle_atr, 0, 0, 1, atr);
    
    // Check for buy signal
    if(fast_ema[0] > slow_ema[0] && IsLowestLow(5))
    {
        double stop_loss = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (atr[0] * ATRMultiplier);
        double lot_size = CalculateLotSize(SymbolInfoDouble(_Symbol, SYMBOL_BID), stop_loss);
        OpenBuyPosition(stop_loss, lot_size);
    }
    
    // Check for sell signal
    if(fast_ema[0] < slow_ema[0] && IsHighestHigh(5))
    {
        double stop_loss = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + (atr[0] * ATRMultiplier);
        double lot_size = CalculateLotSize(SymbolInfoDouble(_Symbol, SYMBOL_ASK), stop_loss);
        OpenSellPosition(stop_loss, lot_size);
    }
    
    // Check for position closure
    CheckForPositionClosure();
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk amount                          |
//+------------------------------------------------------------------+
double CalculateLotSize(double entry_price, double stop_loss)
{
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lots_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    double risk_distance = MathAbs(entry_price - stop_loss);
    double tick_amount = risk_distance / tick_size;
    double value_per_lot = tick_amount * tick_value;

    double lots = NormalizeDouble(RiskAmount / value_per_lot, 2);

    // Ensure lot size is within allowed range
    double min_lots = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lots = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    lots = MathMax(lots, min_lots);
    lots = MathMin(lots, max_lots);

    // Round to nearest allowed lot step
    return NormalizeDouble(MathFloor(lots / lots_step) * lots_step, 2);
}

//+------------------------------------------------------------------+
//| Check if current bar is lowest low of last n bars                |
//+------------------------------------------------------------------+
bool IsLowestLow(int n)
{
    double low[];
    CopyLow(_Symbol, PERIOD_M30, 0, n, low);
    return low[0] == ArrayMinimum(low);
}

//+------------------------------------------------------------------+
//| Check if current bar is highest high of last n bars              |
//+------------------------------------------------------------------+
bool IsHighestHigh(int n)
{
    double high[];
    CopyHigh(_Symbol, PERIOD_M30, 0, n, high);
    return high[0] == ArrayMaximum(high);
}

//+------------------------------------------------------------------+
//| Open a buy position                                              |
//+------------------------------------------------------------------+
void OpenBuyPosition(double stop_loss, double lot_size)
{
    trade.Buy(lot_size, _Symbol, 0, stop_loss);
}

//+------------------------------------------------------------------+
//| Open a sell position                                             |
//+------------------------------------------------------------------+
void OpenSellPosition(double stop_loss, double lot_size)
{
    trade.Sell(lot_size, _Symbol, 0, stop_loss);
}

//+------------------------------------------------------------------+
//| Check for position closure                                       |
//+------------------------------------------------------------------+
void CheckForPositionClosure()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && IsHighestHigh(5))
                {
                    trade.PositionClose(PositionGetTicket(i));
                }
                else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && IsLowestLow(5))
                {
                    trade.PositionClose(PositionGetTicket(i));
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                trade.PositionClose(PositionGetTicket(i));
            }
        }
    }
}