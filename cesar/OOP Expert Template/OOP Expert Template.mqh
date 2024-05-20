#define APP_COPYRIGHT "cesreve"
#define APP_LINK      ""
#define APP_VERSION   "1.00"
#define APP_DESCRIPTION                                                                            \
   "A simple template"
#define APP_COMMENT "OOP Expert Template"
#define APP_MAGIC   999

#include "Framework.mqh"

//	Inputs
 
input string InpStartTime;// = "10:00";
input string InpStopTime;// = "18:00";

//	Default inputs
//	I have these in a separate file because I use them all the time
#include <Orchard/Shared/Default Inputs.mqh>

//	The expert does all the work
#include "Expert.mqh"
CExpert *Expert;

//
int      OnInit() {

   Expert =
      new CExpert( new CTimeFilter(InpStartTime, InpStopTime), //timefilter
                     InpVolume, InpTradeComment, InpMagic );

   return ( Expert.OnInit() );
}

//
void OnDeinit( const int reason ) {
   delete Expert;
}

//
void OnTick() {
   Expert.OnTick();
}

//
