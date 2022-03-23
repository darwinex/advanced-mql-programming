//+--------------------------------------------------------------------------------+
//| DWEX Portfolio Risk Man Multi Position.mqh                                         |
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
      double MultiPositionVaR; 
      
      void   CPortfolioRiskMan(ENUM_TIMEFRAMES VaRTF, int SDPeriods, int CorrPeriods); //CONSTRUCTOR
      bool   CalculateVaR(string &Assets[], double &AssetPosSizes[]);

      
   private:
      ENUM_TIMEFRAMES ValueAtRiskTimeframe;
      int   StandardDeviationPeriods;
      int   CorrelationPeriods;
      
      bool  GetAssetStdDevReturns(string VolSymbolName, double &StandardDevOfReturns);
      bool  GetAssetCorrelation(string CorrSymbolName1, string CorrSymbolName2, double &PearsonR);
};

//CONSTRUCTOR
void CPortfolioRiskMan::CPortfolioRiskMan(ENUM_TIMEFRAMES VaRTF, int SDPeriods, int CorrPeriods)  
{
   MessageBox("Warning: This risk management module is intended for illustrative purposes only, and is only suitable for assets managed by your broker in your account currency. Generally, the vast majority of brokers use the 'account currency' for all Forex pairs, so accurate results will be obtained for this asset type.\n\nHowever, the calculation currencies used for Stocks, Stock Indices, and Commodity CFDs will differ broker to broker. Therefore it is your responsibility to undertake the relevant currency conversions applicable to your broker, in order to obtain accurate results.", "WARNING", MB_ICONINFORMATION);  
   
   ValueAtRiskTimeframe     = VaRTF;
   StandardDeviationPeriods = SDPeriods;
   CorrelationPeriods       = CorrPeriods;
}

