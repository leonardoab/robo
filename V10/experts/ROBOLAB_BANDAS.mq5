//+------------------------------------------------------------------+
//|                                               ROBOLAB_BANDAS.mq5 |
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


enum intervals  // Enumeração de constantes nomeadas
   {
    H15_30 = 1,     // 15:30
    H16_00 = 2,  // 16:00
    H16_30 = 3,     // 16:30
    H17_00 = 4,  // 17:00
    H17_30 = 5,     // 17:30
   };


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input string cabecario1;      // ====== ALVO/LOSS - NORMAL ========
input int qtdContratos = 1;   // Quantidade de contratos
input double gain = 3;        // GAIN Minimo
input double loss = 15;        // LOSS Maximo
input double margem = 0.5;      // Margem Entrada
input int mediaRSI = 7;         // Media RSI
input int mediaBands = 50;         // Media Bandas
input int candlesCancel = 7;    // Candles para Cancelar Entrada
input int faixaCompra = 25;     // Faixa Compra
input int faixaVenda = 80;     // Faixa Compra
input int quantidadeCandlesPsair = 85; // Qtd Candles para Mudar o Gain
input int qtdPontos = 6; // Ajuste do Novo Gain
input intervals horarioEnum = H15_30;
input intervals horarioMaxEnum = H17_30;







string horario = "16:30";
string horarioMax = "17:30";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
CTrade operacao;
MqlRates BarData[2];

bool ordemAberta = false;
bool mudouCandle = false;

double SubBandaArray[];
double InfBandaArray[];
double RsiArray[];

int mRSI;
int mBand;
int contador = 0;
int ultimoCandle = 1;
int dobrar = 0;



double PrecoFechamentoPenultimoCandle = 1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
mRSI = iRSI(_Symbol, _Period, mediaRSI, PRICE_CLOSE);
mBand = iBands(_Symbol, _Period, mediaBands,0,2, PRICE_CLOSE);

if (horarioEnum == H15_30) horario = "15:30";
if (horarioEnum == H16_00) horario = "16:00";
if (horarioEnum == H16_30) horario = "16:30";
if (horarioEnum == H17_00) horario = "17:00";
if (horarioEnum == H17_30) horario = "17:30";

if (horarioMaxEnum == H15_30) horarioMax = "15:30";
if (horarioMaxEnum == H16_00) horarioMax = "16:00";
if (horarioMaxEnum == H16_30) horarioMax = "16:30";
if (horarioMaxEnum == H17_00) horarioMax = "17:00";
if (horarioMaxEnum == H17_30) horarioMax = "17:30";





 /*   H15_30 = 1,     // Intervalo de um mês
    H16_00 = 2,  // Dois meses
    H16_30 = 3,     // Três meses - trimestre
    H17_00 = 4,  // Semestre
    H17_30 = 5,     // Ano - 12 meses*/
   
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
    
    

    if (mudouCandle)
    {
        ordemAberta = OrdemAberta(_Symbol);
        
         if (ordemAberta) 
        {
        horarioFecharPosicaoDolar(horarioMax, SymbolInfoDouble(_Symbol, SYMBOL_LAST), _Symbol, qtdContratos);
        
        }        
        
        contador ++;
        
        if (contador == candlesCancel) fecharTodasOrdensPendentes();
        
        if (ordemAberta && contador == quantidadeCandlesPsair) alterarSaida();
        
        ArraySetAsSeries(SubBandaArray, true);        
        ArraySetAsSeries(InfBandaArray, true);
        CopyBuffer(mBand, 1, 0, 3, SubBandaArray);
        CopyBuffer(mBand, 2, 0, 3, InfBandaArray);
        
        ArraySetAsSeries(RsiArray, true);
        CopyBuffer(mRSI, 0, 0, 3, RsiArray);
        
        if (
        
         horaOperar(horario)
         && !ordemAberta 
        //&& BarData[1].close > SubBandaArray[2] 
        //&& BarData[1].open < SubBandaArray[2]
        && RsiArray[1] > faixaVenda 
        //&& BarData[0].close < SubBandaArray[1]
        && BarData[ultimoCandle].high > SubBandaArray[1]
        && BarData[ultimoCandle].close < SubBandaArray[1]
         
        
        ){
           //funcao_verifica_meta_ou_perda_atingida("Meta", -300, 300, true) ;
           fecharTodasOrdensPendentes();
           //operacao.Sell(qtdContratos,_Symbol,BarData[ultimoCandle].close,BarData[ultimoCandle].close + loss,BarData[ultimoCandle].close - gain);
           //operacao.SellLimit(qtdContratos,_Symbol, (BarData[0].close - 1 ), (BarData[0].close + loss + 1 ), (BarData[0].close - gain -1)); 
           //operacao.SellStop(qtdContratos, (BarData[ultimoCandle].low - margem ),_Symbol, (BarData[ultimoCandle].low + loss - margem ),(BarData[ultimoCandle].low - gain - margem),ORDER_TIME_SPECIFIED, (TimeTradeServer() + PeriodSeconds(PERIOD_M5)));
           operacao.OrderOpen(_Symbol,ORDER_TYPE_SELL_STOP_LIMIT,qtdContratos + dobrar,(BarData[ultimoCandle].low - margem ),(BarData[ultimoCandle].low - margem ),(BarData[ultimoCandle].low + loss - margem ),(BarData[ultimoCandle].low - gain - margem),ORDER_TIME_SPECIFIED,(TimeTradeServer() + PeriodSeconds(PERIOD_M5)));
           contador = 0;
           
           
           
        
        }
        else if (
        
         horaOperar(horario)
         && !ordemAberta 
       // && BarData[1].close < InfBandaArray[2] 
        //&& BarData[1].open > InfBandaArray[2] 
        && RsiArray[1] < faixaCompra
        && BarData[ultimoCandle].low < InfBandaArray[1]
        && BarData[ultimoCandle].close > InfBandaArray[1]
         
        //&& BarData[0].close > InfBandaArray[1]
        ){
          //funcao_verifica_meta_ou_perda_atingida("Meta", -300, 300, true) ;
          fecharTodasOrdensPendentes();
           //operacao.Buy(qtdContratos,_Symbol,BarData[ultimoCandle].close,BarData[ultimoCandle].close - loss,BarData[ultimoCandle].close + gain);
           //operacao.BuyLimit(qtdContratos,_Symbol, (BarData[0].close + 1 ), (BarData[0].close - loss - 1 ), (BarData[0].close + gain + 1)); 
           //operacao.BuyStop(qtdContratos, (BarData[ultimoCandle].high + margem ),_Symbol, (BarData[ultimoCandle].high - loss + margem ),(BarData[ultimoCandle].high + gain + margem),ORDER_TIME_SPECIFIED, (TimeTradeServer() + PeriodSeconds(PERIOD_M5)));
           operacao.OrderOpen(_Symbol,ORDER_TYPE_BUY_STOP_LIMIT,qtdContratos + dobrar,(BarData[ultimoCandle].high + margem ),(BarData[ultimoCandle].high + margem ),(BarData[ultimoCandle].high - loss + margem ),(BarData[ultimoCandle].high + gain + margem),ORDER_TIME_SPECIFIED,(TimeTradeServer() + PeriodSeconds(PERIOD_M5)));
           contador = 0;
        }  
        
        
        
        
        
        
    }



    
   
  }
