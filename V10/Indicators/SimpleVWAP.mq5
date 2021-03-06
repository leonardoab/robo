//+------------------------------------------------------------------+
//|                                                   SimpleVWAP.mq5 |
//|                            Copyright 2018-2019, Conrado Carvalho |
//|                                           https://conrado.mat.br |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2018-2019, Conrado Carvalho"
#property link        "https://conrado.mat.br"
#property description "Simple Volume Weighted Average Price"
#property version     "2.00"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers      1
#property indicator_plots        1
#property indicator_type1        DRAW_LINE
#property indicator_color1       clrBlue
#property indicator_width1       1
//---
//--- input parameters
input int InpPeriod=10;  // Weighted average period
//---
//--- indicator buffers 
double ExtVWAPBuffer[];
//---
int ExtPeriod;
//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator validations
   if(InpPeriod<2)
     {
      ExtPeriod=10;
      Print("Incorrect value for input variable InpPeriod = ",InpPeriod,
            "Indicator will use value = ",ExtPeriod," for calculations.");
     }
   else
      ExtPeriod=InpPeriod;
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtVWAPBuffer,INDICATOR_DATA);
//--- name for indicator label
   IndicatorSetString(INDICATOR_SHORTNAME,"Simple VWAP("+string(ExtPeriod)+")");
//--- name for index label
   PlotIndexSetString(0,PLOT_LABEL,"Simple VWAP("+string(ExtPeriod)+")");
//--- set number of digits    
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| VWAP OnCalculate function                                        |
//+------------------------------------------------------------------+
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
//--- check for rates count
   if(rates_total<ExtPeriod)
      return(0);
   int pos=prev_calculated-1;
   if(pos<=ExtPeriod)
   {
      for(int i=0;i<ExtPeriod;i++)
         ExtVWAPBuffer[i]=0.0;
      pos=ExtPeriod+1;   
   }      
//--- main cycle
   for(int i=pos;i<rates_total && !IsStopped();i++)
     {
      //--- calculate VWAP
      ExtVWAPBuffer[i]=CalculateVWAP(i,open,high,low,close,volume);
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Volume Weighted Average Price                                    |
//+------------------------------------------------------------------+
double CalculateVWAP(int position,
                     const double &open[],
                     const double &high[],
                     const double &low[],
                     const double &close[],
                     const long &volume[])
  {
   double price=0.0;
   double sum=0.0;
   double vwap=0.0;
   long weightsum=0.0;
   for(int i=0;i<ExtPeriod;i++)
     {
      price=(high[position-i]+low[position-i]+close[position-i])/3; // typical price
      sum+=price*volume[position-i];
      weightsum+=volume[position-i];
     }
   if(weightsum==0) weightsum=1;  
   vwap=sum/weightsum;
   return(vwap);
  }
//+------------------------------------------------------------------+
