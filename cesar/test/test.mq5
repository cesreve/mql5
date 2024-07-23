#property copyright "Your Name"
#property link      "https://www.yourwebsite.com"
#property version   "1.01"
#property strict

#include <Trade\Trade.mqh>

input int MagicNumber = 123456;  // Magic number for trade identification

CTrade trade;
datetime lastTradeTime = 0;
double yesterdayHigh = 0;
datetime currentTradingDay = 0;

int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    // Perform any cleanup here
}

void OnTick()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    // Check for a new trading day
    if (IsNewTradingDay(currentTime))
    {
        // Calculate yesterday's high
        yesterdayHigh = iHigh(_Symbol, PERIOD_D1, 1);
        lastTradeTime = 0; // Reset last trade time
        currentTradingDay = currentTime;
        Print("New trading day started. Yesterday's high: ", yesterdayHigh);
    }
    
    // Check if it's after 10 AM and before 5 PM
    if (timeStruct.hour >= 10 && timeStruct.hour < 17)
    {
        // Check if we haven't traded today and price is above yesterday's high
        if (lastTradeTime == 0 && SymbolInfoDouble(_Symbol, SYMBOL_ASK) > yesterdayHigh)
        {
            if (OpenLongPosition())
            {
                lastTradeTime = currentTime;
            }
        }
    }
    // Check if it's 5 PM or later
    else if (timeStruct.hour >= 17)
    {
        CloseAllPositions();
    }
}

bool IsNewTradingDay(datetime currentTime)
{
    if (currentTradingDay == 0)
    {
        return true; // First run of the EA
    }
    
    MqlDateTime currentTimeStruct, lastTimeStruct;
    TimeToStruct(currentTime, currentTimeStruct);
    TimeToStruct(currentTradingDay, lastTimeStruct);
    
    // Check if it's a new day and the market has been closed for a while
    if (currentTimeStruct.day != lastTimeStruct.day && currentTime - currentTradingDay > PeriodSeconds(PERIOD_H4))
    {
        return true;
    }
    
    return false;
}

bool OpenLongPosition()
{
    double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double lotSize = 0.01; // You may want to adjust this or make it an input parameter
    
    if (trade.Buy(lotSize, _Symbol, askPrice, 0, 0, "open"))
    {
        Print("Long position opened successfully");
        return true;
    }
    else
    {
        Print("Error opening long position: ", GetLastError());
        return false;
    }
}

void CloseAllPositions()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            if (PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
                trade.PositionClose(ticket);
            }
        }
    }
}