//+------------------------------------------------------------------+


bool VerificarMudouCandle()
{
    if (BarData[ultimoCandle].close != PrecoFechamentoPenultimoCandle)
    {
        PrecoFechamentoPenultimoCandle = BarData[ultimoCandle].close;
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

   if (order_ticket != 0) 
   
   {
   OrderSend(request, result);
   if (dobrar > 0) dobrar = dobrar - 4;
   }
       
}

bool horaOperar(string inicioPrimeiroPeriodo)
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


bool horarioFecharPosicaoDolar(string horarioMaximo, float precoAtual, string ativo, int tamanhoLote)
{

    fecharTodasOrdensPendentes();
   
    ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
    double StopLossCorrente = PositionGetDouble(POSITION_SL);
    double GainCorrente = PositionGetDouble(POSITION_TP);
    double PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);

    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    horaCorrente = StringToTime("2020.01.01 " + horaCorrenteStr);

    if (StringToTime("2020.01.01 " + horaCorrenteStr) > StringToTime("2020.01.01 " + horarioMaximo))
    {
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
          //  operacao.PositionModify(PositionTicket, precoAtual + 20, precoAtual - 20);
        operacao.Sell(tamanhoLote, ativo, precoAtual);

        else
            operacao.Buy(tamanhoLote, ativo, precoAtual);
          //  operacao.PositionModify(PositionTicket, precoAtual - 20, precoAtual + 20);

        return true;

    }
    else return false;

}


void alterarSaida (){



    ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
    double StopLossCorrente = PositionGetDouble(POSITION_SL);
    double GainCorrente = PositionGetDouble(POSITION_TP);
    double PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);

    
   
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            operacao.PositionModify(PositionTicket,StopLossCorrente + qtdPontos, PrecoAberturaPosicao);
        //operacao.Sell(tamanhoLote, ativo, precoAtual);

        else
        //    operacao.Buy(tamanhoLote, ativo, precoAtual);
            operacao.PositionModify(PositionTicket, StopLossCorrente - qtdPontos , PrecoAberturaPosicao);
            

    

  
    




}

void funcao_verifica_meta_ou_perda_atingida(string tmpOrigem, double tmpValorMaximoPerda, double tmpValor_Maximo_Ganho, bool tmp_placar)
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
    tmp_x = string(2018) + "." + string(tmp_data_b.mon) + "." + string(tmp_data_b.day) + " 00:00:01";

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
    //for (tmp_contador = 0; tmp_contador < tmp_total; tmp_contador++)
    //{
        //--- tentar obter ticket negócios 
        if ((tmp_ticket = HistoryDealGetTicket(tmp_total - 1)) > 0)
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
        
        
        //if (tmp_profit < -90) 
        //dobrar = dobrar + 4;
        //else dobrar = 0;
    //}

    if (tmp_resultado_financeiro_dia == 0)
    {
       
        if (tmp_placar = true) Comment("Placar  0x0");
        
    }
    else
    {
        if ((tmp_resultado_financeiro_dia > 0) && (tmp_resultado_financeiro_dia != 0))
        {
            if (tmp_placar = true) 
            {
            Comment("Lucro R$" + DoubleToString(NormalizeDouble(tmp_resultado_financeiro_dia, 2), 2));
            
            }
        }
        else
        {
            if (tmp_placar = true) 
            {
            Comment("Prejuizo R$" + DoubleToString(NormalizeDouble(tmp_resultado_financeiro_dia, 2), 2));
            
            }
        }

        if (tmp_resultado_financeiro_dia < tmpValorMaximoPerda)
        {
            Print("Perda máxima alcançada.");
            
        }
        else
        {
            if (tmp_resultado_financeiro_dia > tmpValor_Maximo_Ganho)
            {
                Print("Meta Batida.");
               
            }
        }
    }
   
}