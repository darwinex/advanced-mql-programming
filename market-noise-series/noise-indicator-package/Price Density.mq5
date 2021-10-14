
//+--------------------------------------------------------------------------------+
//|                                                              Price Density.mq5 |
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
#property version   "1.01"
#property strict

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkOrange
#property indicator_level1 5              
#property indicator_levelwidth 1          
#property indicator_levelstyle STYLE_DOT  
   
//Input parameters
input int    InpPeriods                = 20;      //Indicator Periods
input double InpNoiseThresholdLevel    = 5.0;     //Visual Noise Threshold Level

double PriceDensityBuffer[];      
double SumOfIndHighLowsBuffer[]; 
double HighestHighBuffer[];
double LowestLowBuffer[];
   
int OnInit()
{
   SetIndexBuffer(0, PriceDensityBuffer, INDICATOR_DATA);              
   SetIndexBuffer(1, SumOfIndHighLowsBuffer, INDICATOR_CALCULATIONS);  
   SetIndexBuffer(2, HighestHighBuffer, INDICATOR_CALCULATIONS);       
   SetIndexBuffer(3, LowestLowBuffer, INDICATOR_CALCULATIONS);        
   
   IndicatorSetInteger(INDICATOR_DIGITS, 5);
   IndicatorSetString(INDICATOR_SHORTNAME, "Noise Price Density (" + IntegerToString(InpPeriods) + ")");
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriods);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, InpNoiseThresholdLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrYellow);
   IndicatorSetString(INDICATOR_LEVELTEXT, 0, "HIGH VALUES = HIGH NOISE"); 

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
   if(currCountOfPriceBars <= InpPeriods)
      return(0);    
   
   int currentPosition = prevCountOfPriceBars - 1; 
   
   if(currentPosition < InpPeriods)
      currentPosition = InpPeriods;
   
   for(int i = currentPosition; i < currCountOfPriceBars && !IsStopped(); i++)
   {    
      if(currCountOfPriceBars != prevCountOfPriceBars) 
      {
         SumOfIndHighLowsBuffer[i] = 0;
         HighestHighBuffer[i] = DBL_MIN;
         LowestLowBuffer[i] = DBL_MAX;
         
         for(int iLoop = i - 1; iLoop > i - InpPeriods; iLoop--)      
         {
            SumOfIndHighLowsBuffer[i] += high[iLoop] - low[iLoop]; 
         
            if(high[iLoop] > HighestHighBuffer[i])
               HighestHighBuffer[i] = high[iLoop];
               
            if(low[iLoop] < LowestLowBuffer[i])
               LowestLowBuffer[i] = low[iLoop];
         }
      }
      
      double highestHigh = MathMax(HighestHighBuffer[i], high[i]);
      double lowestLow = MathMin(LowestLowBuffer[i], low[i]);
      
      if(highestHigh - lowestLow != 0) 
         PriceDensityBuffer[i] = (SumOfIndHighLowsBuffer[i] + (high[i] - low[i])) / (highestHigh - lowestLow);
      else                     
         PriceDensityBuffer[i] = 0.0;
   }

   return(currCountOfPriceBars);
}
