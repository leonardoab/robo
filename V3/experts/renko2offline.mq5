//+------------------------------------------------------------------+
//|                                                Renko2offline.mq5 |
//|                                Copyright 2018, Guilherme Santos. |
//|                                               fishguil@gmail.com |
//|                                                Renko 2.0 Offline |
//|                                                                  |
//|2018-03-28:                                                       |
//| Fixed events and time from renko rates                           |
//|2018-04-02:                                                       |
//| Fixed renko open time on renko rates                             |
//|2018-04-10:                                                       |
//| Add tick event and remove timer event for tester                 |
//|2018-04-30:                                                       |
//| Correct volume on renko bars, wicks, performance, and parameters |
//|2018-05-10:                                                       |
//| Now with timer event                                             |
//|2018-05-16:                                                       |
//| New methods and MiniChart display by Marcelo Hoepfner            |
//|2018-06-21:                                                       |
//| New library with custom tick, performance and other improvements |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Guilherme Santos."
#property link      "fishguil@gmail.com"
#property version   "2.0"
#property description "Renko 2.0 Offline"
#include <RenkoCharts.mqh>
#include <Indicadores.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
// Inputs
input string RenkoSymbol = "";                              //Symbol (Default = current)
input ENUM_RENKO_TYPE RenkoType = RENKO_TYPE_TICKS;         //Type
input double RenkoSize = 5;                                //Brick Size (Ticks, Pips or Points)
input bool RenkoWicks = true;                               //Show Wicks
input ENUM_RENKO_WINDOW RenkoWindow = RENKO_CURRENT_WINDOW; //Window
input int RenkoTimer = 100;                                //Timer in milliseconds (0 = Off)


/*-------------------------- FIM RENKO -------------------------------------------------------------*/



MqlRates BarData[1];
MqlRates BarDataHist[65];
int MediaHist[65];


int contador = 0;

int posicoes[5];
double topoFundo[2];
double valorPorTick[6];

int mediaRapida = 20;
int media = 50;
int mediaLonga = 100;


input int loss = 100;
input int margem = 100;



int ValorMediaCurtaTick;
int ValorMediaTick;
int ValorMediaLongaTick;
int ValorBandaInferiorTick;
int ValorBandaSuperiorTick;

int ValorMACDTick;

int ValorMACDTickNormalizada;
int ValorMediaCurtaTickNormalizada;
int ValorMediaTickNormalizada;
int ValorMediaLongaTickNormalizada;
int ValorBandaSuperiorTickNormalizada;
int ValorBandaInferiorTickNormalizada;

double valorUltimoTopo = 0;
double valorUltimoFundo = 0;



int QuantidadeCandleOperacao = 0;
input int ToleranciaLoss = 90;
int AguardeCandles = 3;
int HoraIni = 15;

input int precoSubida = 25;
input int precoSubidaLoss = 75;
input int margemGain = 50;



int UltimoFundo = 1;
int UltimoTopo = 1;
int Contador = 0;

double PrecoTick;
double PrecoFechamentoUltimoCandle;
double PrecoFechamentoPenultimoCandle = 1;
double PrecoFechamentoP = 1;
double PrecoFechamentoPenultimoCandleTick = 1;  
double PrecoAberturaUltimoCandle;


double StopLossCorrente = 1;
double GainCorrente = 1;
double PrecoAberturaPosicao = 1;


double ValorUltimoTopo = 0;
double ValorUltimoFundo = 0;

double ValorTopoFundo = 0;
bool SinalRepique = false;



ulong PositionTicket = 1;

double MediaCurtaArray[];
double MediaLongaArray[];
double MACDArray[];
double SuperiorBandArray[];
double InferiorBandArray[];
bool modoSimulado = true;

double ask;
double bid;





// Renko Charts
//RenkoCharts RenkoOffline();
Indicadores IndicadoresOperacao();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

/* =================================================== FUNCOES BASE ==============================================================*/

