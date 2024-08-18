//+------------------------------------------------------------------+
//|                                              TimeRangeExample.mq5 |
//|                        Copyright 2023, Your Name                  |
//|                             https://www.yourwebsite.com           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Name"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include <Orchard/Frameworks/Framework_3.06/Framework.mqh>

//+------------------------------------------------------------------+
CTradeCustom trade;
CRange *Range = NULL;

//+------------------------------------------------------------------+
//| Input variables                                                 |
//+------------------------------------------------------------------+
input int InpStartHour = 10; // Start hour for the range (0-23)
input int InpStartMin = 0; // Start minute for the range (0-59)
input int InpEndHour = 11; // End hour for the range (0-23)
input int InpEndMin = 0; // End minute for the range (0-59)

//+------------------------------------------------------------------+
//| Global variables                                                |
//+------------------------------------------------------------------+
datetime lastRangeDate = 0;
int positionCounts[2]; // Index 0 for long positions, index 1 for short positions
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if (Range != NULL)
    {
        delete Range;
        Range = NULL;
    }
    ObjectsDeleteAll(0);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Get current server time
    datetime currentTime = TimeCurrent();
    
    // Calculate today's date at start and end times
    MqlDateTime currentTimeStruct;
    TimeToStruct(currentTime, currentTimeStruct);
    
    // Check if we need to create a new time range object
    Range = new CRange(_Symbol, PERIOD_CURRENT);

    // Set the time range
    Range.SetTimeRange(currentTime, InpStartHour, InpStartMin, InpEndHour, InpEndMin);    

    // Display the range on the chart
    Range.DisplayRangeOnChart(clrAliceBlue, clrBlue, 2);
    
    // Display information in a comment
    string comment = StringFormat(
        "Time Range Example\n" +
        "Start Time: %s\n" +
        "End Time: %s\n" +
        "High Point: %.5f\n" +
        "Low Point: %.5f\n" +
        "High Point Time: %s\n" +
        "Low Point Time: %s\n" +
        "Current Time: %s\n" +
        "Is In Range: %s",
        TimeToString(Range.GetStartTime(), TIME_DATE|TIME_MINUTES),
        TimeToString(Range.GetEndTime(), TIME_DATE|TIME_MINUTES),
        Range.GetHighPoint(),
        Range.GetLowPoint(),
        TimeToString(Range.GetHighPointTime(), TIME_DATE|TIME_MINUTES|TIME_SECONDS),
        TimeToString(Range.GetLowPointTime(), TIME_DATE|TIME_MINUTES|TIME_SECONDS),
        TimeToString(currentTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
        Range.IsInRange(currentTime) ? "Yes" : "No"
    );
    
    Comment(comment);
    
    // Count positions by type
    trade.PositionCountByType(_Symbol, positionCounts);

    // Add position count information to the comment
    comment += StringFormat("\nLong Positions: %d\nShort Positions: %d",
                            positionCounts[POSITION_TYPE_BUY],
                            positionCounts[POSITION_TYPE_SELL]);

    // Update the comment on the chart
    Comment(comment);
}
