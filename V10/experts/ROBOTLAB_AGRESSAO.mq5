#property copyright "Copyright 2019, Leonardo Araujo Bezerra."
#property link      "leonardoab89@gmail.com"
#property version   "4.0"
#property description "ROBOLAB_INDICE"

/* ======================================== INCLUDES =============================================================*/

#include <RenkoCharts.mqh>
#include <Indicadores.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade operacao;

/* ======================================== INPUT VARIAVEIS =============================================================*/

input ENUM_RENKO_WINDOW RenkoWindow = RENKO_NEW_WINDOW;    // GERAL => Abrir estrategia
input bool CarregarHistorico = true;                       // GERAL => Criar renko e carregar Historico
input string Ativo = "WING20";                             // GERAL => Ativo 
input float loss = 100;                                    // GERAL => Valor em pontos Loss
input float gain = 100;                                    // GERAL => Valor em pontos Gain
input int QtdContratos = 1;                                // GERAL => Quantidade de Contratos
input string horario = "17:00";                            // GERAL => Horario Maximo Abrir
input string horarioFecha = "17:45";                       // GERAL => Horario Fechamento
input int metaGain = 30;                                   // GERAL => Quantidade Maximo Gain
input int metaLoss = -75;                                  // GERAL => Quantidade Maximo Loss
input int mediaRapida = 3;                                 // Média => Média Rapida
input int mediaLonga = 9;                                  // Média => Média Lenta
input float Ticks_Weis_1 = 75;                             //  WEIS => Quantidade de Pontos
input double RenkoSize = 10;                               // RENKO => Tamanho Renko
input int valorSombraMaximo = 1000;                        // CANDL => Tamanho Max Sombra
input int valorPreformadoMinimo = 0;                       // CANDL => Tamanho Candle Pre
input bool agressao = false;                                     // AGRES => Usar Agressao
input int agressaoMinimaCompra = 50;                       // GERAL => Agressão mínima compra
input int agressaoMinimaVenda = 50;                        // GERAL => Agressão mínima venda


/* ======================================== VARIAVEIS =============================================================*/

ENUM_RENKO_TYPE RenkoType = RENKO_TYPE_TICKS;

MqlRates BarData[100];

bool mudouCandle = false;

string RenkoSymbol = "";
string original_symbol, custom_symbol;
string operacaoWeis_1 = "Nada";
string operacaoWeis_2 = "Nada";
string sinalWeis[2];

int contadorWeis[2];
int posicoes[2];
int RenkoTimer = 100;
int obv;
int AgressaoCompra = 0;

double PrecoFechamentoPenultimoCandle = 1;

double PrecoTick = 0;
double valorPorTick[2];
double obvArray[];

double PrecoAbertura = 0;
double PrecoSombra = 0;

bool ordemAberta = false;
bool operando = false;



float volumeCompra = 0;
float volumeVenda = 0;
float acumuladoCompra = 0;
float acumuladoVenda = 0;


/* ============================================================================================================*/

