#property copyright "Copyright 2019, Leonardo Araujo Bezerra."
#property link      "leonardoab89@gmail.com"
#property version   "4.0"
#property description "ROBOLAB_INDICE"

/* ======================================== INCLUDES =============================================================*/

#include <RenkoCharts.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade operacao;

/* ======================================== INPUT VARIAVEIS =============================================================*/

input ENUM_RENKO_WINDOW RenkoWindow = RENKO_NEW_WINDOW;    // Abrir estrategia
input bool CarregarHistorico = true;                       // BackTeste = False, Real/Criar Grafico = True
input string Ativo = "WING20";                             // Ativo 
input float loss = 100;                                    // Valor em pontos Loss
input float gain = 100;                                    // Valor em pontos Gain
input int QtdContratos = 1;                                // Quantidade de Contratos
input string horario = "17:00";                            // Horario Maximo Abrir
input string horarioFecha = "17:45";                       // Horario Fechamento
input int metaGain = 30;                                   // Financeiro Maximo Gain
input int metaLoss = -75;                                  // Financeiro Maximo Loss
input bool tipomedia = true;                               // Media True = RENKO / False = Normal(1M)
input int mediaRapida = 3;                                 // Média Rapida
input int mediaLonga = 9;                                  // Média Lenta
input float Ticks_Weis_1 = 75;                             // Quantidade de Pontos WEIS
input double RenkoSize = 10;                               // Tamanho Renko
input int valorSombraMaximo = 1000;                        // Tamanho Max Sombra
input int valorPreformadoMinimo = 0;                       // Tamanho Candle Pre Formado


/* ======================================== VARIAVEIS =============================================================*/

ENUM_RENKO_TYPE RenkoType = RENKO_TYPE_TICKS;

MqlRates BarData[100];

string RenkoSymbol = "";
string original_symbol, custom_symbol;
string operacaoWeis_1 = "Nada";
string operacaoWeis_2 = "Nada";
string sinalWeis[2];

int contadorWeis[2];
int RenkoTimer = 100;

double PrecoFechamentoPenultimoCandle = 1;
double PrecoTick = 0;
double PrecoAbertura = 0;
double PrecoSombra = 0;
double MediaCurtaArray[];   
double MediaLongaArray[];   

bool ordemAberta = false;
bool mudouCandle = false;
bool operando = false;

int mRapida = 0;                              
int mLonga = 0;                                  


/* ============================================================================================================*/

