//+------------------------------------------------------------------+
//|                                               ROBOLAB_SCAPER.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>

CTrade operacao;

input string cabecario1;      // ====== ALVO/LOSS - NORMAL ========
input int qtdContratos = 1;   // Quantidade de contratos
input double gain = 50;     // GAIN
input double loss = 300;      // LOSS - Distancia maximo Topo/Fundo
input double distancia = 70;      // Distancia VWAP
input double qtdCandles = 2;      // Quantidade Candles para Zerar

input string cabecario16;             // ====== HORARIOS =================
input string horarioAbrMin = "09:00"; // Abertura MIN
input string horarioAbrMax = "17:00"; // Abertura MAX
input string horarioFecMax = "17:30"; // Fechamento MAX

input string cabecario17;             // ====== METAS =====================
input double metaGainDi = 30;        // Ganho Max Diario ($)
input double metaLossDi = -60;       // Perda Max Diario ($)

input string cabecario21;          // ====== INDICADORES - RSI ========
input bool usarRsi = false;        // Usar Indicador

//+------------------------------------------------------------------+
//|                                 |
//+------------------------------------------------------------------+

int mVwap;
double VwapArray[];

bool mudouCandle = false;
bool mudouCandle5 = false;
bool ordemAberta = false;

int mRSI;
double RSIArray[];

int contador = 0;

double PrecoFechamentoPenultimoCandle = 1;

MqlRates BarData[1];

double PrecoFechamentoPenultimoCandle5 = 1;

MqlRates BarData5[1];


//+------------------------------------------------------------------+
//|                                 |
//+------------------------------------------------------------------+

int OnInit()
{
    //---

    //---

    mVwap = iCustom(_Symbol, _Period, "VWAP");
    mRSI = iRSI(Symbol(), Period(), 14, PRICE_CLOSE);

    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //---


    CopyRates(_Symbol, _Period, 1, 1, BarData);
    CopyRates(_Symbol, PERIOD_M5, 1, 1, BarData5);

    mudouCandle = VerificarMudouCandle();
    mudouCandle5 = VerificarMudouCandle5();




    if (mudouCandle)
    {

        ordemAberta = OrdemAberta(_Symbol);
        ArraySetAsSeries(VwapArray, true);
        CopyBuffer(mVwap, 0, 0, 3, VwapArray);
        ArraySetAsSeries(RSIArray, true);
        CopyBuffer(mRSI, 0, 0, 3, RSIArray);

        if (horaOperar(horarioAbrMax) && !ordemAberta  && !funcao_verifica_meta_ou_perda_atingida("Meta", metaLossDi, metaGainDi, true)    )
        {
            if ((VwapArray[1] - BarData[0].close < distancia && VwapArray[1] - BarData[0].close > 0) || (BarData[0].close - VwapArray[1] < distancia && BarData[0].close - VwapArray[1] > 0))
            {
                if ( BarData[0].close > BarData[0].open //&& mRSI > 60
                )
                {
                    //SymbolInfoDouble(_Symbol, SYMBOL_LAST)
                    operacao.Sell(qtdContratos, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_LAST), SymbolInfoDouble(_Symbol, SYMBOL_LAST) + loss, SymbolInfoDouble(_Symbol, SYMBOL_LAST) - gain);
                    contador = 0;

                }
                else if (BarData[0].close < BarData[0].open //&& mRSI < 40
                )
                {
                    operacao.Buy(qtdContratos, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_LAST), SymbolInfoDouble(_Symbol, SYMBOL_LAST) - loss, SymbolInfoDouble(_Symbol, SYMBOL_LAST) + gain);
                    contador = 0;

                }
            }
        }
        
    }
    
    
    
    
    if(ordemAberta && mudouCandle5) 
        {


            ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
            double StopLossCorrente = PositionGetDouble(POSITION_SL);
            double GainCorrente = PositionGetDouble(POSITION_TP);
            double PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);

            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {


                if (BarData[0].close < BarData[0].open) contador++;
                if (contador == qtdCandles) operacao.Sell(qtdContratos, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_LAST), SymbolInfoDouble(_Symbol, SYMBOL_LAST) + loss, SymbolInfoDouble(_Symbol, SYMBOL_LAST) - gain);


            }
            else
            {


                if (BarData[0].close > BarData[0].open) contador++;
                if (contador == qtdCandles) operacao.Buy(qtdContratos, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_LAST), SymbolInfoDouble(_Symbol, SYMBOL_LAST) - loss, SymbolInfoDouble(_Symbol, SYMBOL_LAST) + gain);


            }

            //horaOperar(horarioAbrMax)



        }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
//+------------------------------------------------------------------+


bool VerificarMudouCandle()
{
    if (BarData[0].close != PrecoFechamentoPenultimoCandle)
    {
        PrecoFechamentoPenultimoCandle = BarData[0].close;
        return true;
    }

    else
        return false;
}

bool VerificarMudouCandle5()
{
    if (BarData5[0].close != PrecoFechamentoPenultimoCandle5)
    {
        PrecoFechamentoPenultimoCandle5 = BarData5[0].close;
        return true;
    }

    else
        return false;
}


bool OrdemAberta(string ativo)
{
    if (PositionSelect(ativo) == true)
        return true;
    else
        return false;
}


bool horaOperar(string inicioPrimeiroPeriodo)
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    horaCorrente = StringToTime("2020.01.01 " + horaCorrenteStr);

    if (StringToTime("2020.01.01 " + horaCorrenteStr) <= StringToTime("2020.01.01 " + inicioPrimeiroPeriodo))
    {
        return true;
    }
    else
    {
        return false;
    }
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
            if (tmp_symboll == _Symbol) tmp_resultado_financeiro_dia = tmp_resultado_financeiro_dia + tmp_profit;

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