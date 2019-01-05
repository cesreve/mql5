//+------------------------------------------------------------------+
//|                                                      BoTrend.mq5 |
//|                                                           Ceezer |
//+------------------------------------------------------------------+
#property copyright "Ceezer"
#property version   "1.00"

#define BACK_MAGIC 6730
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//---
input double      InpLots          = 1.0;       // Volume
input double      InpTrailingStop  = 5.0;       // Trailing Stop
input double      InpStopLoss      = 10.0;      // Stop Loss
input double      InpTakeProfit    = 10.0;      // Take Profit
input int         InpMA1Period     = 100;       // MA1 Period
input int         InpMA2Period     = 300;       // MA2 Period
input int         InpMA3Period     = 600;       // MA3 Period
input int         InpMA4Period     = 1000;      // MA4 Period
input int         InpStochKPeriod     = 11;     // Stochastic %K
input int         InpStochDPeriod     = 5;      // Stochastic %D
input int         InpStochSlowing     = 3;      // Stochastic slowing
//---
//+------------------------------------------------------------------+
//| Sample Strategy expert class                                     |
//+------------------------------------------------------------------+
class CSampleExpert
  {
protected:
  double            m_adjusted_point;
  CTrade            m_trade;
  CSymbolInfo       m_symbol;
  CPositionInfo     m_position;
  CAccountInfo      m_account;
  //--- indicators
  int               m_handle_MA1;
  int               m_handle_MA2;
  int               m_handle_MA3;
  int               m_handle_MA4;
  int               m_handle_stochastic;
  //--- indicator buffers
  double            m_buff_MA1[];
  double            m_buff_MA2[];
  double            m_buff_MA3[];
  double            m_buff_MA4[];
  double            m_buff_stochastic_main[];
  double            m_buff_stochastic_signal[];
  double            m_buff_Close[];
  //--- indicator data for processing
  double            m_MA1;
  double            m_MA2;
  double            m_MA3;
  double            m_MA4;
  double            m_stochastic;
  double            m_stochastic_previous;
  double            m_signal;
  double            m_signal_previous;
  double				  m_close;
  //---
  double            m_trailing_stop;
  double            m_take_profit;
  double            m_stop_loss;

public:
                    CSampleExpert(void);
                   ~CSampleExpert(void);
  bool              Init(void);
  void              Deinit(void);
  bool              Processing(void);

protected:
  bool              InitCheckParameters(const int digits_adjust);
  bool              InitIndicators(void);
  bool              LongOpened(void);
  bool              ShortOpened(void);
  };
//--- global expert
CSampleExpert ExtExpert;
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSampleExpert::CSampleExpert(void): m_adjusted_point(0),
                                    m_handle_MA1(INVALID_HANDLE),
                                    m_handle_MA2(INVALID_HANDLE),
                                    m_handle_MA3(INVALID_HANDLE),
                                    m_handle_MA4(INVALID_HANDLE),
                                    m_handle_stochastic(INVALID_HANDLE),                                   
                                    m_MA1(0),
                                    m_MA2(0),
                                    m_MA3(0),
                                    m_MA4(0),
                                    m_stochastic(0),
                                    m_stochastic_previous(0),
                                    m_signal(0),
                                    m_signal_previous(0),
                                    m_close(0),                     
                                    m_trailing_stop(0),
                                    m_take_profit(0),
                                    m_stop_loss(0)
    {
      ArraySetAsSeries(m_buff_MA1,true);
      ArraySetAsSeries(m_buff_MA2,true);
      ArraySetAsSeries(m_buff_MA3,true);
      ArraySetAsSeries(m_buff_MA4,true);
      ArraySetAsSeries(m_buff_stochastic_main,true);
      ArraySetAsSeries(m_buff_stochastic_signal,true);
      ArraySetAsSeries(m_buff_Close,true);
    }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSampleExpert::~CSampleExpert(void)
  {
  }
//+------------------------------------------------------------------+
//| Initialization and checking for input parameters                 |
//+------------------------------------------------------------------+
bool CSampleExpert::Init(void)
  {
//--- initialize common information
    m_symbol.Name(Symbol());                   // symbol
    m_trade.SetExpertMagicNumber(BACK_MAGIC);  // magic
    m_trade.SetMarginMode();
//--- tuning digits for GER30
    int digits_adjust=100;
    m_adjusted_point=m_symbol.Point()*digits_adjust;
//--- set default deviation for trading in adjusted points
    m_trailing_stop   =InpTrailingStop*m_adjusted_point;
    m_take_profit     =InpTakeProfit*m_adjusted_point;
    m_stop_loss       =InpStopLoss*m_adjusted_point;          
//--- set default deviation for trading in adjusted points
    m_trade.SetDeviationInPoints(3*digits_adjust);
//---
    if(!InitCheckParameters(digits_adjust))
      return(false);
    if(!InitIndicators())
      return(false);
//--- succeed
    return(true);      
  }
