

//+------------------------------------------------------------------+
//|                                               ROBOLAB_CANDLE.mq5 |
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

input string cabecario1;              // ====== ALVO/LOSS - NORMAL ========
input int qtdContratos = 1;           // Quantidade de contratos FUTx1 VISTAx100
input double gain = 50;               // GAIN 
input double loss = 200;              // LOSS 
input double fator = 10;              // ACAO = 100 - DOLAR = 10 - Indice = 1 
input double mult = 5;                // ACAO = 1 - DOLAR = 5 - Indice = 5 
input string cabecario17;             // ====== METAS =====================
input double metaGainDi = 3000;       // Ganho Max Diario ($)
input double metaLossDi = -3000;      // Perda Max Diario ($)
input string cabecario16;             // ====== HORARIOS =================
input string horarioAbrMin = "09:00"; // Abertura MIN
input string horarioAbrMax = "17:00"; // Abertura MAX
input string horarioFecMax = "17:30"; // Fechamento MAX

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
MqlRates BarData[1];

int ultimoCandle = 0, mHILO, div;

double high = 0,low = 200000,highbase, lowbase,precoAtual, media1Normalizada, media2Normalizada, hilo1Buffer[], hilo2Buffer[], hilo3Buffer[], hilo4Buffer[];

datetime horaPenultimoFechamento;

bool ordemAberta = false, mudouCandle = false, ordemExecutada = false,virouHilo = false;

string sentido = "";



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //---



    
    mHILO = iCustom(_Symbol, _Period, "HILOE", 42, MODE_SMA, -1);
    
    //---
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
    mudouCandle = VerificarMudouCandle();

    if (mudouCandle)
    {

        fecharTodasOrdensPendentes();
        ordemAberta = OrdemAberta(_Symbol);

        precoAtual = SymbolInfoDouble(_Symbol, SYMBOL_LAST);


        ArraySetAsSeries(hilo1Buffer, true);
        ArraySetAsSeries(hilo2Buffer, true);

        CopyBuffer(mHILO, 0, 0, 3, hilo1Buffer);
        CopyBuffer(mHILO, 1, 0, 3, hilo2Buffer);
        CopyBuffer(mHILO, 2, 0, 3, hilo3Buffer);
        CopyBuffer(mHILO, 3, 0, 3, hilo4Buffer);

        gravarValores();

        if (ordemAberta)
        {
            horarioFecharPosicao(horarioFecMax, SymbolInfoDouble(_Symbol, SYMBOL_LAST), _Symbol, qtdContratos);
            ordemExecutada = true;
        }


        if (!ordemAberta && horarioAberMax(horarioAbrMax) && !ordemExecutada && horarioAberMin(horarioAbrMin) && !metaDiaria("Meta", metaLossDi, metaGainDi, false))
        {


            // 100%
            if (sentido == "Compra" && (highbase - lowbase) + lowbase < BarData[0].close && (highbase - lowbase) * 1.308 + lowbase > BarData[0].close)

            {

                div = ((highbase - lowbase) + lowbase) * fator / mult;

                media1Normalizada = div * mult /  fator;

                operacao.OrderOpen(
                     _Symbol,
                     ORDER_TYPE_BUY_LIMIT,
                     qtdContratos,
                     media1Normalizada,
                     media1Normalizada,
                     media1Normalizada - loss,
                     media1Normalizada + gain,
                     ORDER_TIME_SPECIFIED,
                     TimeTradeServer() + PeriodSeconds(PERIOD_M5), highbase + ":" + lowbase
                     );

            }

            // 130,8%
            else if (sentido == "Compra" && (highbase - lowbase) * 1.308 + lowbase < BarData[0].close && (highbase - lowbase) * 1.618 + lowbase > BarData[0].close)

            {

                div = ((highbase - lowbase) * 1.308 + lowbase) * fator / mult;

                media1Normalizada = div * mult /  fator;

                operacao.OrderOpen(
                     _Symbol,
                     ORDER_TYPE_BUY_LIMIT,
                     qtdContratos,
                     media1Normalizada,
                     media1Normalizada,
                     media1Normalizada - loss,
                     media1Normalizada + gain,
                     ORDER_TIME_SPECIFIED,
                     TimeTradeServer() + PeriodSeconds(PERIOD_M5), highbase + ":" + lowbase
                     );

            }

            //161,8
            else if (sentido == "Compra" && (highbase - lowbase) * 1.618 + lowbase < BarData[0].close && (highbase - lowbase) * 2.618 + lowbase > BarData[0].close)

            {

                div = ((highbase - lowbase) * 1.618 + lowbase) * fator / mult;

                media1Normalizada = div * mult / fator;

                operacao.OrderOpen(
                     _Symbol,
                     ORDER_TYPE_BUY_LIMIT,
                     qtdContratos,
                     media1Normalizada,
                     media1Normalizada,
                     media1Normalizada - loss,
                     media1Normalizada + gain,
                     ORDER_TIME_SPECIFIED,
                     TimeTradeServer() + PeriodSeconds(PERIOD_M5), highbase + ":" + lowbase
                     );

            }

            else if (sentido == "Venda" && highbase - (highbase - lowbase) > BarData[0].close && highbase - (highbase - lowbase) * 1.308 < BarData[0].close)

            {

                div = (highbase - (highbase - lowbase)) * fator / mult;

                media1Normalizada = div * mult / fator;

                operacao.OrderOpen(
                    _Symbol,
                    ORDER_TYPE_SELL_LIMIT,
                    qtdContratos,
                    media1Normalizada,
                    media1Normalizada,
                    media1Normalizada + loss,
                    media1Normalizada - gain,
                    ORDER_TIME_SPECIFIED,
                    TimeTradeServer() + PeriodSeconds(PERIOD_M5), highbase + ":" + lowbase
                    );

            }



            else if (sentido == "Venda" && highbase - (highbase - lowbase) * 1.308 > BarData[0].close && highbase - (highbase - lowbase) * 1.618 < BarData[0].close)

            {

                div = (highbase - (highbase - lowbase) * 1.308) * fator / mult;

                media1Normalizada = div * mult  / fator;

                operacao.OrderOpen(
                    _Symbol,
                    ORDER_TYPE_SELL_LIMIT,
                    qtdContratos,
                    media1Normalizada,
                    media1Normalizada,
                    media1Normalizada + loss,
                    media1Normalizada - gain,
                    ORDER_TIME_SPECIFIED,
                    TimeTradeServer() + PeriodSeconds(PERIOD_M5), highbase + ":" + lowbase
                    );

            }

            else if (sentido == "Venda" && highbase - (highbase - lowbase) * 1.618 > BarData[0].close && highbase - (highbase - lowbase) * 2.618 < BarData[0].close)

            {

                div = (highbase - (highbase - lowbase) * 1.618) * fator / mult;

                media1Normalizada = div * mult / fator;

                operacao.OrderOpen(
                    _Symbol,
                    ORDER_TYPE_SELL_LIMIT,
                    qtdContratos,
                    media1Normalizada,
                    media1Normalizada,
                    media1Normalizada + loss,
                    media1Normalizada - gain,
                    ORDER_TIME_SPECIFIED,
                    TimeTradeServer() + PeriodSeconds(PERIOD_M5), highbase + ":" + lowbase
                    );

            }

        }
    }

}
//+------------------------------------------------------------------+



