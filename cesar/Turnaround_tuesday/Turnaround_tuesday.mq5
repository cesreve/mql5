#property copyright "Cesreve"
#property link      "https://www.cesreve.com"
#property version   "1.02"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input int MagicNumber = 123456;     // Magic number for trade identification
input double LotSize = 1;        // Lot size for trading
input int InpMaPeriod = 34;         // Period for Moving Average
input ENUM_MA_METHOD MAMethod = MODE_EMA;  // Moving Average method
input int InpTuesdayStartHour = 9; // Start hour for Tuesday
input int InpTuesdayEndHour = 17;  // End hour for Tuesday
input double InpStopLossPercent = 1; // Stop loss percentage

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;
bool tradeAllowed = false;
int handleMA;  // Handle for the moving average indicator
double ma[];   // Array to store MA values

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    
    //--- create moving average handle
    handleMA = iMA(Symbol(), PERIOD_CURRENT, InpMaPeriod, 0, MAMethod, PRICE_CLOSE);
    if(handleMA == INVALID_HANDLE)
    {
        Alert("Failed to create MA handle");
        return INIT_FAILED;
    }
    
    // Initialize ma array
    ArraySetAsSeries(ma, true);
    ArrayResize(ma, 1);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release the MA indicator handle
    IndicatorRelease(handleMA);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    MqlDateTime time;
    TimeCurrent(time);
    UpdateMA();
    // Reset tradeAllowed on Monday
    if (time.day_of_week == WEDNESDAY)
    {
        tradeAllowed = true;
    }
    
    // Check for opening condition on Tuesday after x AM
    if (time.day_of_week == TUESDAY && time.hour >= InpTuesdayStartHour && tradeAllowed)
    {
        CheckAndOpenPosition();
    }
    
    // Check for closing condition on Tuesday after x PM
    if (time.hour > InpTuesdayEndHour || time.day_of_week != TUESDAY)
    {
        CloseAllPositions();
    }

    Comment('\n',(string)time.day_of_week, 
    '\n', (string)ma[0], 
    '\n', (string)time.hour
    //'\n', (string)ma[1]
    );
    
} // End of OnTick

//+------------------------------------------------------------------+
//| Function to update MA values                                        |
//+------------------------------------------------------------------+
void UpdateMA()
{
    if(CopyBuffer(handleMA, 0, 1, 1, ma) != 1)
    {
        Print("Failed to get iMA values.");
    }
}

//+------------------------------------------------------------------+
//| Function to check condition and open position                     |
//+------------------------------------------------------------------+
void CheckAndOpenPosition()
{
     // Update MA value
     UpdateMA();
     
     // Check if Monday's close was below the MA
     double mondayClose = iClose(_Symbol, PERIOD_D1, 1); // Yesterday's close
     
    if (mondayClose < ma[0])
    // if( mondayClose < mondayOpen)
     {
         OpenPosition();
         tradeAllowed = false; // Prevent opening more positions this week
     }
}

//+------------------------------------------------------------------+
//| Function to open a position                                        |
//+------------------------------------------------------------------+  
void OpenPosition()
{
    double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    if (trade.Buy(LotSize, _Symbol, askPrice, CalculateStopLoss(InpStopLossPercent), 0, string(__FILE__)))
    {
        Print("Long position opened successfully");
    }
    else
    {
        Print("Error opening long position: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Function to close all positions                                    |
//+------------------------------------------------------------------+  
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
                Print("Position closed");
            }
        }
    }
}

// Function to calculate the stoploss
double CalculateStopLoss(double risk)
{   
    double prevClose = iClose(_Symbol, PERIOD_D1, 1);
    double stopLoss = prevClose - (risk/100 * prevClose);
    return stopLoss;
}