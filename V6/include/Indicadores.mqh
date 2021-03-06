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
    bool StopGainMovel(float distanciaGain, float distanciaLoss, float proximoAlvo, string ativo, float precoAtual);
    bool OrdemAberta(string ativo);
    void IncializaIndicadores(int &posicoes[], int mediaRapida, int media, int mediaLonga, int mediaAdx,ENUM_TIMEFRAMES tempoGrafico,ENUM_APPLIED_VOLUME tipoVolume,string ativoCheio,int mediaLongaMACD,int mediaCurtaMACD,int sinalMACD,int mediaBanda,int desvioBanda,string ativoRenko,ENUM_TIMEFRAMES tempoGraficoRenko);
    void AtualizaIndicadoresTick(int &posicoes[], double &valorPorTick[],int quantidadeMedia);
    bool Venda (float loss, float gain,string ativo, int tamanhoLote);
    bool Compra(float loss, float gain,string ativo, int tamanhoLote);
    void BuscaUltimoTopoFundo(MqlRates &ultimasCotacoes[],double &topoFundo[],int quantidadeCandles);
    void BuscaUltimoTopoFundoPull(MqlRates &ultimasCotacoes[],double &topoFundo[],int quantidadeCandles);
    bool horariOperar(string inicioPrimeiroPeriodo,string fimPrimeiroPeriodo,string inicioSegundoPeriodo,string fimSegundoPeriodo);
    double margemEntrada(double mediaCurta, double media, double mediaLonga,double PrecoTick,int margem);
    bool horarioFecharPosicao(string horarioMaximo,float precoAtual, string ativo);
    bool CompraAlvosLimite(float loss, float gain,string ativo, int tamanhoLote);
    bool VendaAlvosLimite(float loss, float gain,string ativo, int tamanhoLote);
    void Indicadores::FecharTudo(string ativo);


};


/*============================= FUNCOES ========================================*/

CTrade trade;

bool Indicadores::VendaAlvosLimite(float loss, float gain,string ativo, int tamanhoLote){

    double ask = SymbolInfoDouble(ativo, SYMBOL_BID);
    if (!OrdemAberta(ativo))
    {
        trade.Sell(tamanhoLote, ativo, ask, ask + loss);
        //trade.Sell(tamanhoLote, ativo, ask);  
        //trade.BuyLimit(tamanhoLote, ask + loss, ativo);  
        trade.BuyLimit(tamanhoLote, ask - gain, ativo);  
        //LOGAR
        return true;
    }
    else
    {
        //LOGAR
        return false;
    }
}

bool Indicadores::CompraAlvosLimite(float loss, float gain,string ativo, int tamanhoLote)
{

    double bid = SymbolInfoDouble(ativo, SYMBOL_ASK);
    if (!OrdemAberta(ativo))
    {
        trade.Buy(tamanhoLote, ativo, bid, bid - loss);  
        //trade.Buy(tamanhoLote, ativo, bid);
        //trade.SellLimit(tamanhoLote, bid - loss, ativo);  
        trade.SellLimit(tamanhoLote, bid + gain, ativo);          
        //LOGAR
        return true;
    }
    else
    {
        //LOGAR
        return false;
    }
}


void Indicadores::FecharTudo(string ativo)
{

    trade.PositionClose(ativo);
}


bool Indicadores::OrdemAberta(string ativo)
{
    if (PositionSelect(ativo) == true) return true;
    else return false;
}


bool Indicadores::Venda (float loss, float gain,string ativo, int tamanhoLote){

    double ask = SymbolInfoDouble(ativo, SYMBOL_BID);
    if (!OrdemAberta(ativo))
    {
        trade.Sell(tamanhoLote, ativo, ask, ask + loss, ask - gain, "");        
        //LOGAR
        return true;
    }
    else
    {
        //LOGAR
        return false;
    }
}

bool Indicadores::Compra(float loss, float gain,string ativo, int tamanhoLote)
{

    double bid = SymbolInfoDouble(ativo, SYMBOL_ASK);
    if (!OrdemAberta(ativo))
    {
        trade.Buy(tamanhoLote, ativo, bid, bid - loss, bid + gain, "");        
        //LOGAR
        return true;
    }
    else
    {
        //LOGAR
        return false;
    }
}

bool Indicadores::StopGainMovel(float distanciaGain, float distanciaLoss, float proximoAlvo, string ativo, float precoAtual)
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

