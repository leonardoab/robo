//+------------------------------------------------------------------+
//|                                                ROBOLAB_RVWAP.mq5 |
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
#include <Trade\PositionInfo.mqh>

CTrade trade;

int handle;
int ultimo = 1;
int vwap;
int obv;

double vwapArray[];
double stochast[];
double signal[];
double obvArray[];

double PrecoFechamentoPenultimoCandle = 1;

MqlRates BarData[2];

bool mudouCandle = false;

input int gain = 200;
input int loss = 200;
input int tamanhoMinimo = 100;
input int margemEntrada = 50;
input ENUM_TIMEFRAMES tempoExecucao = PERIOD_M5;


bool ordemAberta = false;



datetime expiration;
int precoReferencia = 0;


int OnInit()
{
    //---

    vwap = iCustom(Symbol(), Period(), "VWAP");    
    obv = iCustom(Symbol(), Period(), "OBV",VOLUME_TICK);
    handle = iStochastic(Symbol(), PERIOD_M1, 5, 3, 3, MODE_SMA, STO_LOWHIGH);

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
    CopyRates(_Symbol, _Period, 1, 2, BarData);
    //CopyRates(_Symbol, PERIOD_M5, 1, 2, BarDataCinco);

    mudouCandle = VerificarMudouCandle();
    
    ordemAberta = OrdemAberta(_Symbol);
    
    
    
    
    if (ordemAberta) horarioFecharPosicaoIndice("17:45",SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Symbol,1);

    if (mudouCandle)
    {    
    
    
        funcao_verifica_meta_ou_perda_atingida("Teste",-100,100,true);
    
        ArraySetAsSeries(vwapArray, true);
        //ArraySetAsSeries(stochast, true);
        //ArraySetAsSeries(signal, true);
        ArraySetAsSeries(obvArray, true);
        
        
        CopyBuffer(vwap, 0, 0, 3, vwapArray);        
        CopyBuffer(obv, 0, 0, 3, obvArray);    
        //CopyBuffer(handle, 0, 0, 3, stochast);
        //CopyBuffer(handle, 1, 0, 3, signal);

        double tamanhoCandle = 0;
        double sombraInf = 0;
        double sombraSup = 0;
        string sinalCandle = "";
        string sentidoSombra = "";

        double tamanhoCandleDois = 0;
        string sinalCandleDois = "";

        //double razao = 0;

        if (BarData[ultimo].close > BarData[ultimo].open)
        {
            tamanhoCandle = BarData[ultimo].close - BarData[ultimo].open;
            sombraSup = BarData[ultimo].high - BarData[ultimo].close;
            sombraInf = BarData[ultimo].open - BarData[ultimo].low;
            sinalCandle = "C";
        }

        else
        {
            tamanhoCandle = BarData[ultimo].open - BarData[ultimo].close;
            sombraSup = BarData[ultimo].high - BarData[ultimo].open;
            sombraInf = BarData[ultimo].close - BarData[ultimo].low;
            sinalCandle = "V";
        }

        /*if (BarData[1].close > BarData[1].open){
        tamanhoCandleDois = BarData[1].close - BarData[1].open;   
        sinalCandleDois = "C";   
        }
        else {   
        tamanhoCandleDois = BarData[1].open - BarData[1].close;   
        sinalCandleDois = "V";      
        }*/

        if (sombraInf > sombraSup) sentidoSombra = "+";
        else sentidoSombra = "-";
        
        //double preco = SymbolInfoDouble(_Symbol, SYMBOL_ASK); // MAIOR
        //double preco2 = SymbolInfoDouble(_Symbol, SYMBOL_BID); // MENOR
        //datetime expiration=TimeTradeServer()+PeriodSeconds(PERIOD_M1);

        //COMPRA
        if (BarData[ultimo].open < vwapArray[1]
        && BarData[ultimo].close > vwapArray[1]
        && tamanhoCandle > tamanhoMinimo
        && horaOperar("17:00")
        && horaOperarInicio("09:05")
        && !ordemAberta
        && obvArray[1] > obvArray[2]
        //&& vwapArrayCinco[ultimo] > BarDataCinco[ultimo].open                
        //&& BarDataCinco[ultimo].open > mediaVinteArray[1]
        //&& sentidoSombra == "+"
        )
        {
        
            
            precoReferencia = BarData[ultimo].close + margemEntrada;
            expiration=TimeTradeServer()+PeriodSeconds(tempoExecucao);
        
            //trade.Buy(1, _Symbol, BarData[ultimo].high, BarData[ultimo].high - loss, BarData[ultimo].high + gain);
            //trade.BuyLimit(1,(BarData[ultimo].high + 100),_Symbol,BarData[ultimo].high - loss,BarData[ultimo].high + gain,ORDER_TIME_DAY,0);
            trade.BuyStop(1,precoReferencia,_Symbol,precoReferencia - loss,precoReferencia + gain,ORDER_TIME_SPECIFIED,expiration);
        }

        //VENDA
        if (BarData[ultimo].close < vwapArray[1]
        && BarData[ultimo].open > vwapArray[1]
        && tamanhoCandle > tamanhoMinimo
        && horaOperar("17:00")
        && horaOperarInicio("09:05")
        && !ordemAberta
        && obvArray[1] > obvArray[2]
        //&& vwapArrayCinco[ultimo] < BarDataCinco[ultimo].close
        //&& BarDataCinco[ultimo].close < mediaVinteArray[1]
        //&& sentidoSombra == "-"
        )
        {
        
        
            
            precoReferencia = BarData[ultimo].close - margemEntrada;
            expiration=TimeTradeServer()+PeriodSeconds(tempoExecucao);
            
            trade.SellStop(1,precoReferencia,_Symbol,precoReferencia + loss,precoReferencia - gain,ORDER_TIME_SPECIFIED,expiration);
        
            //operacao = "Venda";
            //trade.Sell(1, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), SymbolInfoDouble(_Symbol, SYMBOL_BID) + loss, SymbolInfoDouble(_Symbol, SYMBOL_BID) - gain);
        }
    }
}
//+------------------------------------------------------------------+


