//+------------------------------------------------------------------+
//|                                                  Indicadores.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Leonardo Bezerra"
#property link      "https://www.mql5.com"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

class Indicadores

{
    public:
    string SentidoMedias(double mediaCurta, double media, double mediaLonga);
    bool Indicadores::StopGainMovel(int distanciaGain, int distanciaLoss, int proximoAlvo, string ativo, int precoAtual);
    bool OrdemAberta(string ativo);
    void IncializaIndicadores(int &posicoes[], int mediaRapida, int media, int mediaLonga);
    void AtualizaIndicadoresTick(int &posicoes[], double &valorPorTick[]);
    bool Venda (int loss, int gain,string ativo);
    bool Compra(int loss, int gain,string ativo);
    void BuscaUltimoTopoFundo(MqlRates &ultimasCotacoes[],double &topoFundo[],int quantidadeCandles);
    void BuscaUltimoTopoFundoPull(MqlRates &ultimasCotacoes[],double &topoFundo[],int quantidadeCandles);
    bool horariOperar(int inicioPrimeiroPeriodo,int fimPrimeiroPeriodo);
    double margemEntrada(double mediaCurta, double media, double mediaLonga,double PrecoTick,int margem);


};


/*============================= FUNCOES ========================================*/

CTrade trade;


bool Indicadores::OrdemAberta(string ativo)
{
    if (PositionSelect(ativo) == true) return true;
    else return false;
}


bool Indicadores::Venda (int loss, int gain,string ativo){

    double bid = SymbolInfoDouble(ativo, SYMBOL_BID);
    if (!OrdemAberta(ativo))
    {
        trade.Sell(1, ativo, bid, bid + loss, bid - gain, "");        
        //LOGAR
        return true;
    }
    else
    {
        //LOGAR
        return false;
    }
}


bool Indicadores::Compra(int loss, int gain,string ativo)
{

    double ask = SymbolInfoDouble(ativo, SYMBOL_ASK);
    if (!OrdemAberta(ativo))
    {
        trade.Buy(1, ativo, ask, ask - loss, ask + gain, "");        
        //LOGAR
        return true;
    }
    else
    {
        //LOGAR
        return false;
    }
}

bool Indicadores::StopGainMovel(int distanciaGain, int distanciaLoss, int proximoAlvo, string ativo, int precoAtual)
{

    if (OrdemAberta(ativo))
    {
        ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
        double StopLossCorrente = PositionGetDouble(POSITION_SL);
        double GainCorrente = PositionGetDouble(POSITION_TP);
        double PrecoAberturaPosicao = PositionGetDouble(POSITION_PRICE_OPEN);

        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            if (GainCorrente - precoAtual < distanciaGain)
            {
                trade.PositionModify(PositionTicket, precoAtual - distanciaLoss, precoAtual + proximoAlvo);
            }
        }
        else
        {
            if (precoAtual - GainCorrente < distanciaGain)
            {
                trade.PositionModify(PositionTicket, precoAtual + distanciaLoss, precoAtual - proximoAlvo);
            }
        }

        return true;
    }

    else return false;

}

void Indicadores::IncializaIndicadores(int &posicoes[], int mediaRapida, int media, int mediaLonga)
{
    posicoes[0] = iMA(_Symbol, _Period, mediaRapida, 0, MODE_EMA, PRICE_CLOSE);
    //posicoes[1] = iMA(_Symbol, _Period, media, 0, MODE_EMA, PRICE_CLOSE);
    //posicoes[2] = iMA(_Symbol, _Period, mediaLonga, 0, MODE_EMA, PRICE_CLOSE);
    posicoes[3] = iBands(_Symbol, _Period, 20, 0, 2, PRICE_CLOSE);
    posicoes[4] = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
}

