//+------------------------------------------------------------------+
//|                                                      HeatMap.mq4 |
//|                                                       Matheszabi |
//|                                          http://www.mathesoft.ro |
//+------------------------------------------------------------------+
#property copyright "Matheszabi"
#property link      "http://www.mathesoft.ro"
#property version   "1.00"
#property strict
#property indicator_chart_window

extern string CurrencyPairSufix = ".lmx";//Like .lmx if you use LMAX as broker;
//+------------------------------------------------------------------+

// Majors:   AUD,    CAD,    CHF,   EUR,   GBP,  JPY,    NZD,    USD
// ------------------------------- pairs ----------------------------
// AUD pairs: AUDCAD, AUDCHF, EURAUD, GBPAUD, AUDJPY, AUDNZD, AUDUSD
// CAD pairs: AUDCAD, CADCHF, EURCAD, GBPCAD, CADJPY, NZDCAD, USDCAD
// CHF pairs: AUDCHF, CADCHF, EURCHF, GBPCHF, CHFJPY, NZDCHF, USDCHF
// EUR pairs: EURAUD, EURCAD, EURCHF, EURGBP, EURJPY, EURNZD, EURUSD
// GBP pairs: GBPAUD, GBPCAD, GBPCHF, EURGBP, GBPJPY, GBPNZD, GBPUSD
// JPY pairs: AUDJPY, CADJPY, CHFJPY, EURJPY, GBPJPY, NZDJPY, USDJPY
// NZD pairs: AUDNZD, NZDCAD, NZDCHF, EURNZD, GBPNZD, NZDJPY, NZDUSD
// USD pairs: AUDUSD, USDCAD, USDCHF, EURUSD, GBPUSD, USDJPY, NZDUSD  

static string pairs[] = {"AUDCAD", "AUDCHF", "EURAUD", "GBPAUD", "AUDJPY", "AUDNZD", "AUDNZD",
                                   "CADCHF", "EURCAD", "GBPCAD", "CADJPY", "NZDCAD", "USDCAD",
                                             "EURCHF", "GBPCHF", "CHFJPY", "NZDCHF", "USDCHF",
                                                       "EURGBP", "EURJPY", "EURNZD", "EURUSD",
                                                                 "GBPJPY", "GBPNZD", "GBPUSD",
                                                                           "NZDJPY", "USDJPY",
                                                                                     "NZDUSD"                                                                      
                          };

                
string pairsWithSufix[];
double marketInfoPoints[]; // MarketInfo(currencyPair,MODE_POINT) -ex eurusd: 0.00001

extern bool DisplaySpreadInfo = true;
static string depositCurrencyName = AccountInfoString(ACCOUNT_CURRENCY); //usd  

extern bool DisplayCandleOpen = true; // Display the unclosed candle info

extern bool DisplayCandleClose = true;// Display the last closed candle info

extern int TopMostValues = 5; // After soring values how much need to be shown, the max is 28

