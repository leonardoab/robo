#property copyright "Copyright 2019, Leonardo Bezerra."
#property link      "leonardoab89@gmail.com"
#property version   "1.0"
#property description "ROBOLAB_INDICE"
#include <RenkoCharts.mqh>
#include <Indicadores.mqh>


/* ======================================== RENKO =============================================================*/

// Inputs
//input string ativo = ""; 
string RenkoSymbol = "";
input ENUM_RENKO_WINDOW RenkoWindow = RENKO_NEW_WINDOW;    // GERAL =============== Abrir estrategia
input bool CarregarHistorico = true;                       // GERAL =============== Criar renko e carregar Historico
bool limitada = false;                                // GERAL =============== Limitada? 
input string AtivoEscolhido = "WDOX19";                    // GERAL =============== Ativo 

string Ativo = AtivoEscolhido;

input float loss = 5;                                    // GERAL =============== Valor em pontos Loss
input float gain = 3.5;                                    // GERAL =============== Valor em pontos Gain
input int QtdContratos = 1;                                // GERAL =============== Quantidade de Contratos

input string horarioFechar = "17:00";                      // FECHAMENTO  =============== Fechar posiooes abertar apos horario

input float Ticks_Weis_1 = 2;                             // WEIS 1 =============== Quantidade de Pontos
input bool Entrada_Ticks_Weis_1 = true;                    // WEIS 1 =============== Considerar Sinal
float Ticks_Weis_2 = Ticks_Weis_1 * 2;                     // WEIS 2 =============== Quantidade de Pontos
input bool Entrada_Ticks_Weis_2 = false;                   // WEIS 2 =============== Considerar Sinal
float Ticks_Weis_3 = Ticks_Weis_1 * 3;                     // WEIS 3 =============== Quantidade de Pontos
input bool Entrada_Ticks_Weis_3 = false;                   // WEIS 3 =============== Considerar Sinal

input bool usarHorarioEntrada = true;                      // H OPERAR =============== Ligar Indicador? 
input string horarioInicioPrimeiro = "09:00";              // H OPERAR =============== Inicio entrada primeiro periodo
input string horariofimPrimeiro = "12:00";                 // H OPERAR =============== Final entrada primeiro periodo
input string horarioInicioSegundo = "12:00";               // H OPERAR =============== Inicio entrada primeiro periodo
input string horariofimSegundo = "16:30";                  // H OPERAR =============== Final entrada primeiro periodo


input double RenkoSize = 4;                               // RENKO =============== Size(R)
input int RenkoTimer = 100;                                // RENKO =============== Tempo Atualizacao Grafico em milliseconds 

/* ============================================================================================================*/

ENUM_RENKO_TYPE RenkoType = RENKO_TYPE_TICKS;              //Type
bool RenkoWicks = true;                                    //Show Wicks



//int posicoes[7];

MqlRates BarData[195];

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

//double bufferWW[];
double ultimaReferencia = 0;

double valorUltimoTopo = 0;
double valorUltimoFundo = 1000000;

float volumeCompra = 0;
float volumeVenda = 0;


