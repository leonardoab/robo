//+------------------------------------------------------------------+
//|                                                  RenkoCharts.mqh |
//|                                Copyright 2018, Guilherme Santos. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Guilherme Santos."
#property link      "www.facebook.com/RenkoCharts2"
//+------------------------------------------------------------------+
//| includes                                                         |
//+------------------------------------------------------------------+
#include "Symbol.mqh"
//+------------------------------------------------------------------+
//| types                                                            |
//+------------------------------------------------------------------+
enum ENUM_RENKO_TYPE
  {
   RENKO_TYPE_TICKS, //Ticks
   RENKO_TYPE_PIPS,  //Pips
   RENKO_TYPE_POINTS //Points
  };
//Enum
enum ENUM_RENKO_WINDOW
  {
   RENKO_NO_WINDOW,        //No Window
   RENKO_CURRENT_WINDOW,   //Current Window
   RENKO_NEW_WINDOW,       //New Window
   RENKO_MINI_CHART        //Mini Chart
  };
//+------------------------------------------------------------------+
//| class                                                            |
//+------------------------------------------------------------------+
class RenkoCharts
  {
//Internal Variables
private:
   MqlTick  ticks[];             //Ticks buffer
   MqlRates rates[],             //Rates buffer
            renko_buffer[];      //Renko buffer
   string   renko_symbol,        //Original symbol
            custom_symbol;       //Custom symbol
   double   renko_size,          //Renko size
            brick_size,          //Brick size
            up_wick,             //Upper wick size
            down_wick,           //Down wick size
            last_price;          //Last price
   long     tick_volumes,        //Tick Volumes
            volumes;             //Volumes
   bool     show_wicks;          //Show renko wicks
   ENUM_RENKO_TYPE renko_type;
//Methods
public:
   RenkoCharts();
   ~RenkoCharts();
   RenkoCharts(string symbol, ENUM_RENKO_TYPE type, double size, bool wicks);
   bool     Setup(string symbol, ENUM_RENKO_TYPE type, double size, bool wicks);
   int      LoadFrom(datetime start);
   long     LoadVolumes(datetime start, bool ticks);
   int      UpdateRates();
   int      UpdatePrice(double price, datetime time, long tick_volume, long volume, int spread);
   int      ClearRates();
   double   GetValue(int buffer, int index);
   double   GetValueAsSeries(int buffer, int index);
//Custom Symbol Methods
   string   GetSymbolName();
   void     CreateCustomSymbol(string name);
   bool     CheckCustomSymbol();
   int      ClearCustomSymbol();
   int      ReplaceCustomSymbol();
   int      UpdateCustomSymbol(int count);
   long     OpenCustomSymbol();
   void     SetCustomSymbol(long chart_id);
   bool     ValidateSymbol(string &name);
   int      UpdateCustomTick();
//Event Methods
   void     Start(ENUM_RENKO_WINDOW window);
   void     Stop();
   void     Refresh();
//Internal Methods
private:
   int AddOne(datetime time);
   int CloseUp(double points, datetime time, int spread);
   int CloseDown(double points, datetime time, int spread);
   int LoadPrice(double price, datetime time, long tick_volume, long volume, int spread);
   int LoadPrice(const MqlRates &price);
   int LoadPriceOHLC(const MqlRates &price);
   void MiniChartCustomSymbol();
  };
//+------------------------------------------------------------------+
//| methods                                                          |
//+------------------------------------------------------------------+
//Default Constructors
RenkoCharts::RenkoCharts()
  {
   Setup(_Symbol, RENKO_TYPE_TICKS, 20, true);
   return;
  }

RenkoCharts::RenkoCharts(string symbol, ENUM_RENKO_TYPE type = RENKO_TYPE_TICKS, double size = 20, bool wicks = true)
  {
   Setup(symbol, type, size, wicks);
   return;
  }

RenkoCharts::~RenkoCharts()
  {
   ArrayFree(rates); 
   ArrayFree(renko_buffer); 
  }

