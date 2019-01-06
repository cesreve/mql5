//+------------------------------------------------------------------+
//|                                             dax30_holy_grail.mq5 |
//|                                                          cesreve |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "CEEZER"
#property link      ""
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input int InpStochKPeriod       = 12;        // Stochastic %K
input int InpStochDPeriod       = 3;         // Stochastic %D
input int InpStochSlowing       = 3;         // Stochastic slowing
input double   InpLots          = 0.1;       // lots
input ushort   InpTakeProfit    = 0.0;       // Take Profit (in pips)
input ushort   InpStopLoss      = 0.0;       // Stop Loss (in pips)
input ushort   InpBreakevenStop = 8.0;       // Breakeven Stop (in pips)
//---
ulong    m_magic=417858287;            // magic number
ulong    m_slippage=30;                // slippage
int      handle_iStochastic;           // variable for storing the iStochastic indicator

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {   
   if(Bars(Symbol(),Period())<InpStochKPeriod)
     {
      Print("Number of bars is too small");
      return(INIT_FAILED);
     }
    else if(Bars(Symbol(),Period())>=InpStochKPeriod) return(INIT_SUCCEEDED);  
//---
   m_symbol.Name(Symbol());                  // sets symbol name
   RefreshRates();
   m_symbol.Refresh();
   
//---
   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
     {
      Print(err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
     
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(Symbol(),SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(Symbol(),SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   m_trade.SetDeviationInPoints(m_slippage);
   
//--- create handle of the indicator iStochastic
   handle_iStochastic=iStochastic(m_symbol.Name(),Period(),InpStochKPeriod,InpStochDPeriod,InpStochSlowing,MODE_SMA,STO_LOWHIGH);
//--- if the handle is not created 
   if(handle_iStochastic==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iStochastic indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   Comment("\n\n\nTime is: ", iTime(1));

//--- Get indicators vales
   double Stoch1		   = iStochasticGet(MAIN_LINE,1);
   double StochSignal1 	= iStochasticGet(SIGNAL_LINE,1);

//--- closing Positions
   int total=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            total++;
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               if(StochSignal1>80)
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  return;
                 }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
               if(StochSignal1<20)
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  return;
                 }
               }

//--- Breakeven stop
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            total++;
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               if(m_symbol.Bid()>m_position.PriceOpen()+m_symbol.NormalizePrice(InpBreakevenStop))
               {
                m_trade.PositionModify(m_position.Ticket(),m_position.PriceOpen(),m_position.PriceOpen()+m_symbol.NormalizePrice(InpTakeProfit));
                return;
               }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
               if(m_symbol.Ask()<m_position.PriceOpen()-m_symbol.NormalizePrice(InpBreakevenStop))
               {
                m_trade.PositionModify(m_position.Ticket(),m_position.PriceOpen(),m_position.PriceOpen()-m_symbol.NormalizePrice(InpTakeProfit));
                return;
               }
             }

   if(total==0) // if there are no positions
     {
      //-- opening of a long position
      if(iClose(1)>= ((iOpen(2)+iClose(2))/2) && iClose(2)<iOpen(2) && Stoch1 < 20 && StochSignal1 < 20)
        {
         if(!RefreshRates())
           {
            PrevBars=iTime(1);
            return;
           }
         OpenBuy(InpStopLoss,InpTakeProfit);
         return;
        }

      //--- opening a short position
      if(iClose(1) <= ((iOpen(2)+iClose(2))/2) && iClose(2)>iOpen(2) && Stoch1 > 80 && StochSignal1 > 80)
        {
         if(!RefreshRates())
           {
            PrevBars=iTime(1);
            return;
           }
         OpenSell(InpStopLoss,InpTakeProfit);
         return;
        }
     }
   return;
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Checks if the specified filling mode is allowed                  | 
//+------------------------------------------------------------------+ 
bool IsFillingTypeAllowed(string symbol,int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes 
   int filling=(int)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
//--- Return true, if mode fill_type is allowed 
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+ 
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0) time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+ 
//| Get Open for specified bar index                                | 
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
//| Get Stochastic indicator values                                  | 
//|  the buffer numbers are the following:                           |
//|   0 - MAIN_LINE, 1 - SIGNAL_LINE                                 |                             
//+------------------------------------------------------------------+ 
double iStochasticGet(const int buffer, const int index)
  {
   double Stoch[1];
//ArraySetAsSeries(Stoch,true);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iStochasticBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iStochastic,buffer,index,1,Stoch)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Stoch[0]);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(chek_volime_lot!=0.0)
      if(chek_volime_lot>=InpLots)
        {
         if(m_trade.Buy(InpLots,NULL,m_symbol.Ask(),m_symbol.Bid()+sl,m_symbol.Bid()-tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
           }
         else
           {
            Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
        }
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(chek_volime_lot!=0.0)
      if(chek_volime_lot>=InpLots)
        {
         if(m_trade.Sell(InpLots,NULL,m_symbol.Bid(),m_symbol.Ask()+sl,m_symbol.Ask()+tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
           }
         else
           {
            Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
        }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+