//+------------------------------------------------------------------+
//| Checking for input parameters                                    |
//+------------------------------------------------------------------+
bool CSampleExpert::InitCheckParameters(const int digits_adjust)
  {
//--- initial data checks
    if(InpTakeProfit*digits_adjust<m_symbol.StopsLevel())
    {
      printf("Take Profit must be greater than %d",m_symbol.StopsLevel());
      return(false);
    }
    if(InpStopLoss*digits_adjust<m_symbol.StopsLevel())
    {
      printf("Stop Loss must be greater than %d",m_symbol.StopsLevel());
      return(false);
    }
    if(InpTrailingStop*digits_adjust<m_symbol.StopsLevel())
    {
      printf("Trailing Stop must be greater than %d",m_symbol.StopsLevel());
      return(false);
    }
//--- check for right lots amount
    if(InpLots<m_symbol.LotsMin() || InpLots>m_symbol.LotsMax())
    {
      printf("Lots amount must be in the range from %f to %f",m_symbol.LotsMin(),m_symbol.LotsMax());
      return(false);
    }
    if(MathAbs(InpLots/m_symbol.LotsStep()-MathRound(InpLots/m_symbol.LotsStep()))>1.0E-10)
    {
      printf("Lots amount is not corresponding with lot step %f",m_symbol.LotsStep());
      return(false);
    }
//--- warning
    if(InpTakeProfit<=InpTrailingStop)
      printf("Warning: Trailing Stop must be less than Take Profit");
//--- succeed
    return(true);
  }