void Indicadores::IncializaIndicadores(int &posicoes[], int mediaRapida, int media, int mediaLonga, int mediaAdx,ENUM_TIMEFRAMES tempoGrafico,ENUM_APPLIED_VOLUME tipoVolume,string ativoCheio,int mediaLongaMACD,int mediaCurtaMACD,int sinalMACD,int mediaBanda,int desvioBanda,string ativoRenko,ENUM_TIMEFRAMES tempoGraficoRenko)
{

    //ENUM_APPLIED_VOLUME  applied_volume=VOLUME_REAL;   // tipo de volume
    posicoes[0] = iMA(ativoRenko, tempoGraficoRenko, mediaRapida, 0, MODE_EMA, PRICE_CLOSE);
    posicoes[1] = iMA(ativoRenko, tempoGraficoRenko, media, 0, MODE_EMA, PRICE_CLOSE);
    posicoes[2] = iMA(ativoRenko, tempoGraficoRenko, mediaLonga, 0, MODE_EMA, PRICE_CLOSE);
    posicoes[3] = iBands(ativoRenko, tempoGraficoRenko, mediaBanda, 0, desvioBanda, PRICE_CLOSE);
    posicoes[4] = iMACD(ativoRenko, tempoGraficoRenko, mediaCurtaMACD, mediaLongaMACD, sinalMACD, PRICE_CLOSE);
    posicoes[5]=  iADX(ativoRenko,tempoGraficoRenko,mediaAdx);
    //posicoes[6]=  iVolumes(ativoCheio,tempoGrafico,tipoVolume);    
    
}

void Indicadores::AtualizaIndicadoresTick(int &posicoes[], double &valorPorTick[],int quantidadeMedia)
{
    double MediaCurtaArray[];
    //double MediaArray[];
    //double MediaLongaArray[];
    double MACDArray[];
    double SuperiorBandArray[];
    double InferiorBandArray[];
    double ADXArray[];
    double VolumeArray[];
    quantidadeMedia = quantidadeMedia + 1;

    ArraySetAsSeries(MediaCurtaArray, true);
    //ArraySetAsSeries(MediaArray, true);
    //ArraySetAsSeries(MediaLongaArray, true);
    ArraySetAsSeries(MACDArray, true);
    ArraySetAsSeries(SuperiorBandArray, true);
    ArraySetAsSeries(InferiorBandArray, true);
    ArraySetAsSeries(ADXArray, true);
    //ArraySetAsSeries(VolumeArray, true);

    CopyBuffer(posicoes[0], 0, 0, 3, MediaCurtaArray);
    //CopyBuffer(posicoes[1], 0, 0, 3, MediaArray);
    //CopyBuffer(posicoes[2], 0, 0, 3, MediaLongaArray);
    CopyBuffer(posicoes[3], 1, 0, 3, SuperiorBandArray);
    CopyBuffer(posicoes[3], 2, 0, 3, InferiorBandArray);
    CopyBuffer(posicoes[4], 0, 0, 3, MACDArray);
    CopyBuffer(posicoes[5], 0, 0, 3, ADXArray);
    //CopyBuffer(posicoes[6], 0, 0, quantidadeMedia, VolumeArray);

    valorPorTick[0] = MediaCurtaArray[0];
    //valorPorTick[1] = MediaArray[0];
    //valorPorTick[2] = MediaLongaArray[0];
    valorPorTick[3] = SuperiorBandArray[0];
    valorPorTick[4] = InferiorBandArray[0];
    valorPorTick[5] = MACDArray[0];
    valorPorTick[6] = ADXArray[0];
    valorPorTick[7] = ADXArray[1];
    valorPorTick[8] = 0;
    
    /*int x = 0;
    
    for (x = 1; x < quantidadeMedia; x++){
    
    valorPorTick[8] = valorPorTick[8] + VolumeArray[x];
    
    }*/
   //valorPorTick[8] = valorPorTick[8] / (quantidadeMedia - 1);
    
       
    //valorPorTick[10] = VolumeArray[1];   
    
    
    
    
    
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

bool Indicadores::horariOperar(string inicioPrimeiroPeriodo,string fimPrimeiroPeriodo,string inicioSegundoPeriodo,string fimSegundoPeriodo)
{
    datetime horaCorrente = TimeCurrent();

    string horaCorrenteStr = TimeToString(horaCorrente, TIME_MINUTES);    
    
    horaCorrente = StringToTime(   "2019.01.01 " + horaCorrenteStr);    

    if (
    (  StringToTime(   "2019.01.01 " + horaCorrenteStr)  >= StringToTime(   "2019.01.01 " + inicioPrimeiroPeriodo)  
        && StringToTime(   "2019.01.01 " + horaCorrenteStr)  <= StringToTime(   "2019.01.01 " + fimPrimeiroPeriodo) ) ||
         (StringToTime(   "2019.01.01 " + horaCorrenteStr)  >= StringToTime(   "2019.01.01 " + inicioSegundoPeriodo) 
         && StringToTime(   "2019.01.01 " + horaCorrenteStr)  <= StringToTime(   "2019.01.01 " + fimSegundoPeriodo))
         )
         
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


bool Indicadores::horarioFecharPosicao(string horarioMaximo,float precoAtual, string ativo)
{

    if (OrdemAberta(ativo))
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
             if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  trade.PositionModify(PositionTicket, precoAtual - 1, precoAtual + 1);
             else trade.PositionModify(PositionTicket, precoAtual + 1, precoAtual - 1);
             
             return true;
           
        }
        else return false;
        
        
    }
    return false;
   

}


