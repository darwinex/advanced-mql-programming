
//+--------------------------------------------------------------------------------+
//|                                                                       KAMA.mq5 |
//|                            Copyright 2021, Darwinex & Trade Like A Machine Ltd |
//|                                                       https://www.darwinex.com |
//|                                              https://www.tradelikeamachine.com |
//|                                                                                |
//| Provided to Darwinex customers and Subscribers of the Darwinex Youtube Channel | 
//|                                                                                |
//|       This is an indicator within the 'Noise Indicator Package' as part of the |
//|                                                YouTube Series on Market Noise. |
//|                      Episode 1 can be found here: https://youtu.be/1z09UFOJ-G4 |                                                        
//|                                                                                |
//| DISCLAIMER AND TERMS OF USE OF THIS INDICATOR                                  |
//| THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"    |
//| AND IS NOT GUARANTEED TO BE BUG FREE.                                          |
//| ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE          |
//| IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE |
//| DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE   |
//| FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL     |
//| DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR     |
//| SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER     |
//| CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  |
//| OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  |
//| OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.           |
//+--------------------------------------------------------------------------------+

#property copyright "Copyright 2021, Darwinex & Trade Like A Machine Ltd"
#property link      "https://www.darwinex.com"
#property version   "1.04"
#property strict

#property description "Kaufman Adaptive Moving Average (KAMA)"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   1

#property indicator_label1  "KAMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrAqua
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

input uint                 InpEffPeriod      =  20;            //Efficiency Periods
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   //Applied price
input uint                 InpFastestMAV     =  2;             //Fastest MAV
input uint                 InpSlowestMAV     =  30;            //Slowest MAV

double         BufferKAMA[];
double         BufferMA[];
double         BufferABS[];
double         BufferMAA[];

int            handle_price;
int            eff_periods;
double         sc_constant1;
double         sc_constant2;

#include <MovingAverages.mqh>

int OnInit()
{

   eff_periods = int(InpEffPeriod < 1 ? 1 : InpEffPeriod);
   
   double fastest_mav = 2.0 / (InpFastestMAV + 1.0);
   double slowest_mav = 2.0 / (InpSlowestMAV + 1.0);
   
   sc_constant1 = fastest_mav - slowest_mav;
   sc_constant2 = slowest_mav;
    
   SetIndexBuffer(0, BufferKAMA, INDICATOR_DATA);
   SetIndexBuffer(1, BufferMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, BufferABS, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, BufferMAA, INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME, "TLAM KAMA (" + IntegerToString(eff_periods) + ") Constants: " + DoubleToString(sc_constant1, 3) + ", " + DoubleToString(sc_constant2, 3));
   IndicatorSetInteger(INDICATOR_DIGITS, Digits());

   ArraySetAsSeries(BufferKAMA, true);
   ArraySetAsSeries(BufferMA, true);
   ArraySetAsSeries(BufferABS, true);
   ArraySetAsSeries(BufferMAA, true);

   ResetLastError();
   
   //Create handle for current price
   handle_price = iMA(NULL, PERIOD_CURRENT, 1, 0, MODE_SMA, InpAppliedPrice);
   
   if(handle_price == INVALID_HANDLE)
   {
      Print("Error creating the handle for price (", GetLastError(), ")");
      return INIT_FAILED;
   }
   
   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < eff_periods) return 0;

   int limit = rates_total - prev_calculated;
   
   if(limit > 1)
   {
      limit = rates_total - eff_periods - 2;
      ArrayInitialize(BufferKAMA, 0);
      ArrayInitialize(BufferMA, 0);
      ArrayInitialize(BufferABS, 0);
      ArrayInitialize(BufferMAA, 0);
   }

   int copied = 0;
   int count = (limit == 0 ? 1 : rates_total);
   
   copied = CopyBuffer(handle_price, 0, 0, count, BufferMA);
   
   if(copied != count) 
      return 0;
   
   for(int i=limit; i>=0 && !IsStopped(); i--)
      BufferABS[i] = fabs(BufferMA[i] - BufferMA[i+1]);
      
   SimpleMAOnBuffer(rates_total, prev_calculated, 0, eff_periods, BufferABS, BufferMAA);

   for(int i=limit; i>=0 && !IsStopped(); i--)
   {
      double kER = BufferMAA[i] * eff_periods;
      
      if(kER != 0)
         kER = MathAbs(BufferMA[i] - BufferMA[i + eff_periods - 1]) / kER;
         
      double sc = MathPow((kER * sc_constant1) + sc_constant2, 2);

      BufferKAMA[i] = BufferKAMA[i+1] + (sc * (BufferMA[i] - BufferKAMA[i+1]));
   }

   return(rates_total);
}