int Compra = 0;
float acumuladoCompra = 0;
float acumuladoVenda = 0;
int contadorAcumulado = 0;

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

    if (CarregarHistorico)
    {
        //Get Symbol
        if (RenkoSymbol != "")
            original_symbol = RenkoSymbol;
        //Check Period
        if (RenkoWindow == RENKO_CURRENT_WINDOW && ChartPeriod(0) != PERIOD_M1)
        {
            MessageBox("Renko must be M1 period!", __FILE__, MB_OK);
            ChartSetSymbolPeriod(0, Ativo, PERIOD_M1);
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
    
    RenkoOffline.Stop();
}
//+------------------------------------------------------------------+
//| Tick Event (for testing purposes only)                           |
//+------------------------------------------------------------------+
void OnTick()

{
    if (!IsStopped() && CarregarHistorico) RenkoOffline.Refresh();
    AtualizarIndicadores();
    MudouCadle();

    int total = OrdersTotal();

    bool fecha = IndicadoresOperacao.horarioFecharPosicao(horarioFechar, PrecoTick, Ativo);    

    /*if ((total == 1 && IndicadoresOperacao.OrdemAberta(AtivoEscolhido) == false) || fecha)
    {

        MqlTradeRequest request = { 0 };
        MqlTradeResult result = { 0 };        

        ulong order_ticket = OrderGetTicket(0);                 

        ZeroMemory(request);
        ZeroMemory(result);
        //--- setting the operation parameters     
        request.action = TRADE_ACTION_REMOVE;               
        request.order = order_ticket;                       
                                                            
        if (!OrderSend(request, result))
        PrintFormat("OrderSend error %d", GetLastError());                                                                
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order); 


    }   */

    MqlTick tick;
    SymbolInfoTick(Ativo, tick);


    if (tick.last == tick.ask) volumeCompra = volumeCompra + tick.volume_real;
 
    else volumeVenda = volumeVenda + tick.volume_real;
    
    if (volumeCompra != 0 && volumeVenda != 0) Compra = (volumeCompra / (volumeCompra + volumeVenda)) * 100;

    Comment("\nCOMPRA: " + volumeCompra +
             "\nCOMPRA %: " + Compra +
             "\nVENDA: " + volumeVenda +
             "\nQuantidade Candles WEIS 1: " + contadorWeis[0] +
             "\nSinal Candles WEIS 1: " + operacaoWeis_1 +
             "\nQuantidade Candles WEIS 2: " + contadorWeis[1] +
             "\nSinal Candles WEIS 2: " + operacaoWeis_2 +
             "\nQuantidade Candles WEIS 3: " + contadorWeis[2] +
             "\nSinal Candles WEIS 3: " + operacaoWeis_3               
             );



    if (mudouCandle)
    {
        operacaoWeis_1 = weis(Ticks_Weis_1, Entrada_Ticks_Weis_1, 0);
        operacaoWeis_2 = weis(Ticks_Weis_2, Entrada_Ticks_Weis_2, 1);
        operacaoWeis_3 = weis(Ticks_Weis_3, Entrada_Ticks_Weis_3, 2);

        
        if (
             operacaoWeis_1 == "Venda"
          && operacaoWeis_2 == "Venda"
          && operacaoWeis_3 == "Venda"
          && (IndicadoresOperacao.horariOperar(horarioInicioPrimeiro, horariofimPrimeiro, horarioInicioSegundo, horariofimSegundo) || !usarHorarioEntrada)
          && (Compra <= 50 || !CarregarHistorico)
          )
        {
            if (limitada) IndicadoresOperacao.VendaAlvosLimite(loss, gain, Ativo, QtdContratos);
            else IndicadoresOperacao.Venda(loss, gain, Ativo, QtdContratos);
            
            Print("------- DADOS VENDA");            
            Print(" Volume Compra: ", volumeCompra);
            Print(" Volume Compra: ", volumeVenda);
            Print("% AGRESSAO: ", Compra);
            Print(" Quantidade Candles WEIS 1: ", contadorWeis[0]);
            Print(" Quantidade Candles WEIS 2: ", contadorWeis[1]);
            Print(" Quantidade Candles WEIS 3: ", contadorWeis[2]);
            Print("------- FIM DADOS VENDA");
            
        }
        else if (
                  operacaoWeis_1 == "Compra"
               && operacaoWeis_2 == "Compra"
               && operacaoWeis_3 == "Compra"
               && (IndicadoresOperacao.horariOperar(horarioInicioPrimeiro, horariofimPrimeiro, horarioInicioSegundo, horariofimSegundo) || !usarHorarioEntrada)
               && (Compra >= 50 || !CarregarHistorico)
               )
        {        
            if (limitada) IndicadoresOperacao.CompraAlvosLimite(loss, gain, Ativo, QtdContratos);
            else IndicadoresOperacao.Compra(loss, gain, Ativo, QtdContratos);
            
            
            Print("------- DADOS COMPRA");            
            Print(" Volume Compra: ", volumeCompra);
            Print(" Volume Compra: ", volumeVenda);
            Print("% AGRESSAO: ", Compra);
            Print(" Quantidade Candles WEIS 1: ", contadorWeis[0]);
            Print(" Quantidade Candles WEIS 2: ", contadorWeis[1]);
            Print(" Quantidade Candles WEIS 3: ", contadorWeis[2]);
            Print("------- FIM DADOS COMPRA");
            
            
            
        }
    }


    if (mudouCandle)
    {
        volumeCompra = 0;
        volumeVenda = 0;
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
    int i = 194;

    CopyRates(_Symbol, PERIOD_M1, 1, 195, BarData);

    int k;

    for (k = 0; BarData[k].close == 0; k--)
    {
        i--;
    }

    PrecoFechamentoUltimoCandle = BarData[i].close;
    PrecoAberturaUltimoCandle = BarData[i].open;

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

string weis(int ticks, bool sinalTrigger, int weis)
{

    int i = 194;

    int k;

    for (k = 0; BarData[k].close == 0; k--)
    {
        i--;
    }

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