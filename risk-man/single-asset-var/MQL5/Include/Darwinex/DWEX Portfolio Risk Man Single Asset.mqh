//+--------------------------------------------------------------------------------+
//| DWEX Portfolio Risk Man.mqh                                                    |
//|                                                                                |
//| THIS CODE IS PROVIDED FOR ILLUSTRATIVE PURPOSES ONLY. ALWAYS THOUROUGHLY TEST  |
//| ANY CODE BEFORE THEN ADAPTING TO YOUR OWN PERSONAL RISK OBJECTIVES AND RISK    |
//| APPETITE.                                                                      |
//|                                                                                |
//| DISCLAIMER AND TERMS OF USE OF THIS CODE                                       |
//| THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"    |
//| AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE      |
//| IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE |
//| DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE   |
//| FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL     |
//| DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR     |
//| SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER     |
//| CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  |
//| OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  |
//| OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.           |
//|                                                                                |
//+--------------------------------------------------------------------------------+

//+--------------------------------------------------------------------------------+
//| THIS CODE EXAMPLE IS SUPPLIED AS PART OF THE FOLLOWING YOUTUBE SERIES TITLED   | 
//| 'INSTITUTIONAL-GRADE RISK MANAGEMENT TECHNIQUES':                              |
//|                                                                                |
//| https://www.youtube.com/playlist?list=PLv-cA-4O3y979Ltr9wQ2lRJu1INve3RCM       |
//+--------------------------------------------------------------------------------+

#property copyright     "Copyright 2022, Darwinex"
#property link          "https://www.darwinex.com"
#property description   "Portfolio Risk Management Module"
#property strict

#include <Math\Stat\Math.mqh>

class CPortfolioRiskMan
{
   public:   
      double SinglePositionVaR; 
      
      void   CPortfolioRiskMan(ENUM_TIMEFRAMES VaRTimeframe, int StdDevPeriods); //CONSTRUCTOR
      bool   CalculateVaR(string Asset, double AssetPosSize);

      
   private:
      ENUM_TIMEFRAMES ValueAtRiskTimeframe;
      int   StandardDeviationPeriods;
      
      bool  GetAssetStdDevReturns(string VolSymbolName, double &StandardDevOfReturns);
};

//CONSTRUCTOR
void CPortfolioRiskMan::CPortfolioRiskMan(ENUM_TIMEFRAMES VaRTF, int SDPeriods)  
{
   MessageBox("Warning: This risk management module is intended for illustrative purposes only, and is only suitable for assets managed by your broker in your account currency. Generally, the vast majority of brokers use the account currency for all Forex pairs, so accurate results will be obtained for this asset type.\n\nHowever, the calculation currencies for used for Stocks, Stock Indices, and Commodity CFDs will differ broker to broker. Therefore it is your responsibility to undertake the relevant currency conversions applicable to your broker, in order to obtain accurate results.", "WARNING", MB_ICONINFORMATION);  
   
   ValueAtRiskTimeframe     = VaRTF;
   StandardDeviationPeriods = SDPeriods;
}

bool CPortfolioRiskMan::CalculateVaR(string Asset, double AssetPosSize) //N.B. ProposedPosSize should be +ve for a LONG pos and -ve for a SHORT pos                 
{  
   //CALCULATE STD DEV OF RETURNS FOR POSITION
   double stdDevReturns;
   if(!GetAssetStdDevReturns(Asset, stdDevReturns)) //2nd param passed by ref
   {
      Alert("Error calculating Std Dev of Returns for " + Asset + " in: " + __FUNCTION__ + "()");
      return false;
   }
   
   //GET NOMINAL VALUE FOR PROPOSED POSITION
   //TODO: THIS ASSUMES ALL ASSETS CALCULATED USING ACCOUNT CURRENCY. FOR OTHERS E.G. SPX500 NEED TO DO CURRENCY CONVERSION SAME AS IN THE MAIN EA WHEN CALCULATING THE MAX RISK OF THE STOP LOSS
   double nominalValuePerUnitPerLot = SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_SIZE);
   double nominalValue              = MathAbs(AssetPosSize) * nominalValuePerUnitPerLot * iClose(Asset, PERIOD_M1, 0);  //RATIONALE: This calculates how much would be lost on a position that moved from it's current price to a 0 price. This is equivelent to the nominal amount invested if we were trading with 1:1 leverage, i.e. the totasl amount you would lose of the asset's price went to 0

   //CALCULATE THE VaR VALUES FOR THIS IND PROPOSED POSITION
   //VaR Calculated on basis of "max expected loss in 1-day" at a "95% confidence level" (This value will be exceeded 1 day out of 20). The value of 1.65 is the 95% Z-Score for a one-tailed test
   SinglePositionVaR = 1.65 * stdDevReturns * nominalValue; //nominalValue is always +ve because of MathAbs(AssetPosSize) above

   return true;
}

bool CPortfolioRiskMan::GetAssetStdDevReturns(string VolSymbolName, double &StandardDevOfReturns)
{
   double returns[];
   
   ArrayResize(returns, StandardDeviationPeriods);
                 
   //STORE 'CHANGE' IN CLOSE PRICES TO ARRAY
   for(int calcLoop=0; calcLoop < StandardDeviationPeriods; calcLoop++) //START LOOP AT 1 BECAUSE DON'T WANT TO INCLUDE CURRENT BAR (WHICH MIGHT NOT BE COMPLETE) IN CALC.
   {
      //USE calcLoop + 1 BECAUSE DON'T WANT TO INCLUDE CURRENT BAR (WHICH WILL NOT BE COMPLETE) IN CALC.  CALCULATE RETURN AS A RATIO. i.e. 0.01 IS A 1% INCREASE, AND -0.01 IS A 1% DECREASE
      returns[calcLoop] = (iClose(VolSymbolName, ValueAtRiskTimeframe, calcLoop + 1) / iClose(VolSymbolName, ValueAtRiskTimeframe, calcLoop + 2)) - 1.0;
   }
   
   //CALCULATE THE STD DEV OF ALL RETURNS (MathStandardDeviation() IN #include <Math\Stat\Math.mqh>)
   StandardDevOfReturns = MathStandardDeviation(returns);
   
   return true;
}