int OnInit()
{
   int length = ArraySize(pairs);
   
   ArrayResize(pairsWithSufix,length);
   ArrayResize(marketInfoPoints,length);
   for(int i=0; i< length; i++){
      pairsWithSufix[i] = pairs[i] + CurrencyPairSufix;
      marketInfoPoints[i] = MarketInfo(pairsWithSufix[i],MODE_POINT);
   }      
       
   if(DisplaySpreadInfo){
      spreadData = new SpreadData();
   }
   if(DisplayCandleOpen){
      timeFrameDataOpen = new TimeFrameData(0);
   }
   
   if(DisplayCandleClose){
      timeFrameDataClose = new TimeFrameData(1);
   }
   
   return(INIT_SUCCEEDED);
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {  

   string comment = "";
   int length = ArraySize(pairs);
     
   
   if(DisplaySpreadInfo){
      spreadData.refresh();
      
      comment += spreadData.getCommentString(TopMostValues);      
      //comment += spreadData.getTop5CommentString();      
   }
   
   
   if(DisplayCandleOpen){
      timeFrameDataOpen.refresh(); 
      
      comment += "\n\n  OPEN candle data (not yet closed)";           
      comment += timeFrameDataOpen.getCommentString(TopMostValues);
   }
    
   if(DisplayCandleClose){
      timeFrameDataClose.refresh(); 
      
      comment += "\n\n  Last Closed candle data ";       
      comment += timeFrameDataOpen.getCommentString(TopMostValues);  
   }
   
   Comment(comment);
   WindowRedraw();
   return(rates_total);
 }
 
 
 
 


class PairValue
{
   public:
      string pair;
      double value;
};
// sorting helper function 
void swap(PairValue &pairValues[], int leftIndex, int rightIndex){
   PairValue swapPairValue;
   
   swapPairValue.pair = pairValues[leftIndex].pair;   
   swapPairValue.value = pairValues[leftIndex].value;
      
   pairValues[leftIndex].pair = pairValues[rightIndex].pair;
   pairValues[leftIndex].value = pairValues[rightIndex].value;
      
   pairValues[rightIndex].pair = swapPairValue.pair;
   pairValues[rightIndex].value = swapPairValue.value;   
}

// a qsort implementation for PairValue
void qsortPairValue(PairValue &pairValues[], int left, int right){
   int i, last;
   
   if (left >= right){
        return;
   }
        
   swap(pairValues, left, (left + right)/2); 
   last = left;
   for (i = left+1; i <= right; i++){
       if ( pairValues[i].value <  pairValues[left].value) {
            swap(pairValues, ++last, i);
       }
   }
            
   swap(pairValues, left, last);
    
   qsortPairValue(pairValues, left, last-1);
   qsortPairValue(pairValues, last+1, right);                
}

void qsortPairValueAbs(PairValue &pairValues[], int left, int right){
   int i, last;
   
   if (left >= right){
        return;
   }
        
   swap(pairValues, left, (left + right)/2); 
   last = left;
   for (i = left+1; i <= right; i++){
       if ( MathAbs(pairValues[i].value) <  MathAbs(pairValues[left].value)) {
            swap(pairValues, ++last, i);
       }
   }
            
   swap(pairValues, left, last);
    
   qsortPairValue(pairValues, left, last-1);
   qsortPairValue(pairValues, last+1, right);                
}

class SpreadData
{
   private:
   //nothing
   public: 
      PairValue inPoints[];
      PairValue inDepositCurrency[];
      // Constructors:      
      void SpreadData();
      // Functions:
      void refresh();
      string getCommentString(int length);
};
SpreadData *spreadData;

SpreadData::SpreadData( )
{   
    int length = ArraySize(pairsWithSufix);
    ArrayResize(inPoints,length);  
    ArrayResize(inDepositCurrency,length);   
    for(int i=0; i<length;i++){
      inPoints[i].pair = pairsWithSufix[i];
      inDepositCurrency[i].pair = pairsWithSufix[i];
    }
}
void SpreadData::refresh(){   
   int length = ArraySize(inPoints);
   int i;
   for( i=0; i< length; i++)
   {
      inPoints[i].value = (int)MarketInfo(pairsWithSufix[i], MODE_SPREAD);   
   }
   for( i=0; i< length; i++)
   {      
      inDepositCurrency[i].value = inPoints[i].value * MarketInfo(pairsWithSufix[i],MODE_TICKVALUE) ;
   }
   
  qsortPairValue(inPoints, 0, length-1);
  qsortPairValueAbs(inDepositCurrency, 0, length-1);
}
string SpreadData::getCommentString(int length = 28)
{
   int i;
   length= MathMin(MathMax(TopMostValues, 1), ArraySize(inPoints));
   
   string comment = "\n  Currency Pairs spread sorted by deposit currency ("+depositCurrencyName+") 1 lot value: -if you open 1 lot size this will be the starting negative amount\n";
   for( i=0; i< length; i++) // descending order: for( i=length-1; i>=0; i--)   
      comment += " "+spreadData.inDepositCurrency[i].pair +"-"+DoubleToStr(spreadData.inDepositCurrency[i].value,2)+" ";
      
   comment += "\n\n  Currency Pairs spread sorted by Points. Informative to use the Take Profit and Stop Loss\n";
   for( i=0; i< length; i++) // descending order: for( i=length-1; i>=0; i--)      
      comment += " "+spreadData.inPoints[i].pair +"-"+DoubleToStr(spreadData.inPoints[i].value,0)+" ";
      
      
   return comment;   
}





class TimeFrameData
{      
   private:
      int mCandleIndex;
   public:
      PairValue volatilityPercentage[];
      PairValue volatilityPoint[];
      PairValue movementPoint[];      
      PairValue trendingPercentage[];
      // Constructors:      
      void TimeFrameData(int candleIndex); 
      // Functions:     
      void refresh();
      string getCommentString(int length);      
};

TimeFrameData::TimeFrameData(int candleIndex)
{  
    this.mCandleIndex = candleIndex;
    
    int length = ArraySize(pairsWithSufix);
    
    ArrayResize(volatilityPercentage,length);  
    ArrayResize(volatilityPoint,length);    
    ArrayResize(movementPoint,length);     
    ArrayResize(trendingPercentage,length);   
}
void TimeFrameData::refresh()   
{   
   // get the data from market
   int length = ArraySize(volatilityPercentage);
   string currencyPair = "";
   double curLow, curHigh, curClose, curOpen;
   for(int i=0; i < length; i++){
      // cache for faster access:
      currencyPair = pairsWithSufix[i];
      curHigh = iHigh(currencyPair, PERIOD_CURRENT, mCandleIndex);
      curLow = iLow(currencyPair, PERIOD_CURRENT, mCandleIndex);
      curClose = iClose(currencyPair, PERIOD_CURRENT, mCandleIndex);
      curOpen = iOpen(currencyPair, PERIOD_CURRENT, mCandleIndex);
      // pair names
      volatilityPercentage[i].pair = currencyPair;
      volatilityPoint[i].pair = currencyPair;
      movementPoint[i].pair = currencyPair;
      trendingPercentage[i].pair = currencyPair;
      // values
      if( curLow != 0){// not all candles data received, so it can be 0 at this point!
         volatilityPercentage[i].value = 100 * ( curHigh - curLow ) / curLow;
      }      
      if(marketInfoPoints[i]){
         volatilityPoint[i].value = ( curHigh - curLow ) / marketInfoPoints[i] ;
         movementPoint[i].value = (curClose - curOpen) / marketInfoPoints[i] ;
      }
      if( (curHigh - curLow ) != 0){// not all candles data received, so it can be 0 at this point!
         trendingPercentage[i].value =  100*MathAbs(curClose - curOpen)/( curHigh - curLow );     
      }
   }
   // sort it:
  qsortPairValue(volatilityPercentage, 0, length-1);
  qsortPairValue(volatilityPoint, 0, length-1);
  qsortPairValueAbs(movementPoint, 0, length-1);
  qsortPairValueAbs(trendingPercentage, 0, length-1);
}
string TimeFrameData::getCommentString(int length=28)
{
   int i;
   length= MathMin(MathMax(TopMostValues, 1), ArraySize(volatilityPercentage));
   string comment = "\n  Volatility in percentage: 100 * (High-Low) / Low  \n";
   for( i=length-1; i>=0; i--)//descending order display   
      comment += " "+volatilityPercentage[i].pair +" "+DoubleToStr(volatilityPercentage[i].value,2)+" ";
   
   comment += "\n  Volatility in Points: 100 * (High-Low) to Points\n";   
   for( i=length-1; i>=0; i--)//descending order display      
      comment += " "+volatilityPoint[i].pair +" "+DoubleToStr(volatilityPoint[i].value,0)+" ";
      
   comment += "\n  Movement in Points: 100 * (Close-Open) to Points\n"; 
   for( i=length-1; i>=0; i--)//descending order display      
      comment += " "+movementPoint[i].pair +" "+DoubleToStr(movementPoint[i].value,0)+" ";
      
   comment += "\n  Trending in percentage: movement/volatility : 100 * Abs(Close-Open) / (High-Low) \n"; 
   for( i=length-1; i>=0; i--)//descending order display      
      comment += " "+trendingPercentage[i].pair +" "+DoubleToStr(trendingPercentage[i].value,2)+" ";
      
   return comment;   
}


TimeFrameData *timeFrameDataOpen;
TimeFrameData *timeFrameDataClose;