bool VerificarMudouCandle()
{
    if (BarData[ultimo].close != PrecoFechamentoPenultimoCandle)
    {
        PrecoFechamentoPenultimoCandle = BarData[ultimo].close;
        return true;
    }

    else return false;
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

bool horaOperarInicio(string inicioPrimeiroPeriodo)
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


bool OrdemAberta(string ativo)
{
    if (PositionSelect(ativo) == true) return true;
    else return false;
}


bool horarioFecharPosicaoIndice(string horarioMaximo,float precoAtual, string ativo, int tamanhoLote)
{

    
        ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
        double StopLossCorrente = PositionGetDouble(POSITION_SL);
        double GainCorrente = PositionGetDouble(POSITION_TP);
        double PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);
        
        
        datetime horaCorrente = TimeCurrent();

        string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    
    
        horaCorrente = StringToTime(   "2019.01.01 " + horaCorrenteStr);
    


        if (StringToTime(   "2019.01.01 " + horaCorrenteStr) > StringToTime(   "2019.01.01 " + horarioMaximo))
        {
             if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  trade.Sell(tamanhoLote, ativo, precoAtual);
             else trade.Buy(tamanhoLote, ativo, precoAtual);
             
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
   string         tmp_x;
   double         tmp_resultado_financeiro_dia;
   int            tmp_contador;
   MqlDateTime    tmp_data_b;
   
   TimeCurrent(tmp_data_b);
   tmp_resultado_financeiro_dia = 0;
   tmp_x = string(tmp_data_b.year) + "." + string(tmp_data_b.mon) + "." + string(tmp_data_b.day) + " 00:00:01";
   
   HistorySelect(StringToTime(tmp_x),TimeCurrent()); 
      int      tmp_total=HistoryDealsTotal(); 
      ulong    tmp_ticket=0; 
      double   tmp_price; 
      double   tmp_profit; 
      datetime tmp_time; 
      string   tmp_symboll; 
      long     tmp_typee; 
      long     tmp_entry; 
         
   //--- para todos os negócios 
      for(tmp_contador=0;tmp_contador<tmp_total;tmp_contador++) 
        { 
         //--- tentar obter ticket negócios 
         if((tmp_ticket=HistoryDealGetTicket(tmp_contador))>0) 
           { 
            //--- obter as propriedades negócios 
            tmp_price =HistoryDealGetDouble(tmp_ticket,DEAL_PRICE); 
            tmp_time  =(datetime)HistoryDealGetInteger(tmp_ticket,DEAL_TIME); 
            tmp_symboll=HistoryDealGetString(tmp_ticket,DEAL_SYMBOL); 
            tmp_typee  =HistoryDealGetInteger(tmp_ticket,DEAL_TYPE); 
            tmp_entry =HistoryDealGetInteger(tmp_ticket,DEAL_ENTRY); 
            tmp_profit=HistoryDealGetDouble(tmp_ticket,DEAL_PROFIT); 
            //--- apenas para o símbolo atual 
            if(tmp_symboll==Symbol()) tmp_resultado_financeiro_dia = tmp_resultado_financeiro_dia + tmp_profit;

           } 
        } 
   
   if (tmp_resultado_financeiro_dia == 0)
      {
          if (tmp_placar = true) Comment("Placar  0x0");
          return(false); //sem ordens no dia
      }
   else
      {
         if ((tmp_resultado_financeiro_dia > 0) && (tmp_resultado_financeiro_dia != 0))
            {
               if (tmp_placar = true) Comment("Lucro R$" + DoubleToString(NormalizeDouble(tmp_resultado_financeiro_dia, 2),2) );
            }
         else
            {
               if (tmp_placar = true) Comment("Prejuizo R$" + DoubleToString(NormalizeDouble(tmp_resultado_financeiro_dia, 2),2));
            }
         
         if (tmp_resultado_financeiro_dia < tmpValorMaximoPerda)
            {
               Print("Perda máxima alcançada.");
               return(true);
            }
         else
            {
               if (tmp_resultado_financeiro_dia > tmpValor_Maximo_Ganho)
               {
                  Print("Meta Batida.");
                  return(true);
               }
            }    
        }  
   return(false);
}


