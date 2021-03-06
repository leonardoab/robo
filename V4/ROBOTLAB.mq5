#property copyright "Copyright 2019, Leonardo Bezerra."
#property link      "leonardoab89@gmail.com"
#property version   "1.0"
#property description "Renko"
#include <RenkoCharts.mqh>
#include <Indicadores.mqh>

/* ======================================== RENKO =============================================================*/

// Inputs
input string RenkoSymbol = "";                             //Symbol (Default = current)
ENUM_RENKO_TYPE RenkoType = RENKO_TYPE_TICKS;              //Type
input double RenkoSize = 4;                                //Size (R)
bool RenkoWicks = true;                                    //Show Wicks
input ENUM_RENKO_WINDOW RenkoWindow = RENKO_NEW_WINDOW;    //Window
input int RenkoTimer = 0;                                  //Timer in milliseconds (0 = Off)
input bool ModoBackTeste = true;                           //Modo Backteste


/* ============================================================================================================*/


int posicoes[5];

int mediaRapida = 144;      // Média Rapida
int media = 50;             // Média
int mediaLonga = 100;       // Média Longa

double valorPorTick[6];

int ValorMediaCurtaTick = 0;

MqlRates BarData[600];

double PrecoTick;
double PrecoFechamentoUltimoCandle;
double PrecoAberturaUltimoCandle;
double PrecoFechamentoPenultimoCandle = 1;

bool mudouCandle = false;

string operacaoWeis_1 = "Nada";
string operacaoWeis_2 = "Nada";
string operacaoWeis_3 = "Nada";

int contadorWeis[3];
string sinalWeis[3];

//int contador = 0;

double bufferWW[];
double ultimaReferencia = 0;

double valorUltimoTopo = 0;
double valorUltimoFundo = 1000000;
//string sinal = "";

input float Ticks_Weis_1 = 100; // Quantidade de Ticks
input float Ticks_Weis_2 = 200; // Quantidade de Ticks
input float Ticks_Weis_3 = 300; // Quantidade de Ticks

input float loss = 3.5; // Loss
input float gain = 1.5; // Gain

/* ============================================================================================================*/


