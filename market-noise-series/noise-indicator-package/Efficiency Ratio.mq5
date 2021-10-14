
//+--------------------------------------------------------------------------------+
//|                                                           Efficiency Ratio.mq5 |
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
#property version   "1.03"
#property strict

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  LightSeaGreen

#property indicator_level1 0.25           //Set arbitary value - overridden by IndicatorSetDouble() in OnInit()
#property indicator_levelwidth 1          //Set thickness of horizontal levels
#property indicator_levelstyle STYLE_DOT  //Set style of horizontal levels
   
//Input parameters
input int      InpEfficiencyPeriods    = 20;          //Indicator Periods
input double   InpNoiseThresholdLevel  = 0.25;       //Visual Noise Threshold Level

double EfficiencyBuffer[];    //Used for the indicator plot 
double SumOfChangesBuffer[];  //Used for increase performance of internal calculations 
   
int OnInit()
{
   SetIndexBuffer(0, EfficiencyBuffer, INDICATOR_DATA);            
   SetIndexBuffer(1, SumOfChangesBuffer, INDICATOR_CALCULATIONS); 
   
   IndicatorSetInteger(INDICATOR_DIGITS, 5);

   IndicatorSetString(INDICATOR_SHORTNAME, "Efficiency Ratio (" + IntegerToString(InpEfficiencyPeriods) + ")");
   
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpEfficiencyPeriods);
   
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, InpNoiseThresholdLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrYellow);
   IndicatorSetString(INDICATOR_LEVELTEXT, 0, "HIGH VAL = HIGH EFF (LOW NOISE)");    

   return(INIT_SUCCEEDED);
}
  
int OnCalculate(const int currCountOfPriceBars,  
                const int prevCountOfPriceBars,  
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(currCountOfPriceBars <= InpEfficiencyPeriods)
      return(0);    
   
   int currentPosition = prevCountOfPriceBars - 1; 
   
   if(currentPosition < InpEfficiencyPeriods)
      currentPosition = InpEfficiencyPeriods;
   
   for(int i = currentPosition; i < currCountOfPriceBars && !IsStopped(); i++)
   {
      //Performance improver
      if(currCountOfPriceBars != prevCountOfPriceBars)
      {
         SumOfChangesBuffer[i] = 0;
         for(int iLoop = i - 1; iLoop > i - InpEfficiencyPeriods; iLoop--) 
            SumOfChangesBuffer[i] += MathAbs(close[iLoop] - close[iLoop - 1]);
      }

      //The efficiency ratio is defined as the overall net price change over the period of time in question,
      //divided by the sum of the individual price changes for each bar in that same period of time.
      double overallNetChange = MathAbs(close[i] - close[i - InpEfficiencyPeriods]);

      //Add on the last bar (needs to happen every tick)
      double sumOfAllChanges = SumOfChangesBuffer[i] + MathAbs(close[i] - close[i - 1]);
      
      //if() needed to resolve problem in Strategy Tester if not checking for sumOfAllChanges==0
      if(sumOfAllChanges != 0)
         EfficiencyBuffer[i] = overallNetChange / sumOfAllChanges;
      else
         EfficiencyBuffer[i] = 0.0;
   }

   return(currCountOfPriceBars);
}
