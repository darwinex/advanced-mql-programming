//+--------------------------------------------------------------------------------+
//| DWEX Incremental Value at Risk.mq4                                             |
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

#property copyright           "Copyright 2022, Darwinex"
#property link                "https://www.darwinex.com"
#property description         "Incremental Value at Risk (VaR) Script Example Code"
#property script_show_inputs
#property strict

//CUSTOM INCLUDE FILE - ENSURE THE FOLLOWING INCLUDE FILE IS LOCATED IN ..\[DATA_FOLDER]\MQL5\Include\Darwinex\DWEX Portfolio Risk Man Multi Position.mqh]
#include <Darwinex\DWEX Portfolio Risk Man Multi Position.mqh>

//INPUTS
input ENUM_TIMEFRAMES InpVaRTimeframe    = PERIOD_D1;    //Value at Risk Timeframe
input int             InpStdDevPeriods   = 21;           //Std Deviation Periods
input int             InpCorrelPeriods   = 42;           //Pearson Correlation Coeff Periods
input string          InpProposedSymbol  = "NZDJPY";     //Proposed Position
input double          InpProposedPosSize = 0.12;         //Proposed Position Size (+ve LONG / -ve SHORT)

void OnStart()
{
   CPortfolioRiskMan PortfolioRisk(InpVaRTimeframe, InpStdDevPeriods, InpCorrelPeriods);
   
   string CurrPortAssets[]   = {"AUDCAD", "EURUSD", "GBPJPY", "USDCAD"};
   double CurrPortLotSizes[] = { 0.1,      -0.1,     0.15,     0.2    };      //+ve - LONG,  -ve - SHORT
   
   //CALCULATE THE INITIAL VaR BEFORE PROPOSED POSITION
   PortfolioRisk.CalculateVaR(CurrPortAssets, CurrPortLotSizes);  
   double currValueAtRisk = PortfolioRisk.MultiPositionVaR;
   
   //CREATE PROPOSED POSITION ARRAY AND ADD PROPOSED POSITION 
   string ProposedPortAssets[];
   double ProposedPorLotSizes[];
   ArrayResize(ProposedPortAssets, ArraySize(CurrPortAssets) + 1);
   ArrayResize(ProposedPorLotSizes, ArraySize(CurrPortLotSizes) + 1);
   
   ArrayCopy(ProposedPortAssets, CurrPortAssets);
   ArrayCopy(ProposedPorLotSizes, CurrPortLotSizes);
   
   ProposedPortAssets[ArraySize(ProposedPortAssets)-1]   = InpProposedSymbol;
   ProposedPorLotSizes[ArraySize(ProposedPorLotSizes)-1] = InpProposedPosSize;
   
   //POSITION DIAGNOSTIOCS
   string posDiagnostics = "";
   for(int i=0; i<ArraySize(ProposedPortAssets); i++)
   {
      string posType = (i==ArraySize(ProposedPortAssets)-1)?"PROPOSED":"EXISTING";
      posDiagnostics += "Pos " + IntegerToString(i) + " " + ProposedPortAssets[i] + " " + DoubleToString(ProposedPorLotSizes[i], 2) + "  (" + posType + ")\n";
   }   
   
   //CALCULATE THE PROPOSED VaR IF NEW POSITION WERE ALLOWED TO OPEN
   PortfolioRisk.CalculateVaR(ProposedPortAssets, ProposedPorLotSizes);
   double proposedValueAtRisk = PortfolioRisk.MultiPositionVaR;
   
   //CALCULATE INCREMENTAL VaR
   double incrVaR = proposedValueAtRisk - currValueAtRisk;
   
   MessageBox(posDiagnostics + "\n" +
              "CURRENT VaR: " + DoubleToString(currValueAtRisk, 2) + "\n" +
              "PROPOSED VaR: " + DoubleToString(proposedValueAtRisk, 2) + "\n" +
              "INCREMENTAL VaR: " + DoubleToString(incrVaR, 2)); 
}