// Renko Charts
RenkoCharts RenkoOffline();
Indicadores IndicadoresOperacao();

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
        if (!RenkoOffline.Setup(original_symbol, RenkoType, RenkoSize, true))
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

    sinalWeis[0] = "";
    sinalWeis[1] = "";


    IndicadoresOperacao.IncializaIndicadores(posicoes, mediaRapida, mediaLonga);    

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

    IndicadoresOperacao.AtualizaIndicadoresTick(posicoes, valorPorTick);    

    CopyRates(_Symbol, PERIOD_M1, 1, 100, BarData);

    mudouCandle = VerificarMudouCandle();

    ordemAberta = IndicadoresOperacao.OrdemAberta(Ativo);

    if (CarregarHistorico) if (ordemAberta) IndicadoresOperacao.operacaoCorrente(loss, gain, Ativo);   
    
    if (agressao){
    
    MqlTick tick;

    SymbolInfoTick(Ativo, tick);

    if (tick.last == tick.ask) volumeCompra = volumeCompra + tick.volume_real;
    else if (tick.last == tick.bid) volumeVenda = volumeVenda + tick.volume_real;

    if (volumeCompra != 0 && volumeVenda != 0) AgressaoCompra = (volumeCompra / (volumeCompra + volumeVenda)) * 100;

    Comment( "\nCOMPRA: " + volumeCompra +
             "\nCOMPRA %: " + AgressaoCompra +
             "\nVENDA: " + volumeVenda +
             "\nVENDA %: " + (100 - AgressaoCompra) +
             "\nQuantidade Candles WEIS 1: " + contadorWeis[0] +
             "\nSinal Candles WEIS 1: " + operacaoWeis_1 +
             "\nQuantidade Candles WEIS 2: " + contadorWeis[1] +
             "\nSinal Candles WEIS 2: " + operacaoWeis_2
             );
    
     }

    if (mudouCandle)
    {       

        if (ordemAberta) horarioFecharPosicaoIndice(horarioFecha, SymbolInfoDouble(_Symbol, SYMBOL_LAST), _Symbol, QtdContratos);
        
        operando = false;
        
        //}

        operacaoWeis_1 = IndicadoresOperacao.weis(Ticks_Weis_1, true, 0, sinalWeis, contadorWeis, 100, BarData);
        operacaoWeis_2 = IndicadoresOperacao.weis((Ticks_Weis_1 * 2), false, 1, sinalWeis, contadorWeis, 100, BarData);

        if (operacaoWeis_1 == "Venda" 
             && operacaoWeis_2 == "Venda" 
             && !ordemAberta 
             //&& (valorPorTick[0] < valorPorTick[1]) 
             && IndicadoresOperacao.horaOperar(horario)             
             && !operando
             && !funcao_verifica_meta_ou_perda_atingida("Meta", metaLoss, metaGain, true)
             && ((100 - AgressaoCompra) >= agressaoMinimaVenda || !agressao)
           )
        {            

            PrecoTick = SymbolInfoDouble(Ativo, SYMBOL_LAST);
            PrecoAbertura = iOpen(Ativo,PERIOD_M5,0);
            PrecoSombra = iLow(Ativo,PERIOD_M5,0);
            operando = true;
            
            if (PrecoTick < PrecoAbertura && PrecoAbertura - PrecoSombra < valorSombraMaximo && PrecoAbertura - PrecoTick > valorPreformadoMinimo) operacao.Sell(QtdContratos, Ativo, PrecoTick, PrecoTick + loss, PrecoTick - gain,
            ":P:" + PrecoTick + ":C0:" + contadorWeis[0] + ":OP1:" +  operacaoWeis_1 + ":C1:" + contadorWeis[1] + ":OP2:" +  operacaoWeis_2 + ":PA:" + PrecoAbertura + ":SO:" + (PrecoAbertura - PrecoSombra) + ":CP:" + (PrecoAbertura - PrecoTick));
            
        }
        else if (operacaoWeis_1 == "Compra" 
                  && operacaoWeis_2 == "Compra" 
                  && !ordemAberta 
                  //&& (valorPorTick[0] > valorPorTick[1]) 
                  && IndicadoresOperacao.horaOperar(horario)                  
                  && !operando
                  && !funcao_verifica_meta_ou_perda_atingida("Meta", metaLoss, metaGain, true)
                  && (AgressaoCompra >= agressaoMinimaCompra || !agressao)
                 )
        {            
            PrecoTick = SymbolInfoDouble(Ativo, SYMBOL_LAST);
            PrecoAbertura = iOpen(Ativo,PERIOD_M5,0);
            PrecoSombra = iHigh(Ativo,PERIOD_M5,0);
            operando = true;
            
            if (PrecoTick > PrecoAbertura && PrecoSombra - PrecoAbertura < valorSombraMaximo && PrecoTick - PrecoAbertura  > valorPreformadoMinimo )  operacao.Buy(QtdContratos, Ativo, PrecoTick, PrecoTick - loss, PrecoTick + gain,
            ":P:" + PrecoTick + ":C0:" + contadorWeis[0] + ":OP1:" +  operacaoWeis_1 + ":C1:" + contadorWeis[1] + ":OP2:" +  operacaoWeis_2 + ":PA:" + PrecoAbertura + ":SO:" + (PrecoSombra - PrecoAbertura) + ":CP:" + (PrecoTick - PrecoAbertura));
            
            
        }
        
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
// FUNCOES
//+------------------------------------------------------------------+

bool VerificarMudouCandle()
{
    if (BarData[99].close != PrecoFechamentoPenultimoCandle)
    {
        PrecoFechamentoPenultimoCandle = BarData[99].close;
        return true;
    }

    else return false;
}

bool horarioFecharPosicaoIndice(string horarioMaximo, float precoAtual, string ativo, int tamanhoLote)
{


    ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
    double StopLossCorrente = PositionGetDouble(POSITION_SL);
    double GainCorrente = PositionGetDouble(POSITION_TP);
    double PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);

    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    horaCorrente = StringToTime("2019.01.01 " + horaCorrenteStr);

    if (StringToTime("2019.01.01 " + horaCorrenteStr) > StringToTime("2019.01.01 " + horarioMaximo))
    {
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            trade.PositionModify(PositionTicket, precoAtual + 20, precoAtual - 20);
        //trade.Sell(tamanhoLote, ativo, precoAtual);

        else
            //trade.Buy(tamanhoLote, ativo, precoAtual);
            trade.PositionModify(PositionTicket, precoAtual - 20, precoAtual + 20);

        return true;

    }
    else return false;

}




