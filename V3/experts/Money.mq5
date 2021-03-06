//+------------------------------------------------------------------+
#include <RenkoCharts.mqh>
#include <Indicadores.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

#property copyright "Copyright 2019, Leonardo Bezerra"
#property link      "leonardoab89@gmail.com"
#property version   "2.0"
#property description "Soma o Volume Financeiro até que de um sinal de reversao, Compra: Quando o maior fechamento se distancia x ticks para baixo, Venda Quando o menor fechamento se distancia x ticks para cima"


#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Weis Volume Waves"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_width1  4
#property indicator_color1  clrGreen, clrRed



// Inputs

input ENUM_APPLIED_VOLUME inpVolumeType = VOLUME_REAL;      // Volume Type to use on waves

/*-------------------------- FIM RENKO -------------------------------------------------------------*/

MqlRates BarData[3];
MqlRates BarDataHist[30];

int contador = 0 ;

double bufferWW[];
double bufferColors[];
double ultimaReferencia = 0;

double valorUltimoTopo = 0;
double valorUltimoFundo = 1000000;

bool modoSimulado = true;
string sinal = "";

input int ticks = 100; // Quantidade de Ticks

// Renko Charts
RenkoCharts RenkoOffline();
Indicadores IndicadoresOperacao();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
    
    
    SetIndexBuffer( 0, bufferWW, INDICATOR_DATA );
    SetIndexBuffer( 1, bufferColors, INDICATOR_COLOR_INDEX );

    IndicatorSetString( INDICATOR_SHORTNAME, "Weis Volume Waves" );

    
    
    
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //---
    //RenkoOffline.Stop();
}
//+------------------------------------------------------------------+
//| Tick Event (for testing purposes only)                           |
//+------------------------------------------------------------------+
void OnTick()
{
    if (!modoSimulado) RenkoOffline.Refresh();   
}
//+------------------------------------------------------------------+
//| Book Event                                                       |
//+------------------------------------------------------------------+
void OnBookEvent(const string& symbol)
{
    OnTick();
}
//+------------------------------------------------------------------+
//| Timer Event (Turn off when backtesting)                          |
//+------------------------------------------------------------------+
void OnTimer()
{
    OnTick();
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
                const int &spread[])   {

    int i, barsToProcess, shouldStartIn = 2;
    double vol;

    if (rates_total < shouldStartIn)  { return 0; }   // no enough bars to calculate the waves...

    // if it is the first start of calculation of the indicator or if the number of values in the indicator changed
    // or if it is necessary to calculate the indicator for two or more bars (it means something has changed in the price history)
    if (prev_calculated == 0 || rates_total > prev_calculated+1) {
        bufferWW[0] = ( inpVolumeType==VOLUME_TICK ? (double)tick_volume[0] : (double)volume[0] );
        barsToProcess = rates_total;
    } else {
        // it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
        // for calculation not more than one bar is added
        barsToProcess = (rates_total-prev_calculated) + 1;
    }


    // calculates the volume waves...
    for (i=rates_total-MathMax(shouldStartIn,barsToProcess-shouldStartIn);  i<rates_total && !IsStopped();  i++)  {

        vol = ( inpVolumeType==VOLUME_TICK ? (double)tick_volume[i] : (double)volume[i] );   // type casts to the correct format of the buffer...
        
        //CopyRates(Symbol(), Period(), 1,10, BarDataHist);
       
       
        
        
      if (ultimaReferencia == 0)   ultimaReferencia = close[i];

      if (close[i] >= close[i-1] && (sinal == ""  || sinal == "Compra")){
      
                bufferWW[i]     = bufferWW[i-1] + vol;
                bufferColors[i] = 0;
                sinal = "Compra";
                contador ++;
      
      }
      else if (close[i] >= close[i-1] && (sinal == ""  || sinal == "Venda") ){
      
      
       int x = 0;    
                
                 valorUltimoFundo = 1000000;
            
                for (x = 0; x < contador; x++)
                {          
                  
                        if (close[i - x] < valorUltimoFundo) valorUltimoFundo = close[i - x] ;                      
                }   
      
              
               if ( close[i] - valorUltimoFundo > ticks){
               
                  bufferWW[i]     = vol;
                  bufferColors[i] = 0;
                  sinal = "Compra";
                  contador = 0;
                  
               }
               
               else {
               
                bufferWW[i]     = bufferWW[i-1] + vol;
                bufferColors[i] = 1;
                sinal = "Venda";
                contador ++;
               
               
               }
      
      
      }
      else if (close[i] < close[i-1] && (sinal == ""  || sinal == "Compra")){
      
                    
                 valorUltimoTopo = 0;
                
                int x = 0;  
                for (x = 0; x < contador; x++)
                {          
                        if (close[i - x] > valorUltimoTopo) valorUltimoTopo = close[i - x] ;          
                                            
                }   
                  
              
               if (valorUltimoTopo - close[i] > ticks){
               
                  bufferWW[i]     = vol;
                  bufferColors[i] = 1;
                  sinal = "Venda";
                  contador = 0;
                  
               }
               
               else {
               
                bufferWW[i]     = bufferWW[i-1] + vol;
                bufferColors[i] = 0;
                sinal = "Compra";
                contador ++;
               
               
               }
      
      
      
      }
      else if (close[i] < close[i-1] && (sinal == ""  || sinal == "Venda")){
      
                bufferWW[i]     = bufferWW[i-1] + vol;
                bufferColors[i] = 1;
                sinal = "Venda";
                contador ++;
      
      }



      
    }

    return rates_total;
}
    