bool VerificarMudouCandle()
{
    if (BarData[ultimoCandle].time != horaPenultimoFechamento)
    {
        horaPenultimoFechamento = BarData[ultimoCandle].time;
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

void fecharTodasOrdensPendentes()
{
    uint total = OrdersTotal();

    for (uint i = 0; i < total; i++)

    {

        MqlTradeRequest request = { 0 };
        MqlTradeResult result = { 0 };

        ulong order_ticket = OrderGetTicket(0);

        ZeroMemory(request);
        ZeroMemory(result);
        //--- setting the operation parameters
        request.action = TRADE_ACTION_REMOVE;
        request.order = order_ticket;

        if (order_ticket != 0)

        {
            printf(OrderSend(request, result));

        }

    }

}

bool horarioFecharPosicao(string horarioMaximo, float precoAtualF, string ativo, int tamanhoLote)
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
            //  operacao.PositionModify(PositionTicket, precoAtual + 20, precoAtual - 20);
            operacao.Sell(tamanhoLote, ativo, precoAtualF);

        else
            operacao.Buy(tamanhoLote, ativo, precoAtualF);
        //  operacao.PositionModify(PositionTicket, precoAtual - 20, precoAtual + 20);

        return true;

    }
    else return false;

}

bool horarioAberMax(string inicioPrimeiroPeriodo)
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    horaCorrente = StringToTime("2019.01.01 " + horaCorrenteStr);

    if (StringToTime("2019.01.01 " + horaCorrenteStr) <= StringToTime("2019.01.01 " + inicioPrimeiroPeriodo))
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool horarioAberMin(string inicioPrimeiroPeriodo)
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    horaCorrente = StringToTime("2019.01.01 " + horaCorrenteStr);

    if (StringToTime("2019.01.01 " + horaCorrenteStr) >= StringToTime("2019.01.01 " + inicioPrimeiroPeriodo))
    {
        return true;
    }
    else
    {
        return false;
    }
}

bool metaDiaria(string tmpOrigem, double tmpValorMaximoPerda, double tmpValor_Maximo_Ganho, bool tmp_placar)
{


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

void gravarValores()
{


    int Number = Bars(Symbol(), Period());
    string NumberString = IntegerToString(Number);

    if (hilo3Buffer[0] != hilo3Buffer[1])
    {
        if (high == 0)
        {
            lowbase = low;
            highbase = BarData[0].high;
            sentido = "Compra";
        }

        else
        {
            lowbase = BarData[0].low;
            highbase = high;
            sentido = "Venda";
        }

        high = 0;
        low = 200000;

        ordemExecutada = false;

    }


    if (hilo3Buffer[1] == 0)
    {
        if (BarData[0].high > high)
        {
            high = BarData[0].high;
            ObjectCreate(_Symbol, NumberString, OBJ_ARROW_SELL, 0, TimeCurrent() - PeriodSeconds(PERIOD_M1), high);
        }


        virouHilo = false;
    }

    if (hilo3Buffer[1] == 1)
    {
        if (BarData[0].low < low)
        {
            low = BarData[0].low;
            ObjectCreate(_Symbol, NumberString, OBJ_ARROW_BUY, 0, TimeCurrent() - PeriodSeconds(PERIOD_M1), low);
        }


        virouHilo = false;

    }


}