//Setup
bool RenkoCharts::Setup(string symbol, ENUM_RENKO_TYPE type = RENKO_TYPE_TICKS, double size = 20, bool wicks = true)
  {
//Check Symbol
   if(symbol == "" || symbol == NULL || SymbolInfoInteger(symbol, SYMBOL_CUSTOM))
     {
      Print("Invalid symbol selected.");
      return(false);
     }
//Select Symbol
   if(SymbolSelect(symbol, true) == false)
     {
      Print("Symbol selection error.");
      return(false);
     }     
//Renko setup
   renko_symbol = symbol;
   renko_type = type;
   renko_size = size;
   show_wicks = wicks;
//Renko brick size
   int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double points = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double pip_size = (digits == 5 || digits == 3) ? points * 10 : points;
   if(renko_type == RENKO_TYPE_TICKS) brick_size = renko_size * tick_size;
   else if(renko_type == RENKO_TYPE_PIPS) brick_size = renko_size * pip_size;
   else brick_size = renko_size;
//Invalid brick size
   if(brick_size <= 0)
     {
      Print("Invalid brick size. Value of ", brick_size, " selected.");
      return(false);
     }
//Minimum brick size
   if(brick_size < tick_size)
     {
      brick_size = tick_size;
      Print("Invalid brick size. Minimum value of ", brick_size, " will be used.");
     }
   brick_size = NormalizeDouble(brick_size, digits);
//Success
   return(true);
  }

//Add one to buffer array
int RenkoCharts::AddOne(datetime time = 0)
  {
   //Resize buffers
   int index = ArrayResize(renko_buffer, ArraySize(renko_buffer)+1, 100000) - 1;
   if(index <= 0) return 0;
   //Time
   if(time == 0) time = TimeCurrent();
   if(time <= renko_buffer[index-1].time) 
      renko_buffer[index].time = renko_buffer[index-1].time+60;
   else 
      renko_buffer[index].time = time;
   //Defaults         
   renko_buffer[index].open = renko_buffer[index].high = renko_buffer[index].low = renko_buffer[index].close = renko_buffer[index-1].close;
   renko_buffer[index].tick_volume = renko_buffer[index].real_volume = 0;
   renko_buffer[index].spread = 0;
   return index;
  }

//Add positive renko bar
int RenkoCharts::CloseUp(double points, datetime time=0, int spread=0)
  {
   int index = ArraySize(renko_buffer) -1;
   //OHLC
   renko_buffer[index].open = renko_buffer[index-1].close + points - brick_size;
   renko_buffer[index].high = renko_buffer[index-1].close + points;
   renko_buffer[index].close = renko_buffer[index-1].close+points;
   //Wicks
   if(show_wicks && down_wick < renko_buffer[index-1].close) renko_buffer[index].low = down_wick;
   else renko_buffer[index].low = renko_buffer[index].open;
   up_wick = down_wick = renko_buffer[index].close;
   //Volumes
   renko_buffer[index].tick_volume = tick_volumes;
   renko_buffer[index].real_volume = volumes;
   renko_buffer[index].spread = spread;
   tick_volumes = volumes = 0;
   //Add one
   return AddOne(time);
  }

//Add negative renko bar
int RenkoCharts::CloseDown(double points, datetime time=0, int spread=0)
  {
   int index = ArraySize(renko_buffer) -1;
   //OHLC
   renko_buffer[index].open = renko_buffer[index-1].close-points+brick_size;
   renko_buffer[index].low = renko_buffer[index-1].close-points;
   renko_buffer[index].close = renko_buffer[index-1].close-points;
   //Wicks
   if(show_wicks && up_wick > renko_buffer[index-1].close) renko_buffer[index].high = up_wick;
   else renko_buffer[index].high = renko_buffer[index].open;
   up_wick = down_wick = renko_buffer[index].close;
   //Volumes
   renko_buffer[index].tick_volume = tick_volumes;
   renko_buffer[index].real_volume = volumes;
   renko_buffer[index].spread = spread;
   tick_volumes = volumes = 0;
   //Add one
   return AddOne(time);
  }

