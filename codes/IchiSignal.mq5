//+------------------------------------------------------------------+
//|                                                 Ichimoku_signal.mq5 |
//|                                                           Ceezer |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Ceezer"
#property link      ""
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\OrderInfo.mqh>

CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
COrderInfo     m_order;                      // pending orders object

//----
int TenkanSenPeriod				    =9;
int KijunSenPeriod           	=26;
int SenkouPeriod             	=52;
int handle_iIchimoku;

//---
input string          BullSound   = "alert.wav";
input string          BearSound   = "alert2.wav";
input bool            ShowAlert = true;
MqlRates rates_array[1];
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create handle of the indicator iIchimoku
   handle_iIchimoku=iIchimoku(m_symbol.Name(),Period(),TenkanSenPeriod,KijunSenPeriod,SenkouPeriod);
//--- if the handle is not created 
   if(handle_iIchimoku==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iIchimoku indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
	static bool trigger=true; // for one-shot play sound in bar duration
	m_symbol.RefreshRates();
	if(!CopyRates(_Symbol,TimeFrame,0,1,rates_array))
	 {
		  Print("ERROR: Can't copy the new bar data!");
		  return;
	 }
	if(NewBar())
	{
		trigger=true;
		//Print("Trigger is true !");
	}


      	
//--- 
  double TKS1     =iIchimokuGet(TENKANSEN_LINE, 1);
  double KS1			=iIchimokuGet(KIJUNSEN_LINE, 1);
  double SSA1     =iIchimokuGet(SENKOUSPANA_LINE, 1);
  double SSB1     =iIchimokuGet(SENKOUSPANB_LINE,1);
  double CHK1     =iIchimokuGet(CHIKOUSPAN_LINE,1);
	//double KS2			=iIchimokuGet(KIJUNSEN_LINE,2);
	double close1		=iClose(1);
  double close26  =iClose(26);
	double open1		=iOpen(1);
	//double close2		=iClose(2);
//---²
	if(trigger)
  {	   if(close1 >= TKS1 && close1 >= KS1 && close1 >= SSA1 && close1 >= SSB1 && CHK1 >= close26) // bullish signal condition
   	{
   		PlaySound(BullSound);
   		trigger=false;
   		//Print("Trigger is false");
   		if(ShowAlert)
   			Alert("Bullish Signal!");
   	}
    if(close1 <= TKS1 && close1 <= KS1 && close1 <= SSA1 && close1 <= SSB1 && CHK1 <= close26) // bearish signal condition
    {
      PlaySound(BearSound);
      trigger=false;
      //Print("Trigger is false");
      if(ShowAlert)
        Alert("Bearish Signal");
    }
  }
  } 
//---

//+------------------------------------------------------------------+
//| Detects begin of new bar                                         |
//+------------------------------------------------------------------+
bool NewBar()
  {
   static datetime lastbar=0;
   datetime curbar=  rates_array[0].time;
   if(lastbar!=curbar)
     {
      lastbar=curbar;
      return (true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iIchimoku                           |
//|  the buffer numbers are the following:                           |
//|   0 - TENKANSEN_LINE, 1 - KIJUNSEN_LINE, 2 - SENKOUSPANA_LINE,   |
//|   3 - SENKOUSPANB_LINE, 4 - CHIKOUSPAN_LINE                      |
//+------------------------------------------------------------------+
double iIchimokuGet(const int buffer,const int index)
  {
   double Ichimoku[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iIchimoku array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iIchimoku,buffer,index,1,Ichimoku)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iIchimoku indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Ichimoku[0]);
  }
//+------------------------------------------------------------------+ 
//| Get Close for specified bar index                                | 
//+------------------------------------------------------------------+ 
double iClose(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double Close[1];
   double close=0;
   int copied=CopyClose(symbol,timeframe,index,1,Close);
   if(copied>0) close=Close[0];
   return(close);
  }
//+------------------------------------------------------------------+ 
//| Get Open for specified bar index                                 | 
//+------------------------------------------------------------------+ 
double iOpen(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double Open[1];
   double open=0;
   int copied=CopyOpen(symbol,timeframe,index,1,Open);
   if(copied>0) open=Open[0];
   return(open);
  }
