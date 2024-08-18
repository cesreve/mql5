//+------------------------------------------------------------------+
//|                                                       Entry1.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      "http://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

// Enum for timeframe selection
enum ENUM_CUSTOM_TIMEFRAME
{
    TIMEFRAME_M1 = PERIOD_M1,    // 1 minute
    TIMEFRAME_M5 = PERIOD_M5,    // 5 minutes
    TIMEFRAME_M15 = PERIOD_M15,  // 15 minutes
    TIMEFRAME_H1 = PERIOD_H1,    // 1 hour
    TIMEFRAME_H4 = PERIOD_H4,    // 4 hours
    TIMEFRAME_D1 = PERIOD_D1     // 1 day
};

// Input parameters
input double   InpLotSize = 0.1;           // Lot size
input int      InpMagicNumber = 123456;    // Magic number
input ENUM_CUSTOM_TIMEFRAME InpTimeframe = TIMEFRAME_M15;  // Timeframe
input int      InpStartHour = 9;           // Start trading hour (0-23)
input int      InpEndHour = 17;            // End trading hour (0-23)

// Global variables
CTrade trade;
datetime lastBarTime;
double lastClose;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize the trade object
    trade.SetExpertMagicNumber(InpMagicNumber);
    
    // Store the last bar's time and close price
    lastBarTime = iTime(_Symbol, InpTimeframe, 0);
    lastClose = iClose(_Symbol, InpTimeframe, 1);
    
    // Validate input parameters
    if(InpStartHour < 0 || InpStartHour > 23 || InpEndHour < 0 || InpEndHour > 23)
    {
        Print("Invalid trading hours. Please enter values between 0 and 23.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Perform any cleanup here
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if it's within trading hours
    datetime currentTime = TimeCurrent();
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    if(timeStruct.hour < InpStartHour || timeStruct.hour >= InpEndHour)
    {
        return; // Outside trading hours, do nothing
    }
    
    // Check if a new bar has formed
    if(lastBarTime < iTime(_Symbol, InpTimeframe, 0))
    {
        // Update lastBarTime
        lastBarTime = iTime(_Symbol, InpTimeframe, 0);
        
        // Get the current close price
        double currentClose = iClose(_Symbol, InpTimeframe, 1);
        
        // Check for long entry
        if(currentClose > lastClose)
        {
            if(!PositionSelect(_Symbol)) // No open position
            {
                trade.Buy(InpLotSize, _Symbol, 0, 0, 0, "Long Entry");
            }
            else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) // Close short and open long
            {
                trade.PositionClose(_Symbol);
                trade.Buy(InpLotSize, _Symbol, 0, 0, 0, "Long Entry");
            }
        }
        // Check for short entry
        else if(currentClose < lastClose)
        {
            if(!PositionSelect(_Symbol)) // No open position
            {
                trade.Sell(InpLotSize, _Symbol, 0, 0, 0, "Short Entry");
            }
            else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) // Close long and open short
            {
                trade.PositionClose(_Symbol);
                trade.Sell(InpLotSize, _Symbol, 0, 0, 0, "Short Entry");
            }
        }
        
        // Update lastClose
        lastClose = currentClose;
    }
}
