//+--------------------------------------------------------------------------------+
//|                                                                       RVOL.mq5 |
//|                                 Copyright, Darwinex & Trade Like A Machine Ltd |
//| Provided to Darwinex customers and Subscribers of the Darwinex Youtube Channel |                                                                 
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

// NOTE: The calculations in this indicator only work for assets that trade 5 days every week. It will not work with 24x7 Crypto for example

#property copyright "Darwinex & Trade Like A Machine Ltd"
#property link      "http://www.darwinex.com"
#property strict

//Indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrGreen, clrOrange, clrRed
#property indicator_style1  0
#property indicator_width1  3

//Level of above average (1.25) and below average (0.8) volume (for time of day) - (ratio of 1.0 indicates current volume is the same as average)
#property indicator_level1 1.25 //Above Average Volume Level
#property indicator_level2 0.8  //Below Average Volume Level

//Input Parmans
input int                 InpAveragingDays  =  5;               //Number of Days for Comparison 
input ENUM_APPLIED_VOLUME InpVolumeType     =  VOLUME_TICK;     //Volume Type

//Indicator Buffers
double ExtRelVolumesBuffer[];
double ExtColorsBuffer[];
int    BarsIn24Hours = 0;
int    AveragingDays;

void OnInit()
{
   //Set Buffers
   SetIndexBuffer(0,ExtRelVolumesBuffer, INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorsBuffer, INDICATOR_COLOR_INDEX);
   
   //Define how many bars required to begin drawing 
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 100);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 100);

   //Set indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   
   //Ensure valid InpAveragingDays
   if(InpAveragingDays >= 1)
      AveragingDays = InpAveragingDays;
   else 
      AveragingDays = 5;
      
   //Set name of indicator
   string short_name = StringFormat("RVOL (Relative Volume) (%d)", AveragingDays);
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   
   //Mean Level
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrWhite);
   IndicatorSetString(INDICATOR_LEVELTEXT, 0, "Above Average Volume");   
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 1, clrWhite);
   IndicatorSetString(INDICATOR_LEVELTEXT, 1, "Below Average Volume");   
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
   //rates_total is the number of bars available for calculations
   if(rates_total < 1)
      return(0);
   
   if(BarsIn24Hours == 0) //Set to 0 by default above
   {
      SetBarsIn24Hours();
      if(BarsIn24Hours == 0) //Bars not yet available in chart for calculation to succeed
         return(0);
   }
   //Set starting point for the processing
   int startBar = prev_calculated - 1;

   //Adjust Start position
   if(startBar < 1)
   {
      ExtRelVolumesBuffer[0] = 0;
      startBar = 1;
   }
     
   //Main cycle
   if(InpVolumeType==VOLUME_TICK)
      CalculateRelVolume(startBar, rates_total, tick_volume);
   else
      CalculateRelVolume(startBar, rates_total, volume);

   //OnCalculate done. Return new prev_calculated.
   return(rates_total);
}

void CalculateRelVolume(const int startBar, const int rates_total, const long& volume[])
{
   ExtRelVolumesBuffer[0] = (double)volume[0];
   ExtColorsBuffer[0] = 0.0;
   
   for(int i = startBar; i < rates_total && !IsStopped(); i++)
   {
      if(i > AveragingDays * BarsIn24Hours)
      {
         double curr_volume = (double)volume[i];
         
         double mean_volume = 0.0;
         
         for(int j = 1; j <= AveragingDays; j++)
            mean_volume += (double)volume[i - (j * BarsIn24Hours)];  
            
         mean_volume /= (double)AveragingDays;
         
         ExtRelVolumesBuffer[i] = curr_volume / mean_volume;   //N.B. Value of 1.0 represents current vol is equal to average volume, 0.0-1.0 is below average, >1.0 is above average
         
         if(ExtRelVolumesBuffer[i] > indicator_level1)         //If current vol higher than average     
            ExtColorsBuffer[i] = 0.0;
         else if (ExtRelVolumesBuffer[i] > indicator_level2)   //If current vol lower than average     
            ExtColorsBuffer[i] = 1.0;
         else 
            ExtColorsBuffer[i] = 2.0;
      }
      else
      {
         ExtRelVolumesBuffer[i] = 0.0;
         ExtColorsBuffer[i] = 0.0;
      }
   }
}

int SetBarsIn24Hours()
{
   datetime prevDateTime = iTime(NULL, PERIOD_CURRENT, 0) - (86400 * 7); //Need to base calculation on 7 days so that weekends don't interfere 
   
   int numBarsIn7Days = iBarShift(NULL, PERIOD_CURRENT, prevDateTime, false);
   
   //Num bars in 7 days actually represents 5 trading days. N.B. This Indicator only works for assets that trade 5 days per week. It will not work with 24x7 Crypto for example
   BarsIn24Hours = numBarsIn7Days / 5; 
      
   return BarsIn24Hours;
}