void Indicadores::AtualizaIndicadoresTick(int &posicoes[], double &valorPorTick[])
{
    double MediaCurtaArray[];
    double MediaArray[];
    double MediaLongaArray[];
    double MACDArray[];
    double SuperiorBandArray[];
    double InferiorBandArray[];

    ArraySetAsSeries(MediaCurtaArray, true);
    ArraySetAsSeries(MediaArray, true);
    ArraySetAsSeries(MediaLongaArray, true);
    ArraySetAsSeries(MACDArray, true);
    ArraySetAsSeries(SuperiorBandArray, true);
    ArraySetAsSeries(InferiorBandArray, true);

    CopyBuffer(posicoes[0], 0, 0, 3, MediaCurtaArray);
    //CopyBuffer(posicoes[1], 0, 0, 3, MediaArray);
    //CopyBuffer(posicoes[2], 0, 0, 3, MediaLongaArray);
    CopyBuffer(posicoes[3], 1, 0, 3, SuperiorBandArray);
    CopyBuffer(posicoes[3], 2, 0, 3, InferiorBandArray);
    CopyBuffer(posicoes[4], 0, 0, 3, MACDArray);

    valorPorTick[0] = MediaCurtaArray[0];
    //valorPorTick[1] = MediaArray[0];
    //valorPorTick[2] = MediaLongaArray[0];
    valorPorTick[3] = SuperiorBandArray[0];
    valorPorTick[4] = InferiorBandArray[0];
    valorPorTick[5] = MACDArray[0];
}


string Indicadores::SentidoMedias(double mediaCurta, double media, double mediaLonga)
{
    if (mediaCurta < media && media < mediaLonga) return "Venda";
    else if (mediaCurta > media && media > mediaLonga) return "Compra";
    else return "Consolidacao";
}

void Indicadores::BuscaUltimoTopoFundo(MqlRates &ultimasCotacoes[],double &topoFundo[],int quantidadeCandles)
{
    int x = 0;    
    double valorUltimoTopo = 0;
    double valorUltimoFundo = 1000000;

    for (x = 0; x <= quantidadeCandles - 1; x++)
    {          
            if (ultimasCotacoes[x].close > valorUltimoTopo) valorUltimoTopo = ultimasCotacoes[x].close ;          
            if (ultimasCotacoes[x].close < valorUltimoFundo) valorUltimoFundo = ultimasCotacoes[x].close ;                      
    }   
    
    topoFundo[0] = valorUltimoTopo;
    topoFundo[1] = valorUltimoFundo;

}

void Indicadores::BuscaUltimoTopoFundoPull(MqlRates &ultimasCotacoes[],double &topoFundo[],int quantidadeCandles)
{
    int x = 0;
    bool virou = false;    
    double valorUltimoTopo = 1000000;
    double valorUltimoFundo = 0;

    for (x = quantidadeCandles - 1; x >= 0; x--)
    {          
            if (ultimasCotacoes[x].close < valorUltimoTopo && !virou) valorUltimoTopo = ultimasCotacoes[x].close ;
            else if (!virou) { virou = true;valorUltimoTopo = ultimasCotacoes[x].close;}
            else if (ultimasCotacoes[x].close > valorUltimoTopo) valorUltimoTopo = ultimasCotacoes[x].close ;
            else break;       
    }
    
    virou = false;    
    
    for (x = quantidadeCandles - 1; x >= 0; x--)
    {
            if (ultimasCotacoes[x].close > valorUltimoFundo && !virou) valorUltimoFundo = ultimasCotacoes[x].close ;
            else if (!virou) { virou = true;valorUltimoFundo = ultimasCotacoes[x].close;}
            else if (ultimasCotacoes[x].close > valorUltimoFundo) valorUltimoFundo = ultimasCotacoes[x].close ;
            else break;       
    }
    
    topoFundo[0] = valorUltimoTopo;
    topoFundo[1] = valorUltimoFundo;

}

bool Indicadores::horariOperar(int inicioPrimeiroPeriodo,int fimPrimeiroPeriodo)
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);

    int horaAtual = StringToInteger(StringSubstr(horaCorrenteStr, 0, 2));

    if ((horaAtual >= inicioPrimeiroPeriodo && horaAtual <= fimPrimeiroPeriodo)  ) // || horaAtual > 14) && horaAtual < 16)
        return true;
    else return false;

}

double Indicadores::margemEntrada(double mediaCurta, double media, double mediaLonga,double PrecoTick,int margem)
{

if ( (PrecoTick - mediaCurta < margem && PrecoTick - mediaCurta > -margem) || (mediaCurta - PrecoTick < margem  &&  mediaCurta - PrecoTick > -margem )) return mediaCurta;
//if ( (PrecoTick - media < margem && PrecoTick - media > -margem) || (media - PrecoTick < margem  &&  media - PrecoTick > -margem )) return media;
//if ( (PrecoTick - mediaLonga < margem && PrecoTick - mediaLonga > -margem) || (mediaLonga - PrecoTick < margem  &&  mediaLonga - PrecoTick > -margem )) return mediaLonga;
else return 0;

}