bool CPortfolioRiskMan::CalculateVaR(string &Assets[], double &AssetPosSizes[]) //N.B. ProposedPosSize should be +ve for a LONG pos and -ve for a SHORT pos                 
{  
   Print("Running " + __FUNCTION__ + "()");
   
   //#########################################
   //CALCULATE STD DEV OF RETURNS FOR POSITION - NOTE THAT WHILE USED AS PART OF A SCRIPT FOR ILLUSTRATIVE PURPOSES, IT IS ADEQUATE TO CALCULATE THE STD DEV OF RETURNS AS IT IS HERE 'ON-DEMAND'. HOWEVER, IF USING AS PART OF A PRODUCTION EA, THEN IT MIGHT BE DESIRABLE TO CALCULATE ALL VALUES DAILY AND STORE FOR USE THROUGHOUT THE DAY (FOR PERFORMANCE REASONS). 
   //#########################################
   
   double stdDevReturns[];                       
   ArrayResize(stdDevReturns, ArraySize(Assets));
   
   for(int assetLoop = 0; assetLoop < ArraySize(Assets); assetLoop++)
   {
      if(!GetAssetStdDevReturns(Assets[assetLoop], stdDevReturns[assetLoop])) 
      {
         Alert("Error calculating Std Dev of Returns for " + Assets[assetLoop] + " in: " + __FUNCTION__ + "()");
         return false;
      }
   }
   
   //########################################
   //CALCULATE CORREL COEFF BETWEEN POSITIONS - NOTE THAT WHILE USED AS PART OF A SCRIPT FOR ILLUSTRATIVE PURPOSES, IT IS ADEQUATE TO CALCULATE THE CORREL COEFF AS IT IS HERE 'ON-DEMAND'. HOWEVER, IF USING AS PART OF A PRODUCTION EA, THEN IT MIGHT BE DESIRABLE TO CALCULATE THE VALUES BETWEEN ALL SYMBOLS THAT WILL BE TRADED, ON A DAILY BASIS AND STORE FOR USE THROUGHOUT THE DAY (FOR PERFORMANCE REASONS). 
   //########################################

   double correlCoeff[][30];
   ArrayResize(correlCoeff, ArraySize(Assets));
   
   for(int assetALoop = 0; assetALoop < ArraySize(Assets); assetALoop++)
   {
      for(int assetBLoop = 0; assetBLoop < ArraySize(Assets); assetBLoop++)
      {
         if(!GetAssetCorrelation(Assets[assetALoop], Assets[assetBLoop], correlCoeff[assetALoop][assetBLoop]))
         {
            Alert("Error calculating Correl Coeff between " + Assets[assetALoop] + " and " + Assets[assetBLoop] + " in: " + __FUNCTION__ + "()");
            return false;
         }
         
         //DIAGNOSTICS - REMOVE IN PROD
         Print("Correl Coeff between " + Assets[assetALoop] + " and " + Assets[assetBLoop] + ": " + DoubleToString(correlCoeff[assetALoop][assetBLoop], 4));
      }
   }

   //###########################
   //GET NOMINAL MONETARY VALUES - FOR INDIVIDUAL PROPOSED POSITIONS. NOTE 1: THESE VALUES WILL BE -VE IF THE POSITION IS SHORT, AND +VE IF LONG. IT IS NECESSARY TO RETAIN THIS SIGN FOR THE PORTFOLIO STD DEV CALCULATION, SO THAT THE CORREL COEFF CAN BE REVERESED IF HOLDING POSITIONS IN OPPOSIT DIRECTIONS. NOTE 2: THIS ASSUMES ALL ASSETS CALCULATED USING ACCOUNT CURRENCY. FOR OTHERS E.G. SPX500 WOULD NEED TO PERFORM CURRENCY CONVERSION.
   //###########################
   
   double nominalValues[];
   ArrayResize(nominalValues, ArraySize(Assets));
   
   double portfolioNominalValue = 0.0;
   
   for(int assetLoop = 0; assetLoop < ArraySize(Assets); assetLoop++)
   {
      //ASSET MONETARY VALUE (-VE IF SHORT, +VE IF LONG)
      double nominalValuePerUnitPerLot = SymbolInfoDouble(Assets[assetLoop], SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(Assets[assetLoop], SYMBOL_TRADE_TICK_SIZE);
      nominalValues[assetLoop] = AssetPosSizes[assetLoop] * nominalValuePerUnitPerLot * iClose(Assets[assetLoop], PERIOD_M1, 0);  //RATIONALE: This calculates how much would be lost on a position that moved from it's current price to a 0 price. This is equivelent to the nominal amount invested if we were trading with 1:1 leverage, i.e. the totasl amount you would lose of the asset's price went to 0
      
      //CALC 'PORTFOLIO' MONETARY VALUE
      portfolioNominalValue += MathAbs(nominalValues[assetLoop]);
   }
   
   //##########################
   //CALCULATE POSITION WEIGHTS (Sum TO 1.0)
   //##########################
   
   double posWeight[];
   ArrayResize(posWeight, ArraySize(Assets));
   
   for(int assetLoop = 0; assetLoop < ArraySize(Assets); assetLoop++)
   {
      posWeight[assetLoop] = nominalValues[assetLoop] / portfolioNominalValue; //WEIGHTS WILL BE -VE FOR SHORT POSITIONS (THIS ENSURES CORREL COEFF CALCS WORK CORRECTLY) BUT ABS VALUE OF ALL WEIGHTS STILL SUM TO 1.0
   }
 
   //###########################
   //CALCULATE PORTFOLIO STD DEV 
   //###########################

   double portSDCalcPart1 = 0.0;
   double portSDCalcPart2 = 0.0;
   
   //LOOP THROUGH ALL POSITIONS AND USE CORRELATION VALUES WITH OTHER POSITIONS, AND VOLATILITY VALUES TO CALCULATE THE OVERALL PORTFOLIO VaR 
   for(int assetALoop=0; assetALoop<ArraySize(Assets); assetALoop++)
   {
      //N.B. MUST CALCULATE THE WEIGHTING BASED ON THE NOMINAL MONETARY INVESTMENT AMT (NOT THE LOT SIZE BECAUSE LOTS AE NOT CONSISTENT ACROSS ASSETS)
      portSDCalcPart1 += MathPow(posWeight[assetALoop], 2) * MathPow(stdDevReturns[assetALoop], 2);  // += MathPow(pos_weighting, 2) * MathPow(stddev, 2)
      
      for(int assetBLoop=0; assetBLoop<ArraySize(Assets); assetBLoop++)
      {
         //Only compare if not already compared the other way around (don't double count), and also don't compare a position with itself
         if(assetBLoop > assetALoop) //It's important that this uses the same for loop structure as when setting the correlation values above, so that the correct values get used.
         {  
            portSDCalcPart2 +=     2 * posWeight[assetALoop] *                // Weight of position A (keep sign)
                                       posWeight[assetBLoop] *                // Weight of position B (keep sign)
                                       stdDevReturns[assetALoop] *            // Std Dev of Returns for position A's asset
                                       stdDevReturns[assetBLoop] *            // Std Dev of Returns for position B's asset
                                       correlCoeff[assetALoop][assetBLoop];   // Correlation between assets A and B (This value is for both positions being in the same direction - see above for description of how this works when positions in different directions)
         }
      }
   }
   
   double portfolioStdDev = MathSqrt(portSDCalcPart1 + portSDCalcPart2);


   //######################################### 
   //CALCULATE THE VaR VALUE FOR TWO POSITIONS - VaR Calculated on basis of "max expected loss in requested period of time" at a "95% confidence level" (This value will be exceeded 1 period out of 20). The value of 1.65 is the 95% Z-Score for a one-tailed test
   //#########################################
  
   MultiPositionVaR = 1.65 * portfolioStdDev * portfolioNominalValue; //portfolioNominalValue is always +ve because of MathAbs(AssetPosSize) above
   
   return true;
}

bool CPortfolioRiskMan::GetAssetStdDevReturns(string VolSymbolName, double &StandardDevOfReturns)
{
   Print("Running " + __FUNCTION__ + "()");

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

bool CPortfolioRiskMan::GetAssetCorrelation(string CorrSymbolName1, string CorrSymbolName2, double &PearsonR)
{
   Print("Running " + __FUNCTION__ + "()");
   
   //AVOID CURRENT BAR BECAUSE IT IS NOT YET COMPLETE
   int StartBar = 1; 
   
   //CALCULATE THE DIFF BETWEEN SUCCESSIVE VALUES IN EACH ARRAY TO CREATE A NEW ARRAY (WHEN CALCULATING CORRELATION WE MUST USE THE DIFFERENCES BETWEEN SUCCESSIVE PRICES, NOT THE PRICES THEMSELVES)
         
   double assetAPriceDiffValues[];
   double assetBPriceDiffValues[];
   
   ArrayResize(assetAPriceDiffValues, CorrelationPeriods);
   ArrayResize(assetBPriceDiffValues, CorrelationPeriods);
   
   //THE BAR BEING PROCESSED FOR EACH ASSET IS STORED INDEPENDENTLY, IN CASE ONE ASSET HAS A BAR(S) FOR A CERTAIN TIME AND THE OTHER DOESN'T - "MUST" ONLY EVER COMPARE BARS THAT HAVE AN EQUIVELENT OPENING TIME, OTHERWISE THE CORRELATION DATA WILL BE "COMPLETELY MEANINGLESS"
   int currBarAssetA = StartBar;
   int currBarAssetB = StartBar;
   int numBarsProcessed = 0;

   //CHECK IF THE OPEN TIME FOR THE CURRENT BARS OF EACH ASSET ARE IDENTICAL - "MUST" ONLY EVER COMPARE BARS THAT HAVE AN EQUIVELENT OPENING TIME, OTHERWISE THE DIFFS WILL NOT SYNC AND THE RESULTING CORRELATION VALUES WILL BE "COMPLETELY MEANINGLESS"
   while(numBarsProcessed < CorrelationPeriods)
   {
      //CHECK THAT EACH ASSET HAS DATA AVAILABLE FOR THE CALCULATION
      if(iTime(CorrSymbolName1, ValueAtRiskTimeframe, currBarAssetA) == 0  ||  iTime(CorrSymbolName2, ValueAtRiskTimeframe, currBarAssetB) == 0)
      {
         PearsonR = 0.0;  //IMPOSSIBLE TO ASCERTAIN CORRELATION COEFF SO SET TO 0.0 AND THEN RETURN FALSE SO THAT ERROR CAN BE PICKED UP BY CALLING FUNCTION
         return false;
      }
      
      //FOR THE CORRELATION CALCULATION IT IS "ABSOLUTELY ESSENTIAL" THAT THE BARS ARE SYNCED. OTHERWISE THE RESULTS WILL BE COMPLETELY RANDOM AND MEANINGLESS
      if(iTime(CorrSymbolName1, ValueAtRiskTimeframe, currBarAssetA) < iTime(CorrSymbolName2, ValueAtRiskTimeframe, currBarAssetB))
         currBarAssetB++; //INCREMENT SYMBOL B'S BAR IN AN ATTEMPT TO SYNC WITH SYMBOL A
      else if(iTime(CorrSymbolName1, ValueAtRiskTimeframe, currBarAssetA) > iTime(CorrSymbolName2, ValueAtRiskTimeframe, currBarAssetB))
         currBarAssetA++; //INCREMENT SYMBOL A'S BAR IN AN ATTEMPT TO SYNC WITH SYMBOL B
      else
      {
         //BARS MUST BE SYNCED. OK TO PROCEED AND CALCULATE BAR PRICE CHANGES
         //THE METHODIOLOGY USED IS TO MEASURE THE MOVE IN PRICE FROM THE OPEN TO THE CLOSE OF EACH BAR (SIMPLER IN TERMS OF SYNCING BARS, BUT JUST AS EFFECTIVE, AS DOING CLOSE TO CLOSE OF SUCCESSIVE BARS)
         assetAPriceDiffValues[numBarsProcessed] = iClose(CorrSymbolName1, ValueAtRiskTimeframe, currBarAssetA) - iOpen(CorrSymbolName1, ValueAtRiskTimeframe, currBarAssetA);
         assetBPriceDiffValues[numBarsProcessed] = iClose(CorrSymbolName2, ValueAtRiskTimeframe, currBarAssetB) - iOpen(CorrSymbolName2, ValueAtRiskTimeframe, currBarAssetB);

         numBarsProcessed++;
         
         currBarAssetA++;
         currBarAssetB++;
      }
   }
         
   MathCorrelationPearson(assetAPriceDiffValues, assetBPriceDiffValues, PearsonR);

   return true;
}
