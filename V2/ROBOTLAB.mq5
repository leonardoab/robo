#property copyright "Copyright 2019, Leonardo Bezerra."
#property link      "leonardoab89@gmail.com"
#property version   "1.0"
#property description "ROBO LAB"
#include <RenkoCharts.mqh>
#include <Indicadores.mqh>

/* ======================================== RENKO =============================================================*/

// Inputs

input string RenkoSymbol = "";                             // GERAL =============== Ativo (Default = current)
input bool ModoBackTeste = true;                           // GERAL =============== Backteste 
input ENUM_RENKO_WINDOW RenkoWindow = RENKO_NEW_WINDOW;    // GERAL =============== Abrir estrategia

input string horarioInicio = "09:00" ;                     // GERAL =============== A partir de que horas pode abrir operacoes
input string horariofim = "18:00"    ;                     // GERAL =============== Ate que horas pode abrir operacoes

input float loss = 3.5; // GERAL =============== Valor em pontos Loss
input float gain = 1.5; // GERAL =============== Valor em pontos Gain
input int QtdContratos = 1; // GERAL =============== Quantidade de Contratos

input int mediaRapida = 144;      // MEDIA =============== Valor EXP
input bool usarmedia = true;      // MEDIA =============== Ativar

input int mediaADX = 9;      // ADX ================= Valor da Media do ADX
input float valorRefernciaADX = 50;      // ADX ================= Valor Minimo ADX
input bool crescenteadx = true;      // ADX ================= Valor Crescente

input double RenkoSize = 4;                                // RENKO =============== Size(R)
input int RenkoTimer = 0;                                  // RENKO =============== Tempo Atualizacao Grafico em milliseconds 

ENUM_RENKO_TYPE RenkoType = RENKO_TYPE_TICKS;              //Type
bool RenkoWicks = true;                                    //Show Wicks

float valorTick2 = 0;




/* ============================================================================================================*/

int posicoes[6];


int media = 50;             // Média
int mediaLonga = 100;       // Média Longa

double valorPorTick[8];

double ValorMediaCurtaTick = 0;
double ValorADXTick = 0;
double ValorADXCandleAnterior = 0;

MqlRates BarData[600];
MqlTick myprice;

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

double bufferWW[];
double ultimaReferencia = 0;

double valorUltimoTopo = 0;
double valorUltimoFundo = 1000000;



input float Ticks_Weis_1 = 1.5;          // WEIS 1 =============== Quantidade de Pontos
input bool Entrada_Ticks_Weis_1 = true;  // WEIS 1 =============== Considerar Sinal
input float Ticks_Weis_2 = 3;            // WEIS 2 =============== Quantidade de Pontos
input bool Entrada_Ticks_Weis_2 = false; // WEIS 2 =============== Considerar Sinal
input float Ticks_Weis_3 = 4.5;          // WEIS 3 =============== Quantidade de Pontos
input bool Entrada_Ticks_Weis_3 = false; // WEIS 3 =============== Considerar Sinal


input float distranciaGain = 0.5;       // TRAIL =============== Distancia do Gain para Ativar (Em Pontos)
input float distrancialossPreco = 0.5;  // TRAIL =============== Distancia do Novo Loss do Preco (Em Pontos)
input float proximoAlvo = 2;            // TRAIL =============== Proximo Alvo                  (Em Pontos)


//IndicadoresOperacao.StopGainMovel(margemGain,precoSubidaLoss,precoSubida,Symbol(),PrecoTick);



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

    IndicadoresOperacao.IncializaIndicadores(posicoes, mediaRapida, media, mediaLonga,mediaADX);

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
    
    IndicadoresOperacao.StopGainMovel(distranciaGain,distrancialossPreco,proximoAlvo,Symbol(),PrecoTick);

    if (mudouCandle)
    {
        operacaoWeis_1 = weis(Ticks_Weis_1, Entrada_Ticks_Weis_1, 0);
        operacaoWeis_2 = weis(Ticks_Weis_2, Entrada_Ticks_Weis_2, 1);
        operacaoWeis_3 = weis(Ticks_Weis_3, Entrada_Ticks_Weis_3, 2);
        
        IndicadoresOperacao.StopGainMovel(distranciaGain,distrancialossPreco,proximoAlvo,Symbol(),PrecoTick);
        
        
        //IndicadoresOperacao.StopGainMovel(margemGain,precoSubidaLoss,precoSubida,Symbol(),PrecoTick);

        if (
             operacaoWeis_1 == "Venda"
          && operacaoWeis_2 == "Venda"
          && operacaoWeis_3 == "Venda"
          && (ValorMediaCurtaTick > PrecoFechamentoUltimoCandle || !usarmedia)
          && ValorADXTick > valorRefernciaADX 
          && (ValorADXTick > ValorADXCandleAnterior || !crescenteadx)
          && IndicadoresOperacao.horariOperar(horarioInicio, horariofim)
          )
        {
            IndicadoresOperacao.Venda(loss, gain, _Symbol,QtdContratos);

        }
        else if (
                  operacaoWeis_1 == "Compra"
               && operacaoWeis_2 == "Compra"
               && operacaoWeis_3 == "Compra"
               && (ValorMediaCurtaTick < PrecoFechamentoUltimoCandle || !usarmedia)
               && ValorADXTick > valorRefernciaADX 
               && (ValorADXTick > ValorADXCandleAnterior || !crescenteadx)
               && IndicadoresOperacao.horariOperar(horarioInicio, horariofim)
               
               )
        {
            IndicadoresOperacao.Compra(loss, gain, _Symbol,QtdContratos);

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
    ValorADXCandleAnterior = valorPorTick[7];
    ValorADXTick = valorPorTick[6];

    CopyRates(Symbol(), Period(), 1, 600, BarData);

    PrecoFechamentoUltimoCandle = BarData[599].close;
    PrecoAberturaUltimoCandle = BarData[599].open;

    PrecoTick = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
    
    
    
    
    
    //CopyRates(Symbol(), Period(), 1, 30, myprice);
    
    //valorTick2 = SymbolInfoTick(Symbol(),myprice);

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

string weis(int ticks, bool sinalTrigger, int weis)
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