//Load price information
int RenkoCharts::LoadPrice(double price, datetime time=0, long tick_volume=0, long volume=0, int spread=0)
  {
   static datetime last_time;
   static long last_tick_volume, last_volume;
   //Time
   if(time == 0) time = TimeCurrent();
   //Buffer size
   int size = ArraySize(renko_buffer);
   int index = size-1;
   //First bricks
   if(size==0)
     {
      //1st Buffers
      ArrayResize(renko_buffer, 2, 1000);
      renko_buffer[1].time = time - 60;
      renko_buffer[1].close = renko_buffer[1].high = NormalizeDouble(MathFloor(price/brick_size) * brick_size,_Digits);
      renko_buffer[1].open = renko_buffer[1].low = renko_buffer[1].close - brick_size;
      renko_buffer[1].tick_volume = renko_buffer[1].real_volume = 0;
      renko_buffer[1].spread = 0;
      renko_buffer[0].time = renko_buffer[1].time - 120;
      renko_buffer[0].open = renko_buffer[0].low = renko_buffer[1].open - brick_size;
      renko_buffer[0].high = renko_buffer[0].close = renko_buffer[1].open;
      renko_buffer[0].tick_volume = renko_buffer[0].real_volume = 0;
      renko_buffer[0].spread = 0;
      //Current Buffer
      index = AddOne(time);
     }
   //Time change
   if(time != last_time)
     {
      last_time = time;
      tick_volumes += last_tick_volume;
      volumes += last_volume;
     }
   //Volume change
   last_tick_volume = tick_volume;
   last_volume = volume;
   //Wicks
   up_wick = MathMax(up_wick, price);
   down_wick = MathMin(down_wick, price);
   if(down_wick<=0) down_wick = price;
   //Price change
   if(price != last_price)
     {
      last_price = price;
      //Up
      if(renko_buffer[index-1].close >= renko_buffer[index-2].close)
        {
         if(price >= renko_buffer[index-1].close+brick_size)
           {
            for(; price >= renko_buffer[index-1].close+brick_size;)
               index = CloseUp(brick_size, time, spread);
           } 
         //Down 2x
         else if(price <= renko_buffer[index-1].close-2.0*brick_size) 
           {
            index = CloseDown(2.0*brick_size, time, spread);
            for(; price <= renko_buffer[index-1].close-brick_size;)
               index = CloseDown(brick_size, time, spread);
           }
        }
      //Down
      if(renko_buffer[index-1].close <= renko_buffer[index-2].close)
        {
         if(price <= renko_buffer[index-1].close-brick_size)
           {
            for(; price <= renko_buffer[index-1].close-brick_size;)
               index = CloseDown(brick_size, time, spread);
           } 
         //Up 2x
         else if(price >= renko_buffer[index-1].close+2.0*brick_size)
           {
            index = CloseUp(2.0*brick_size, time, spread);
            for(; price >= renko_buffer[index-1].close+brick_size;)
               index = CloseUp(brick_size, time, spread);
           }
        }
     }
   //Current buffer
   renko_buffer[index].open = renko_buffer[index-1].close;
   renko_buffer[index].high = MathMax(up_wick, price);
   renko_buffer[index].low = MathMin(down_wick, price);
   renko_buffer[index].close = price;
   renko_buffer[index].tick_volume = tick_volumes + tick_volume;
   renko_buffer[index].real_volume = volumes + volume;
   renko_buffer[index].spread = spread;

   return index + 1;
  }

//Load price rates information
int RenkoCharts::LoadPrice(const MqlRates &price)
  {
   //Price
   return LoadPrice(price.close, price.time, price.tick_volume, price.real_volume, price.spread);
  }

//Load OHLC price rates information
int RenkoCharts::LoadPriceOHLC(const MqlRates &price)
  {
   LoadPrice(price.open, price.time, 0, 0, price.spread);
   if(price.close > price.open)
     {
      LoadPrice(price.low, price.time, 0, 0, price.spread);
      LoadPrice(price.high, price.time, 0, 0, price.spread);
     }
   else
     {
      LoadPrice(price.high, price.time, 0, 0, price.spread);
      LoadPrice(price.low, price.time, 0, 0, price.spread);
     }
   return LoadPrice(price.close, price.time, price.tick_volume, price.real_volume, price.spread);
  }

//Load history
int RenkoCharts::LoadFrom(datetime start = 0)
  {
   ResetLastError();
   int total, size = ArraySize(renko_buffer);
   //Copy rates
   if(size == 0)
      total = CopyRates(renko_symbol, PERIOD_M1, 0, 1000000, rates);
   else 
      total = CopyRates(renko_symbol, PERIOD_M1, start - 59, TimeCurrent(), rates);
   //Return
   if(total <= 0)
      return 0; 
   else if(total == 1) 
      size = LoadPrice(rates[0]);
   else for(int i=0; i<total; i++)
      size = LoadPriceOHLC(rates[i]);
   return size;
  }

//Update Rates
int RenkoCharts::UpdateRates()
  {
   static datetime last_update = 0;
   int size = LoadFrom(last_update);
   last_update = TimeCurrent();
   return size;
  }

//Clear Rates
int RenkoCharts::ClearRates()
  {
   return ArrayResize(renko_buffer, 0);
  }