//+------------------------------------------------------------------+
//| Initialization of the indicators                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::InitIndicators(void)
  {
//--- create MA1 indicator
    if(m_handle_MA1==INVALID_HANDLE)
      if((m_handle_MA1=iMA(NULL,0,InpMA1Period,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
      {
        printf("Error creating MA1 indicator");
        return(false);
      }
//--- create MA2 indicator
    if(m_handle_MA2==INVALID_HANDLE)
      if((m_handle_MA2=iMA(NULL,0,InpMA2Period,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
      {
        printf("Error creating MA2 indicator");
        return(false);
      }
//--- create MA3 indicator
    if(m_handle_MA3==INVALID_HANDLE)
      if((m_handle_MA3=iMA(NULL,0,InpMA3Period,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
      {
        printf("Error creating MA3 indicator");
        return(false);
      }
//--- create MA4 indicator
    if(m_handle_MA4==INVALID_HANDLE)
      if((m_handle_MA4=iMA(NULL,0,InpMA4Period,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
      {
        printf("Error creating MA4 indicator");
        return(false);
      } 
//--- create stochastic indicator
    if(m_handle_stochastic==INVALID_HANDLE)
      if((m_handle_stochastic=iStochastic(NULL,0,InpStochKPeriod,InpStochDPeriod,InpStochSlowing,MODE_SMA,STO_LOWHIGH))==INVALID_HANDLE)
      {
        printf("Error creating stochastic indicator");
        return(false);
      }
//--- succeed
    return(true);
  }
//+------------------------------------------------------------------+
//| Check for long position opening                                  |
//+------------------------------------------------------------------+
bool CSampleExpert::LongOpened(void)
  {
    bool res=false;
//--- check for long position(BUY) possibility
    if(m_stochastic<20 || m_stochastic_previous<20)
      if(m_stochastic>m_signal && m_stochastic_previous<m_signal_previous)
        if(m_close>m_MA1 && m_MA1>m_MA2 && m_MA2>m_MA3 && m_MA3>m_MA4)
        {
          double price 	=m_symbol.Ask();
          double tp   	=m_symbol.Bid()+m_take_profit;
          double sl   	=m_symbol.Bid()-m_stop_loss;
          //-- check for free money
          if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_BUY,InpLots,price)<0.0)
            printf("We have no money. Free Margin = %f",m_account.FreeMargin());
          else
          {
            //--- open position
            if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,InpLots,price,sl,tp))
              printf("Position by %s to be opened",Symbol());
            else
            {
              printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
              printf("Open parameters : price=%f,TP=%f",price,tp);
            }
          }
        //--- in any case we must exit from the expert
        res=true;
        }
//--- result
    return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position opening                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::ShortOpened(void)
  {
    bool res=false;
//--- check for short position(SELL) possibility
    if(m_stochastic>80 || m_stochastic_previous>80)
      if(m_stochastic<m_signal && m_stochastic_previous>m_signal_previous)
        if(m_close<m_MA1 && m_MA1<m_MA2 && m_MA2<m_MA3 && m_MA3<m_MA4)
        {
          double price 	=m_symbol.Bid();
          double tp   	=m_symbol.Ask()-m_take_profit;
          double sl   	=m_symbol.Ask()+m_stop_loss;
          //-- check for free money
          if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_SELL,InpLots,price)<0.0)
            printf("We have no money. Free Margin = %f",m_account.FreeMargin());
          else
          {
            //--- open position
            if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,InpLots,price,sl,tp))
              printf("Position by %s to be opened",Symbol());
            else
            {
              printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
              printf("Open parameters : price=%f,TP=%f",price,tp);
            }
          }
        //--- in any case we must exit from the expert
        res=true;
        }
//--- result
    return(res);
  }
//+------------------------------------------------------------------+
//| main function returns true if any position processed             |
//+------------------------------------------------------------------+
bool CSampleExpert::Processing(void)
  {
//--- refresh rates
    if(!m_symbol.RefreshRates())
      return(false);
//--- refresh indicators
    if(CopyBuffer(m_handle_MA1,0,1,1,m_buff_MA1)               			<0 ||
       CopyBuffer(m_handle_MA2,0,1,1,m_buff_MA2)               			<0 ||
       CopyBuffer(m_handle_MA3,0,1,1,m_buff_MA3)               			<0 ||
       CopyBuffer(m_handle_MA4,0,1,1,m_buff_MA4)               			<0 ||
       CopyBuffer(m_handle_stochastic,1,1,2,m_buff_stochastic_signal)   <0 ||
       CopyBuffer(m_handle_stochastic,0,1,2,m_buff_stochastic_main)     <0 ||
    	 CopyClose(NULL,0,1,1,m_buff_Close)								         <0)
    	 {
    	   printf("ECHEC creation buffer");
    	   return(false);
       }   
//--- to simplify the coding and speed up access
//--- data are put into internal variables
    m_MA1      							=m_buff_MA1[0];
    m_MA2      							=m_buff_MA2[0];
    m_MA3      							=m_buff_MA3[0];
    m_MA4      							=m_buff_MA4[0];
    m_stochastic                    =m_buff_stochastic_main[0];
    m_stochastic_previous           =m_buff_stochastic_main[1];
    m_signal                        =m_buff_stochastic_signal[0];
    m_signal_previous               =m_buff_stochastic_signal[1];
    m_close                         =m_buff_Close[0];
//--- display all theses data on chart
    Comment("Moving averages: ",m_MA1," ",m_MA2," ",m_MA3," ",m_MA4,
    	"\nStochastic & Signal: ",m_stochastic," ",m_signal,
    	"\nStochastic previous & Signal previous: ",m_stochastic_previous," ",m_signal_previous,
    	"\nClose: ",m_close);
//--- entering position
		if(PositionsTotal()<2 && OpenForTrading() =="YES")
		{
		   //--- check for long (BUY) possibility
		   if(LongOpened())
		   	return(true);
		   //--- check for short (SELL) possibility
		   if(ShortOpened())
		   	return(true);
	  }
//--- exit without position processing
    return(false);
  }
//+------------------------------------------------------------------+
//| Check hours to open trade                                        |
//+------------------------------------------------------------------+
string OpenForTrading()
  {
//---
      string TradeHour = "";
      MqlDateTime mdt;
      datetime t = TimeCurrent(mdt);
      int m_year=mdt.year;
      int m_month=mdt.mon;
      int m_day=mdt.day;
      int m_hour=mdt.hour;
      int m_minute=mdt.min;
      if (m_hour>=10 && m_hour<=19)
         {
            TradeHour = "YES";
            //Print("oui");
            Comment("TRADING OK: ",t);
         }
      else
         {
            TradeHour = "NO";
            //Print("non");
            Comment("TRADING NOT OK: ",t);
         }
      return(TradeHour);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- create all necessary objects
    if(!ExtExpert.Init())
      return(INIT_FAILED);
//---
    return(INIT_SUCCEEDED);
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
//| Expert new tick handling function                                |
//+------------------------------------------------------------------+
void OnTick(void)
  {
//--- we work only at the time of the birth of new bar
  static datetime PrevBars=0;
  datetime time_0=iTime(0);
  if(time_0==PrevBars)
     return;
  PrevBars=time_0;
//--- check data
  if(Bars(Symbol(),Period())>2*InpMA3Period)
    ExtExpert.Processing();
  }
//+------------------------------------------------------------------+