// Renko Charts
RenkoCharts RenkoOffline();
Indicadores IndicadoresOperacao();
string original_symbol, custom_symbol;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

    if (!ModoBackTeste)
    {
        //Get Symbol
        if (RenkoSymbol != "")
            original_symbol = RenkoSymbol;
        //Check Period
        if (RenkoWindow == RENKO_CURRENT_WINDOW && ChartPeriod(0) != PERIOD_M1)
        {
            MessageBox("Renko must be M1 period!", __FILE__, MB_OK);
            ChartSetSymbolPeriod(0, _Symbol, PERIOD_M1);
            return (INIT_SUCCEEDED);
        }
        //Check Symbol
        if (!RenkoOffline.ValidateSymbol(original_symbol))
        {
            MessageBox("Invalid symbol error. Select a valid symbol!", __FILE__, MB_OK);
            return (INIT_FAILED);
        }
        //Setup Renko
        if (!RenkoOffline.Setup(original_symbol, RenkoType, RenkoSize, RenkoWicks))
        {
            MessageBox("Renko setup error. Check error log!", __FILE__, MB_OK);
            return (INIT_FAILED);
        }
        //Create Custom Symbol
        RenkoOffline.CreateCustomSymbol();
        RenkoOffline.ClearCustomSymbol();
        custom_symbol = RenkoOffline.GetSymbolName();
        //Load History
        RenkoOffline.UpdateRates();
        RenkoOffline.ReplaceCustomSymbol();
        //Chart Setup
        RenkoOffline.Start(RenkoWindow);
        if (RenkoTimer > 0) EventSetMillisecondTimer(RenkoTimer);
    }

    IndicadoresOperacao.IncializaIndicadores(posicoes, mediaRapida, media, mediaLonga);
    
    contadorWeis[0] = 0; 
    contadorWeis[1] = 0; 
    contadorWeis[2] = 0; 
    
     sinalWeis[0] = ""; 
    sinalWeis[1] = ""; 
    sinalWeis[2] = ""; 
 

    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //---
    RenkoOffline.Stop();
}
//+------------------------------------------------------------------+
//| Tick Event (for testing purposes only)                           |
//+------------------------------------------------------------------+
void OnTick()
{
    if (!IsStopped() && !ModoBackTeste) RenkoOffline.Refresh();
    AtualizarIndicadores();
    MudouCadle();

   if (mudouCandle)    
   {
   
   
   operacaoWeis_1 = weis(Ticks_Weis_1,true , 0); 
   operacaoWeis_2 = weis(Ticks_Weis_2,false , 1);
   
   
   if (operacaoWeis_1 == "Compra" && operacaoWeis_2 == "Compra"){
   
   int kk;
   kk = 2;
   
   }
   
   operacaoWeis_3 = weis(Ticks_Weis_3,false , 2);
   
   if (operacaoWeis_1 == "Venda" && operacaoWeis_2 == "Venda" && operacaoWeis_3 == "Venda"){
   
   
   IndicadoresOperacao.Venda( loss,gain,_Symbol);
   
   }
   else if (operacaoWeis_1 == "Compra" && operacaoWeis_2 == "Compra" && operacaoWeis_3 == "Compra" ){
   
   IndicadoresOperacao.Compra( loss,gain,_Symbol);
    
   }
   
   
   
    
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
//+------------------------------------------------------------------+


void AtualizarIndicadores()
{

    IndicadoresOperacao.AtualizaIndicadoresTick(posicoes, valorPorTick);
    ValorMediaCurtaTick = valorPorTick[0];

    CopyRates(Symbol(), Period(), 1, 600, BarData);

    PrecoFechamentoUltimoCandle = BarData[0].close;
    PrecoAberturaUltimoCandle = BarData[0].open;

    PrecoTick = SymbolInfoDouble(_Symbol, SYMBOL_LAST);    

}

void MudouCadle()
{
    if (PrecoFechamentoUltimoCandle != PrecoFechamentoPenultimoCandle)
    {
        PrecoFechamentoPenultimoCandle = PrecoFechamentoUltimoCandle;

        mudouCandle = true;

    }

    else
    {
        mudouCandle = false;
    }
}

string weis(int ticks,bool sinalTrigger,int weis)
{

    int i = 599;
    

    if (ultimaReferencia == 0) ultimaReferencia = BarData[i].close;

    if (BarData[i].close >= BarData[i - 1].close && (sinalWeis[weis] == "" || sinalWeis[weis] == "Compra"))
    {

        sinalWeis[weis] = "Compra";
        contadorWeis[weis]++;
        
        if (sinalTrigger) return "Nada";
        else return "Compra";
        

    }

    else if (BarData[i].close >= BarData[i - 1].close && (sinalWeis[weis] == "" || sinalWeis[weis] == "Venda"))
    {

        int x = 0;

        valorUltimoFundo = 1000000;

        for (x = 0; x < contadorWeis[weis]; x++)
        {

            if (BarData[i - x].close < valorUltimoFundo) valorUltimoFundo = BarData[i - x].close;
        }

        if (BarData[i].close - valorUltimoFundo > ticks)
        {
            sinalWeis[weis] = "Compra";
            contadorWeis[weis] = 0;            
            return "Compra";
            
        }

        else
        {
            sinalWeis[weis] = "Venda";
            contadorWeis[weis]++;
            if (sinalTrigger) return "Nada";
            else return "Venda";
            
        }


    }
    else if (BarData[i].close < BarData[i - 1].close && (sinalWeis[weis] == "" || sinalWeis[weis] == "Compra"))
    {

        valorUltimoTopo = 0;
        int x = 0;

        for (x = 0; x < contadorWeis[weis]; x++)
        {
            if (BarData[i - x].close > valorUltimoTopo) valorUltimoTopo = BarData[i - x].close;
        }

        if (valorUltimoTopo - BarData[i].close > ticks)
        {            
            sinalWeis[weis] = "Venda";
            contadorWeis[weis] = 0;            
            return "Venda";
            
            
        }

        else
        {         
            sinalWeis[weis] = "Compra";
            contadorWeis[weis]++;
            if (sinalTrigger) return "Nada";
            else return "Compra";
            
        }

    }
    else if (BarData[i].close < BarData[i - 1].close && (sinalWeis[weis] == "" || sinalWeis[weis] == "Venda"))
    {
        sinalWeis[weis] = "Venda";
        contadorWeis[weis]++;
        if (sinalTrigger) return "Nada";
        else return "Venda";
        

    }
    
    return "Nada";


}