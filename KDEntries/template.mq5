//+------------------------------------------------------------------+
//|                                                     Template.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Orchard/Frameworks/Framework_3.06/Framework.mqh>
CTradeCustom trade;
CTimeFilter* timeFilter;

//+------------------------------------------------------------------+
//| Enum for custom timeframe                                        |
//+------------------------------------------------------------------+
enum ENUM_CUSTOM_TIMEFRAME
{
    TIMEFRAME_M1 = PERIOD_M1,    // 1 minute
    TIMEFRAME_M2 = PERIOD_M2,    // 2 minutes
    TIMEFRAME_M3 = PERIOD_M3,    // 3 minutes
    TIMEFRAME_M4 = PERIOD_M4,    // 4 minutes
    TIMEFRAME_M5 = PERIOD_M5,    // 5 minutes
    TIMEFRAME_M6 = PERIOD_M6,    // 6 minutes
    TIMEFRAME_M10 = PERIOD_M10,  // 10 minutes
    TIMEFRAME_M12 = PERIOD_M12,  // 12 minutes
    TIMEFRAME_M15 = PERIOD_M15,  // 15 minutes
    TIMEFRAME_M20 = PERIOD_M20,  // 20 minutes
    TIMEFRAME_M30 = PERIOD_M30,  // 30 minutes
    TIMEFRAME_H1 = PERIOD_H1,    // 1 hour
    TIMEFRAME_H2 = PERIOD_H2,    // 2 hours
    TIMEFRAME_H3 = PERIOD_H3,    // 3 hours
    TIMEFRAME_H4 = PERIOD_H4,    // 4 hours
    TIMEFRAME_H6 = PERIOD_H6,    // 6 hours
    TIMEFRAME_H8 = PERIOD_H8,    // 8 hours
    TIMEFRAME_H12 = PERIOD_H12,  // 12 hours
    TIMEFRAME_D1 = PERIOD_D1,    // Daily
    TIMEFRAME_W1 = PERIOD_W1,    // Weekly
    TIMEFRAME_MN1 = PERIOD_MN1   // Monthly
};

//+------------------------------------------------------------------+
//| Enum for stop loss and take profit type                          |
//+------------------------------------------------------------------+
enum ENUM_SL_TP_TYPE
{
    SL_TP_PERCENT,    // Percent
    SL_TP_POINTS      // Points
};

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- General settings
input group "==== General Settings ===="
input int InpMagicNumber = 13112023;  // Magic Number
input ENUM_CUSTOM_TIMEFRAME InpTimeframe = TIMEFRAME_M15; // Timeframe

//--- Trading hours 
input group "==== Trading Hours ===="
input string InpStartTime = "10:00";  // Start trading time
input string InpStopTime = "18:00";   // Stop trading time
input string InpCloseTime = "22:55";  // Close all positions time (if close EOD)
input bool InpCloseAllAtEndOfDay = true; // Close all positions at end of day

//--- Trade parameters
input group "==== Trade Parameters ===="
input double InpLotSize = 0.1;  // Lot size
input ENUM_SL_TP_TYPE InpSLTPType = SL_TP_PERCENT; // Stop Loss and Take Profit Type
input double InpStopLoss = 1.0;  // Stop Loss (% or points)
input double InpTakeProfit = 1.0;  // Take Profit (% or points)

//--- Trade direction
input group "==== Trade Direction ===="
input bool InpAllowLongTrade = true;  // Allow long trades
input bool InpAllowShortTrade = true; // Allow short trades

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+ 
MqlTick tick;
datetime lastBarTime;
double lastClose;
int positionsCount[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);   
    
    timeFilter = new CTimeFilter(InpStartTime, InpStopTime);
    if (!timeFilter.ValidateString())
    {
        Print("Invalid time filter settings");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    lastBarTime = iTime(_Symbol, (ENUM_TIMEFRAMES)InpTimeframe, 0);
    lastClose = iClose(_Symbol, (ENUM_TIMEFRAMES)InpTimeframe, 1);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if (timeFilter != NULL)
    {
        delete timeFilter;
        timeFilter = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if it's time to close all positions
    datetime currentTime = TimeCurrent();
    datetime stopTime = StringToTime(InpCloseTime);
    
    if (InpCloseAllAtEndOfDay && currentTime >= stopTime)
    {
        CloseAllPositions();
        return;  // Exit the function after closing all positions
    }
    
    if (!timeFilter.isInsideRange(currentTime))
    {
        return;  // Outside trading hours, do nothing
    }
    
    // Check if a new bar has formed
    if (lastBarTime < iTime(_Symbol, (ENUM_TIMEFRAMES)InpTimeframe, 0))
    {
        lastBarTime = iTime(_Symbol, (ENUM_TIMEFRAMES)InpTimeframe, 0);
        
        double currentClose = iClose(_Symbol, (ENUM_TIMEFRAMES)InpTimeframe, 1);
        
        // Check for long entry
        if (InpAllowLongTrade && currentClose > lastClose)
        {
            trade.PositionCountByType(_Symbol, positionsCount);
            if (positionsCount[POSITION_TYPE_BUY] == 0)  // No open long positions for this expert
            {
                double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                double stopLoss, takeProfit;
                
                if (InpSLTPType == SL_TP_PERCENT)
                {
                    stopLoss = ask * (1 - InpStopLoss / 100);
                    takeProfit = ask * (1 + InpTakeProfit / 100);
                }
                else // SL_TP_POINTS
                {
                    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
                    stopLoss = ask - InpStopLoss * point;
                    takeProfit = ask + InpTakeProfit * point;
                }
                
                trade.Buy(InpLotSize, _Symbol, ask, stopLoss, takeProfit, "Long Entry");
            }
        }
        
        // Check for short entry
        if (InpAllowShortTrade && currentClose < lastClose)
        {
            trade.PositionCountByType(_Symbol, positionsCount);
            if (positionsCount[POSITION_TYPE_SELL] == 0)  // No open short positions for this expert
            {
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                double stopLoss, takeProfit;
                
                if (InpSLTPType == SL_TP_PERCENT)
                {
                    stopLoss = bid * (1 + InpStopLoss / 100);
                    takeProfit = bid * (1 - InpTakeProfit / 100);
                }
                else // SL_TP_POINTS
                {
                    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
                    stopLoss = bid + InpStopLoss * point;
                    takeProfit = bid - InpTakeProfit * point;
                }
                
                trade.Sell(InpLotSize, _Symbol, bid, stopLoss, takeProfit, "Short Entry");
            }
        }
        
        lastClose = currentClose;
    }
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
            if (PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
            {
                trade.PositionClose(ticket);
            }
        }
    }
}
//+-----------------    END OF ON TICK FUNCTION    ------------------+