//Get values
double RenkoCharts::GetValue(int buffer = 0, int index = -1)
  {
   index = (index<0) ? ArraySize(renko_buffer)-1 : index;
   if(index<0) return EMPTY_VALUE;
   switch(buffer)
   {
      case  0: return (double) renko_buffer[index].time;          break; //Time
      case  1: return          renko_buffer[index].open;          break; //Open
      case  2: return          renko_buffer[index].high;          break; //High
      case  3: return          renko_buffer[index].low;           break; //Low
      case  4: return          renko_buffer[index].close;         break; //Close
      case  5: return (double) renko_buffer[index].tick_volume;   break; //Tick volume
      case  6: return (double) renko_buffer[index].real_volume;   break; //Volume
      case  7: return (double) renko_buffer[index].spread;        break; //Spread
      case  8: return (double) renko_buffer[index].open < renko_buffer[index].close ? 1 : renko_buffer[index].open == renko_buffer[index].close ? 0 : -1; break; //Direction
      default: return EMPTY_VALUE; break;
   }
  }

//Get values as Series
double RenkoCharts::GetValueAsSeries(int buffer = 0, int index = -1)
{
   index = ArraySize(renko_buffer)-index;
   index = (index<=0) ? ArraySize(renko_buffer)-1 : index-1;
   if(index<0) return EMPTY_VALUE;
   switch(buffer)
   {
      case  0: return (double) renko_buffer[index].time;          break; //Time
      case  1: return          renko_buffer[index].open;          break; //Open
      case  2: return          renko_buffer[index].high;          break; //High
      case  3: return          renko_buffer[index].low;           break; //Low
      case  4: return          renko_buffer[index].close;         break; //Close
      case  5: return (double) renko_buffer[index].tick_volume;   break; //Tick volume
      case  6: return (double) renko_buffer[index].real_volume;   break; //Volume
      case  7: return (double) renko_buffer[index].spread;        break; //Spread
      case  8: return (double) renko_buffer[index].open < renko_buffer[index].close ? 1 : renko_buffer[index].open == renko_buffer[index].close ? 0 : -1; break; //Direction
      default: return EMPTY_VALUE; break;
   }    
}  

//+------------------------------------------------------------------+
//| custom symbol methods                                            |
//+------------------------------------------------------------------+
//Return custom symbol name
string RenkoCharts::GetSymbolName()
  {
   return custom_symbol;
  }

//Create renko custom symbol
void RenkoCharts::CreateCustomSymbol(string name = "")
  {
   custom_symbol = name;
   //Symbol name
   if(name == "" || name == NULL)
     {
      string sufix = StringFormat("%g", renko_size);
      if(renko_type == RENKO_TYPE_TICKS) sufix += "TICKS";
      else if(renko_type == RENKO_TYPE_PIPS) sufix += "PIPS";
      else sufix += "POINTS";
      custom_symbol = renko_symbol + "_" + sufix;
     }
   //Create symbol
   const SYMBOL Symb(custom_symbol, "RenkoCharts");  
   Symb.CloneProperties(renko_symbol);
   Symb.On();
   //Select Custom Symbol
   if(SymbolSelect(custom_symbol, true) == false)
      Print("Custom Symbol selection error.");
   return;
  }

//Check custom symbol
bool RenkoCharts::CheckCustomSymbol()
  {
   if(custom_symbol == "" || custom_symbol == NULL)
      return(false);
   return(SymbolInfoInteger(custom_symbol, SYMBOL_CUSTOM));
  }
 
//Clear custom symbol rates
int RenkoCharts::ClearCustomSymbol()
  {
   if(!CheckCustomSymbol()) return 0;
   return CustomRatesDelete(custom_symbol, D'1970.01.01 00:00', D'3000.12.31 00:00');
  }
  
//Update custom symbol rates
int RenkoCharts::ReplaceCustomSymbol()
  {
   if(!CheckCustomSymbol()) return 0;
   return CustomRatesUpdate(custom_symbol, renko_buffer);
  }

//Refresh custom symbol last rates
int RenkoCharts::UpdateCustomSymbol(int count = 0)
  {
   static int last_position = 0;
   if(!CheckCustomSymbol()) return 0;
   //Update buffer
   MqlRates update_buffer[];
   ArraySetAsSeries(update_buffer, true);
   //Start position
   int start = last_position - count;
   if(start < 0) start = 0;
   //Copy last buffer
   int copied = ArrayCopy(update_buffer, renko_buffer, 0, start);
   if(copied <= 0) return 0;
   //Save last position
   last_position = ArraySize(renko_buffer) - 1;
   return CustomRatesUpdate(custom_symbol, update_buffer);
  }

