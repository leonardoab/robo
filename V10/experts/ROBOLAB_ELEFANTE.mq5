//+------------------------------------------------------------------+
//|                                             ROBOLAB_ELEFANTE.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include <Trade\Trade.mqh>

CTrade operacao;




MqlRates BarData[2];

bool ordemAberta = false;
bool mudouCandle = false;
string sinal = "";

double PrecoFechamentoPenultimoCandle = 1;

input string cabecario1;      // ====== ALVO/LOSS - NORMAL ========
input int qtdContratos = 1;   // Quantidade de contratos
input double gain = 100;     // GAIN
input double loss = 250;     // LOSS 
input double tamanhoCandle = 300; // Tamanho Candle Minimo
input double margemEntrada = 10; // Margem de entrada contraria
input double rsiMinimoCompra = 40; // RSI Minimo Compra
input double rsiVendaCompra = 60; // RSI Minimo Venda
input int periodoRSi = 14;

int mRSI;
double RSIArray[];



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
         mRSI = iRSI(Symbol(), Period(), periodoRSi, PRICE_CLOSE);
//---
   return(INIT_SUCCEEDED);
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
CopyRates(_Symbol, _Period, 1, 2, BarData);

 mudouCandle = VerificarMudouCandle();
 ordemAberta = OrdemAberta(_Symbol);
 
  if (ordemAberta){ 
    sinal = "";
    //fecharTodasOrdensPendentes();
    }

    if (mudouCandle)
    {
    
    ArraySetAsSeries(RSIArray, true);
            CopyBuffer(mRSI, 0, 0, 3, RSIArray);
    
    //if (sinal == "") fecharTodasOrdensPendentes();
    
   
    
                if ( 
                (!ordemAberta && BarData[1].close > BarData[1].open && BarData[1].close - BarData[1].open > tamanhoCandle)
                || (sinal == "Venda" &&  BarData[1].low > BarData[0].close - margemEntrada    ) && RSIArray[0] > rsiVendaCompra
                )
                {
                    datetime expiration = TimeTradeServer() + PeriodSeconds(PERIOD_M5);
                     fecharTodasOrdensPendentes();
                    //operacao.Sell(qtdContratos, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_LAST), BarData[1].close + loss, BarData[1].close - gain);
                     operacao.SellStop(qtdContratos, BarData[1].close - margemEntrada, _Symbol, BarData[1].close - margemEntrada + loss, BarData[1].close - margemEntrada - gain, ORDER_TIME_SPECIFIED, expiration,RSIArray[0]);
                     Print("BuyStop() method failed. Return code=",operacao.ResultRetcode(),
            ". Code description: ",operacao.ResultRetcodeDescription());
                
                
                    sinal = "Venda";

                }
                else if ( 
                (!ordemAberta && BarData[1].close < BarData[1].open && BarData[1].open - BarData[1].close > tamanhoCandle)
                || (sinal == "Compra" &&  BarData[1].high < BarData[0].close + margemEntrada ) && RSIArray[0] < rsiMinimoCompra
                )
                {
                    datetime expiration = TimeTradeServer() + PeriodSeconds(PERIOD_M5);
                     fecharTodasOrdensPendentes();
                    //operacao.Buy(qtdContratos, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_LAST), BarData[1].close - loss, BarData[1].close + gain);
                    
                     operacao.BuyStop(qtdContratos, BarData[1].close + margemEntrada, _Symbol, BarData[1].close + margemEntrada - loss, BarData[1].close + margemEntrada + gain, ORDER_TIME_SPECIFIED, expiration,RSIArray[0]);
                 Print("BuyStop() method failed. Return code=",operacao.ResultRetcode(),
            ". Code description: ",operacao.ResultRetcodeDescription());
                
                
                    
                    sinal = "Compra";

                }
    
    
    
    
    
    
    
    }




   
  }
//+------------------------------------------------------------------+

bool VerificarMudouCandle()
{
    if (BarData[1].close != PrecoFechamentoPenultimoCandle)
    {
        PrecoFechamentoPenultimoCandle = BarData[1].close;
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

    MqlTradeRequest request = {0};
    MqlTradeResult result = {0};

    ulong order_ticket = OrderGetTicket(0);

    ZeroMemory(request);
    ZeroMemory(result);
    //--- setting the operation parameters
    request.action = TRADE_ACTION_REMOVE;
    request.order = order_ticket;

    
    if (order_ticket != 0 )OrderSend(request, result);       // PrintFormat("OrderSend error %d", GetLastError());
    //PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
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
