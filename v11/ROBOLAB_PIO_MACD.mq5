

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
input int qtdContratos = 1;           // Quantidade de contratos 
input double gain = 50;               // GAIN 
input double loss = 200;              // LOSS 
input double fator = 1;              // ACAO = 100 - DOLAR = 10 - Indice = 1 
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

int ultimoCandle = 0;

int mMedia1, mMedia2, mMacd;

double media1Buffer[];
double media2Buffer[];
double macDbuffer[];

int div;

double precoAtual;

double PrecoFechamentoPenultimoCandle = 1, media1Normalizada, media2Normalizada;

MqlRates BarData[1];

bool ordemAberta = false;
bool mudouCandle = false;

datetime horaPenultimoFechamento;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

    mMedia1 = iMA(_Symbol, _Period, 9, 0, MODE_EMA, PRICE_CLOSE);
    mMedia2 = iMA(_Symbol, _Period, 72, 0, MODE_EMA, PRICE_CLOSE);
    mMacd = iMACD(_Symbol, PERIOD_M15, 12, 26, 9, PRICE_CLOSE);
    
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    CopyRates(_Symbol, _Period, 1, 1, BarData);
    mudouCandle = VerificarMudouCandle();

    if (mudouCandle)
    {
        fecharTodasOrdensPendentes();

        ordemAberta = OrdemAberta(_Symbol);

        ArraySetAsSeries(media1Buffer, true);
        ArraySetAsSeries(media2Buffer, true);
        ArraySetAsSeries(macDbuffer, true);

        CopyBuffer(mMedia1, 0, 0, 3, media1Buffer);
        CopyBuffer(mMedia2, 0, 0, 3, media2Buffer);
        CopyBuffer(mMacd, 0, 0, 7, macDbuffer);

        div = media1Buffer[0] * fator / mult;

        media1Normalizada = div * mult / fator;

        div = media2Buffer[0] * fator / mult;

        media2Normalizada = div * mult / fator;

        precoAtual = SymbolInfoDouble(_Symbol, SYMBOL_LAST);

        if (horaOperarMax(horarioAbrMax) && horaOperarMin(horarioAbrMin) && !ordemAberta && !funcao_verifica_meta_ou_perda_atingida("Meta", metaLossDi, metaGainDi, true))
        {
            if (media1Buffer[0] > media2Buffer[0]
             && macDbuffer[5] < macDbuffer[6]
             && macDbuffer[4] < macDbuffer[5]
             && macDbuffer[3] < macDbuffer[4]
             && macDbuffer[2] < macDbuffer[3]
             && macDbuffer[2] < macDbuffer[1]
            )
            {
                operacao.OrderOpen(
                 _Symbol,
                 ORDER_TYPE_BUY_LIMIT,
                 qtdContratos,
                 media1Normalizada,
                 media1Normalizada,
                 media1Normalizada - loss,
                 media1Normalizada + gain,
                 ORDER_TIME_SPECIFIED,
                 TimeTradeServer() + PeriodSeconds(PERIOD_M5)
                 );
            }
            else if (media1Buffer[0] < media2Buffer[0]
            && macDbuffer[5] > macDbuffer[6]
            && macDbuffer[4] > macDbuffer[5]
            && macDbuffer[3] > macDbuffer[4]
            && macDbuffer[2] > macDbuffer[3]
            && macDbuffer[2] > macDbuffer[1]
            )
            {
                operacao.OrderOpen(
                _Symbol,
                ORDER_TYPE_SELL_LIMIT,
                qtdContratos,
                media1Normalizada,
                media1Normalizada,
                media1Normalizada + loss,
                media1Normalizada - gain,
                ORDER_TIME_SPECIFIED,
                TimeTradeServer() + PeriodSeconds(PERIOD_M5)
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

bool horarioFecharPosicaoIndice(string horarioMaximo, float precoAtualF, string ativo, int tamanhoLote)
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

bool funcao_verifica_meta_ou_perda_atingida(string tmpOrigem, double tmpValorMaximoPerda, double tmpValor_Maximo_Ganho, bool tmp_placar)
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


bool horaOperarMax(string inicioPrimeiroPeriodo)
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

bool horaOperarMin(string inicioPrimeiroPeriodo)
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    horaCorrente = StringToTime("2020.01.01 " + horaCorrenteStr);

    if (StringToTime("2020.01.01 " + horaCorrenteStr) >= StringToTime("2020.01.01 " + inicioPrimeiroPeriodo))
    {
        return true;
    }
    else
    {
        return false;
    }
}