void AtualizarIndicadores()
{

    CopyRates(Symbol(), Period(), 1, 1, BarData);

    PrecoTick = SymbolInfoDouble(_Symbol, SYMBOL_LAST);   

    PrecoFechamentoUltimoCandle = BarData[0].close;
    PrecoAberturaUltimoCandle = BarData[0].open;
    
    IndicadoresOperacao.AtualizaIndicadoresTick(posicoes,valorPorTick);        
    
    ValorMediaCurtaTick = valorPorTick[0];
    //ValorMediaTick = valorPorTick[1];
    //ValorMediaLongaTick = valorPorTick[2];
    ValorBandaSuperiorTick = valorPorTick[3];
    ValorBandaInferiorTick = valorPorTick[4];
    ValorMACDTick = valorPorTick[5];

    ValorBandaSuperiorTickNormalizada = ValorBandaSuperiorTick - MathMod(ValorBandaSuperiorTick, 5);
    ValorBandaInferiorTickNormalizada = ValorBandaInferiorTick - MathMod(ValorBandaInferiorTick, 5);
    ValorMACDTickNormalizada = ValorMACDTick - MathMod(ValorMACDTick, 5);
    ValorMediaCurtaTickNormalizada = ValorMediaCurtaTick - MathMod(ValorMediaCurtaTick, 5);
    ValorMediaTickNormalizada = ValorMediaTick - MathMod(ValorMediaTick, 5);
    ValorMediaLongaTickNormalizada = ValorMediaLongaTick - MathMod(ValorMediaLongaTick, 5);


    if (IndicadoresOperacao.OrdemAberta(Symbol()))
    {

        PositionTicket = PositionGetInteger(POSITION_TICKET);
        StopLossCorrente = PositionGetDouble(POSITION_SL);
        GainCorrente = PositionGetDouble(POSITION_TP);
        PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);
    }

}


/* =================================================== FIM FUNCOES BASE ==============================================================*/


int OnInit()
{     
  //  if (!modoSimulado) RenkoOffline.InicializaRenkoChart( RenkoSymbol, RenkoWindow, RenkoSize, RenkoWicks,  RenkoTimer, RenkoType);
    IndicadoresOperacao.IncializaIndicadores(posicoes,mediaRapida, media, mediaLonga);    
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
    //if (!modoSimulado) RenkoOffline.Refresh();      

    AtualizarIndicadores();
    
    
    if (PositionSelect(_Symbol) == true)
    {
    
    
              
        
         
         bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         
         
         
         PositionTicket = PositionGetInteger(POSITION_TICKET);
         StopLossCorrente = PositionGetDouble(POSITION_SL);
         
         PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);

        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY )
        {


            trade.PositionModify(PositionTicket, StopLossCorrente,ValorMediaCurtaTickNormalizada);


        }

        else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL )
        {


            trade.PositionModify(PositionTicket, StopLossCorrente, ValorMediaCurtaTickNormalizada);

        }
        
        }
    
    
   
    // AJUSTAR PARA SOMENTE NA MUDANCA DE CANDLE 


    if (// REGRAS PARA COMPRA INICIO
        MudouCadle()
        && operar()        
        && ValorMediaCurtaTick - PrecoTick > margem    
        )
    {    
       
        
        IndicadoresOperacao.Compra(loss,ValorMediaCurtaTickNormalizada - PrecoTick,_Symbol);
        
    }

    else if (// REGRAS PARA VENDA INICIO
       MudouCadle()
       && operar()       
       && PrecoTick - ValorMediaCurtaTick > margem       
       
       )
    {         
        
        
        IndicadoresOperacao.Venda(loss,PrecoTick - ValorMediaCurtaTickNormalizada,_Symbol);
        

    }

    
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

/*+------------------------------------------------------------------+
 Mudanca de Candle
 true -> Mudou de candle
 false -> Ainda esta no mesmo candle 
//+------------------------------------------------------------------+*/

bool MudouCadle()
{
    if (PrecoFechamentoUltimoCandle != PrecoFechamentoPenultimoCandle)
    {
        PrecoFechamentoPenultimoCandle = PrecoFechamentoUltimoCandle;
        
        if (operar2()) {
        
        CopyRates(Symbol(), Period(), 1,60, BarDataHist);
        MediaHist[contador] = ValorMediaCurtaTick;
        contador ++;
        
        }
        
        return true;
    }

    else
    {
        return false;
    }
}

bool operar()
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    int horaAtual = StringToInteger(StringSubstr(horaCorrenteStr, 0, 2));

    if (horaAtual >=  12 && horaAtual < 14){
        
        
        processarLimite ();
        
        
        return true;
        
        }
        
    else return false;

}


bool operar2()
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    int horaAtual = StringToInteger(StringSubstr(horaCorrenteStr, 0, 2));

    if (horaAtual ==  11 )
        return true;
    
    else {
    
    contador = 0;
    return false;
    
    }

}

void processarLimite () {

int x;

for (x = 0; x <= 56; x++)
    {          
            if (MediaHist[x] - BarDataHist[x +1 ].close  > valorUltimoTopo) valorUltimoTopo = MediaHist[x] - BarDataHist[x + 1].close ;          
            if (MediaHist[x] - BarDataHist[x + 1].close < valorUltimoFundo) valorUltimoFundo = MediaHist[x] - BarDataHist[x + 1].close  ;                      
    }   




}



