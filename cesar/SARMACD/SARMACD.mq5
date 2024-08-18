#include <Orchard/Frameworks/Framework_3.06/Framework.mqh>

#include <Trade/Trade.mqh>

// Input parameters
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H4;  // Timeframe
input double InpLotSize = 0.1;                   // Lot size
input int InpMagicNumber = 123456;               // Magic number

// Indicator handles
int macdHandle;
int sarHandle;

// Global variables
CTrade trade;
string symbols[] = {"EURUSD", "GBPUSD"};
double takeProfitPips[2][2] = {{60, 200}, {70, 250}}; // [symbol][timeframe]

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize the trade object
    trade.SetExpertMagicNumber(InpMagicNumber);
    
    // Create indicator handles
    macdHandle = iMACD(_Symbol, InpTimeframe, 12, 26, 9, PRICE_CLOSE);
    sarHandle = iSAR(_Symbol, InpTimeframe, 0.02, 0.2);
    
    if (macdHandle == INVALID_HANDLE || sarHandle == INVALID_HANDLE)
    {
        Print("Failed to create indicator handles");
        return INIT_FAILED;
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    IndicatorRelease(macdHandle);
    IndicatorRelease(sarHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new bar
    if (!IsNewBar()) return;
    
    double macdMain[], macdSignal[], sarBuffer[];
    
    // Copy indicator data
    CopyBuffer(macdHandle, 0, 1, 2, macdMain);
    CopyBuffer(macdHandle, 1, 1, 2, macdSignal);
    CopyBuffer(sarHandle, 0, 1, 2, sarBuffer);
    
    // Check entry conditions
    if (sarBuffer[1] < SymbolInfoDouble(_Symbol, SYMBOL_BID) && macdMain[1] > 0)
    {
        // Buy condition
        double takeProfit = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + GetTakeProfit() * _Point;
        trade.Buy(InpLotSize, _Symbol, 0, 0, takeProfit, "SARMACD Buy");
    }
    else if (sarBuffer[1] > SymbolInfoDouble(_Symbol, SYMBOL_ASK) && macdMain[1] < 0)
    {
        // Sell condition
        double takeProfit = SymbolInfoDouble(_Symbol, SYMBOL_BID) - GetTakeProfit() * _Point;
        trade.Sell(InpLotSize, _Symbol, 0, 0, takeProfit, "SARMACD Sell");
    }
    
    // Check exit conditions
    if (macdMain[1] > macdSignal[1] && macdMain[0] <= macdSignal[0])
    {
        // MACD bearish cross
        CloseAllPositions();
    }
    else if (macdMain[1] < macdSignal[1] && macdMain[0] >= macdSignal[0])
    {
        // MACD bullish cross
        CloseAllPositions();
    }
}

//+------------------------------------------------------------------+
//| Check if it's a new bar                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, InpTimeframe, 0);
    
    if (currentBarTime != lastBarTime)
    {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Get take profit value based on symbol and timeframe              |
//+------------------------------------------------------------------+
double GetTakeProfit()
{
    int symbolIndex = -1;
    for (int i = 0; i < ArraySize(symbols); i++)
    {
        if (_Symbol == symbols[i])
        {
            symbolIndex = i;
            break;
        }
    }
    
    if (symbolIndex == -1) return 0;
    
    int timeframeIndex = (InpTimeframe == PERIOD_D1) ? 1 : 0;
    
    return takeProfitPips[symbolIndex][timeframeIndex];
}

//+------------------------------------------------------------------+
//| Close all open positions                                         |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            if (PositionGetString(POSITION_SYMBOL) == _Symbol && 
                PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
            {
                trade.PositionClose(ticket);
            }
        }
    }
}