bool funcao_verifica_meta_ou_perda_atingida(string tmpOrigem, double tmpValorMaximoPerda, double tmpValor_Maximo_Ganho, bool tmp_placar)
{
    //tmpOrigem = comentario de qual local EA foi chamado a função
    //tmpValorMaximoPerda = valor máximo desejado como perda máxima
    //tmpValor_Maximo_Ganho = valor estipulado de meta do  dia
    //tmp_placar = true exibe no comment o resultado das negociações do dia

    Print("Pesquisa funcao_verifica_meta_ou_perda_atingida (" + tmpOrigem + ")");
    string tmp_x;
    double tmp_resultado_financeiro_dia;
    int tmp_contador;
    MqlDateTime tmp_data_b;

    TimeCurrent(tmp_data_b);
    tmp_resultado_financeiro_dia = 0;
    tmp_x = string(tmp_data_b.year) + "." + string(tmp_data_b.mon) + "." + string(tmp_data_b.day) + " 00:00:01";

    HistorySelect(StringToTime(tmp_x), TimeCurrent());
    int tmp_total = HistoryDealsTotal();
    ulong tmp_ticket = 0;
    double tmp_price;
    double tmp_profit;
    datetime tmp_time;
    string tmp_symboll;
    long tmp_typee;
    long tmp_entry;

    //--- para todos os negócios 
    for (tmp_contador = 0; tmp_contador < tmp_total; tmp_contador++)
    {
        //--- tentar obter ticket negócios 
        if ((tmp_ticket = HistoryDealGetTicket(tmp_contador)) > 0)
        {
            //--- obter as propriedades negócios 
            tmp_price = HistoryDealGetDouble(tmp_ticket, DEAL_PRICE);
            tmp_time = (datetime)HistoryDealGetInteger(tmp_ticket, DEAL_TIME);
            tmp_symboll = HistoryDealGetString(tmp_ticket, DEAL_SYMBOL);
            tmp_typee = HistoryDealGetInteger(tmp_ticket, DEAL_TYPE);
            tmp_entry = HistoryDealGetInteger(tmp_ticket, DEAL_ENTRY);
            tmp_profit = HistoryDealGetDouble(tmp_ticket, DEAL_PROFIT);
            //--- apenas para o símbolo atual 
            if (tmp_symboll == Ativo) tmp_resultado_financeiro_dia = tmp_resultado_financeiro_dia + tmp_profit;

        }
    }

    if (tmp_resultado_financeiro_dia == 0)
    {
        if (tmp_placar = true) Comment("Placar  0x0");
        return (false); //sem ordens no dia
    }
    else
    {
        if ((tmp_resultado_financeiro_dia > 0) && (tmp_resultado_financeiro_dia != 0))
        {
            if (tmp_placar = true) Comment("Lucro R$" + DoubleToString(NormalizeDouble(tmp_resultado_financeiro_dia, 2), 2));
        }
        else
        {
            if (tmp_placar = true) Comment("Prejuizo R$" + DoubleToString(NormalizeDouble(tmp_resultado_financeiro_dia, 2), 2));
        }

        if (tmp_resultado_financeiro_dia < tmpValorMaximoPerda)
        {
            Print("Perda máxima alcançada.");
            return (true);
        }
        else
        {
            if (tmp_resultado_financeiro_dia > tmpValor_Maximo_Ganho)
            {
                Print("Meta Batida.");
                return (true);
            }
        }
    }
    return (false);
}

