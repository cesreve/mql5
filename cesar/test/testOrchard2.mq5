//+------------------------------------------------------------------+
//|                                              TimeRangeExample.mq5 |
//|                        Copyright 2023, Your Name                  |
//|                             https://www.yourwebsite.com           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Name"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include <Orchard/Frameworks/Framework_3.06/Extensions/TimeRange.mqh>

input int GMTOffset = 0; // GMT offset for your broker's server time

CTimeRange *timeRange;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    timeRange = new CTimeRange(_Symbol, PERIOD_CURRENT);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    delete timeRange;
    ObjectsDeleteAll(0);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Get current server time
    datetime currentTime = TimeCurrent();
    
    // Calculate today's date at 10:00 and 11:00
    MqlDateTime currentTimeStruct;
    TimeToStruct(currentTime, currentTimeStruct);
    
    datetime startTime = StringToTime(StringFormat("%04d.%02d.%02d 10:00:00", 
        currentTimeStruct.year, currentTimeStruct.mon, currentTimeStruct.day)) - GMTOffset * 3600;
    datetime endTime = StringToTime(StringFormat("%04d.%02d.%02d 11:00:00", 
        currentTimeStruct.year, currentTimeStruct.mon, currentTimeStruct.day)) - GMTOffset * 3600;
    
    // Set the time range
    timeRange.SetTimeRange(startTime, endTime);

    // Display the range on the chart
    timeRange.DisplayRangeOnChart(clrAliceBlue, clrBlue, 2);
    
    // Display information in a comment
    string comment = StringFormat(
        "Time Range Example\n" +
        "Start Time: %s\n" +
        "End Time: %s\n" +
        "High Point: %.5f\n" +
        "Low Point: %.5f\n" +
        "Current Time: %s\n" +
        "Is In Range: %s",
        TimeToString(timeRange.GetStartTime(), TIME_DATE|TIME_MINUTES),
        TimeToString(timeRange.GetEndTime(), TIME_DATE|TIME_MINUTES),
        timeRange.GetHighPoint(),
        timeRange.GetLowPoint(),
        TimeToString(currentTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
        timeRange.IsInRange(currentTime) ? "Yes" : "No"
    );
    
    Comment(comment);
}