// Renko Charts
RenkoCharts RenkoOffline();

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
    
    if (tipomedia){    
    mRapida = iMA(_Symbol, _Period, mediaRapida, 0, MODE_EMA, PRICE_CLOSE);
    mLonga = iMA(_Symbol, _Period, mediaLonga, 0, MODE_EMA, PRICE_CLOSE);          
    }
    else {
    mRapida = iMA(Ativo, _Period, mediaRapida, 0, MODE_EMA, PRICE_CLOSE);
    mLonga = iMA(Ativo, _Period, mediaLonga, 0, MODE_EMA, PRICE_CLOSE);
    }

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
    

    ArraySetAsSeries(MediaCurtaArray, true);    
    ArraySetAsSeries(MediaLongaArray, true);
    
    CopyBuffer(mRapida, 0, 0, 3, MediaCurtaArray);    
    CopyBuffer(mLonga, 0, 0, 3, MediaLongaArray);      

    CopyRates(_Symbol, PERIOD_M1, 1, 100, BarData);

    mudouCandle = VerificarMudouCandle();

    ordemAberta = OrdemAberta(Ativo);

    if (CarregarHistorico) if (ordemAberta) operacaoCorrente(loss, gain, Ativo);    

    if (mudouCandle)
    {       

        operando = false;
        
        if (ordemAberta) horarioFecharPosicaoIndice(horarioFecha, SymbolInfoDouble(_Symbol, SYMBOL_LAST), _Symbol, QtdContratos);

        operacaoWeis_1 = weis(Ticks_Weis_1, true, 0, sinalWeis, contadorWeis, 100, BarData);
        operacaoWeis_2 = weis((Ticks_Weis_1 * 2), false, 1, sinalWeis, contadorWeis, 100, BarData);

        if (    operacaoWeis_1 == "Venda" 
             && operacaoWeis_2 == "Venda"             
             && !ordemAberta 
             && (MediaCurtaArray[0] < MediaLongaArray[1]) 
             && horaOperar(horario)             
             && !operando
             && !funcao_verifica_meta_ou_perda_atingida("Meta", metaLoss, metaGain, true)
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
                  && (MediaCurtaArray[0] > MediaLongaArray[1]) 
                  && horaOperar(horario)                  
                  && !operando
                  && !funcao_verifica_meta_ou_perda_atingida("Meta", metaLoss, metaGain, true)
                 )
        {            
            PrecoTick = SymbolInfoDouble(Ativo, SYMBOL_LAST);
            PrecoAbertura = iOpen(Ativo,PERIOD_M5,0);
            PrecoSombra = iHigh(Ativo,PERIOD_M5,0);
            operando = true;
            
            if (PrecoTick > PrecoAbertura && PrecoSombra - PrecoAbertura < valorSombraMaximo && PrecoTick - PrecoAbertura  > valorPreformadoMinimo )  operacao.Buy(QtdContratos, Ativo, PrecoTick, PrecoTick - loss, PrecoTick + gain,
            ":P:" + PrecoTick + ":C0:" + contadorWeis[0] + ":OP1:" +  operacaoWeis_1 + ":C1:" + contadorWeis[1] + ":OP2:" +  operacaoWeis_2 + ":PA:" + PrecoAbertura + ":SO:" + (PrecoSombra - PrecoAbertura) + ":CP:" + (PrecoTick - PrecoAbertura));
            
            
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
            operacao.PositionModify(PositionTicket, precoAtual + 20, precoAtual - 20);
        //trade.Sell(tamanhoLote, ativo, precoAtual);

        else
            //trade.Buy(tamanhoLote, ativo, precoAtual);
            operacao.PositionModify(PositionTicket, precoAtual - 20, precoAtual + 20);

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



bool OrdemAberta(string ativo)
{
    if (PositionSelect(ativo) == true) return true;
    else return false;
}

void operacaoCorrente(float loss, float gain,string Ativo){

        
           PositionSelect(Ativo);
           ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
           double StopLossCorrente = PositionGetDouble(POSITION_SL);
           double GainCorrente = PositionGetDouble(POSITION_TP);
           double PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);           
               
   
           if (StopLossCorrente < PrecoAberturaPosicao  && (GainCorrente - PrecoAberturaPosicao < gain || PrecoAberturaPosicao - StopLossCorrente < loss)){
           
           operacao.PositionModify(PositionTicket, (PrecoAberturaPosicao - loss), (PrecoAberturaPosicao + gain));
           
           }
           
           else if (StopLossCorrente > PrecoAberturaPosicao &&  (PrecoAberturaPosicao - GainCorrente < gain || StopLossCorrente - PrecoAberturaPosicao < loss)){
           
           operacao.PositionModify(PositionTicket, (PrecoAberturaPosicao + loss), (PrecoAberturaPosicao - gain)); 
           
           }    

}

string weis(int ticks, bool sinalTrigger, int weis,string &sinalWeis[],int &contadorWeis[],int qtdPeriodos,MqlRates &BarData[])
{ 
    
    double valorUltimoTopo = 0;
    double valorUltimoFundo = 1000000;   
    int i = qtdPeriodos - 1;

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
            if (i - x > 0){
               if (BarData[i - x].close < valorUltimoFundo) valorUltimoFundo = BarData[i - x].close; 
            }      
        
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
            if (i - x > 0){
               if (BarData[i - x].close > valorUltimoTopo) valorUltimoTopo = BarData[i - x].close;
            }
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


bool horaOperar(string inicioPrimeiroPeriodo)
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);    
    
    horaCorrente = StringToTime(   "2019.01.01 " + horaCorrenteStr);    

    if ( StringToTime(   "2019.01.01 " + horaCorrenteStr)  <= StringToTime(   "2019.01.01 " + inicioPrimeiroPeriodo) )
      {             
        return true;        
      }
    else
      {
        return false;
      }

}