//Update custom tick
int RenkoCharts::UpdateCustomTick()
  {
   if(!CheckCustomSymbol()) return 0;
   //Get current tick
   int copied = CopyTicks(renko_symbol, ticks, COPY_TICKS_ALL, 0, 1);
   if(copied <= 0) return 0;
   //Update current tick
   ticks[0].time = (datetime) GetValue(0); //Time buffer
   ticks[0].time_msc = 1000 * (long) ticks[0].time;
   //Update Custom Tick
   copied = CustomTicksAdd(custom_symbol, ticks);
   return copied;
  }

//Open custom symbol window
long RenkoCharts::OpenCustomSymbol()
  {
   if(!CheckCustomSymbol()) return -1;
   long chart_handle = ChartOpen(custom_symbol, PERIOD_M1);
   ChartSetInteger(chart_handle, CHART_MODE, CHART_CANDLES);
   return chart_handle;
  }

//Set chart current symbol
void RenkoCharts::SetCustomSymbol(long chart_id = 0)
  {
   if(!CheckCustomSymbol()) return;
   ChartSetSymbolPeriod(chart_id, custom_symbol, PERIOD_M1);
   ChartSetInteger(chart_id, CHART_MODE, CHART_CANDLES);
  }

//Validate original symbol
bool RenkoCharts::ValidateSymbol(string &name)
  {
   if(name=="" || name==NULL) 
      name = _Symbol;
   if(SymbolInfoInteger(name, SYMBOL_CUSTOM))
     {
      string new_name = StringAt(name, "_");
      if(SymbolInfoInteger(new_name, SYMBOL_CUSTOM))
         return false;
      else 
         name = new_name;
     }
   return true;
  }
  
//+------------------------------------------------------------------+
//| event methods                                                    |
//+------------------------------------------------------------------+

//Creates OnBookEvent on renko symbol
void RenkoCharts::Start(ENUM_RENKO_WINDOW window = RENKO_NO_WINDOW)
  {
   //Open/Set Custom Symbol
   Print("Updating Custom Symbol: ", custom_symbol);
   if(window == RENKO_NEW_WINDOW)
     {
      Comment("Updating Custom Symbol: ", custom_symbol);
      OpenCustomSymbol();
     }
   else if(window == RENKO_CURRENT_WINDOW)
     {
      SetCustomSymbol();
     }
   else if(window == RENKO_MINI_CHART)
     {
      MiniChartCustomSymbol();
     }   
   MarketBookAdd(renko_symbol);
  }

//Release OnBookEvent
void RenkoCharts::Stop()
  {
//---
   Comment("");
   MarketBookRelease(renko_symbol);
   ObjectDelete(0,custom_symbol);
  }
  
//Refresh rates on OnTick and OnBookEvent events
void RenkoCharts::Refresh()
  {
   static datetime last_update;
   static int last_size;
   //Update custom symbol
   int size = UpdateRates();
   if(last_size != size)
      if(TimeCurrent() - last_update > 60)
         ReplaceCustomSymbol();
      else
         UpdateCustomSymbol();
   //Update custom tick
   UpdateCustomTick();
   last_update = TimeCurrent();
   last_size = size;
  }

//Open selectable mini-chart
void RenkoCharts::MiniChartCustomSymbol()
  {
   ObjectCreate(0,custom_symbol,OBJ_CHART,0,0,0);
   ObjectSetString(0,custom_symbol,OBJPROP_SYMBOL,custom_symbol); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_XDISTANCE,0); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_YDISTANCE,200); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_XSIZE,300); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_YSIZE,200); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,custom_symbol,OBJPROP_PERIOD,PERIOD_M1); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_CHART_SCALE,3);
   ObjectSetInteger(0,custom_symbol,OBJPROP_DATE_SCALE,false); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_BACK,false); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_SELECTABLE,true); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_SELECTED,false); 
   ObjectSetInteger(0,custom_symbol,OBJPROP_HIDDEN,true);  
  }

//+------------------------------------------------------------------+
//| custom functions                                                 |
//+------------------------------------------------------------------+
string StringAt(string text, string separator, int position = 0)
  {
   string result[];
   ushort s = StringGetCharacter(separator, 0);
   int n = StringSplit(text, s, result);
   if(position < n)
      return result[position];
   else
      return "";
  }