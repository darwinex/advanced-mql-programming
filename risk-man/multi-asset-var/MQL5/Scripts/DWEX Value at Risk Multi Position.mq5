//+--------------------------------------------------------------------------------+
//| DWEX Value at Risk Multi Position.mqh                                          |
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
#property description         "Value at Risk (VaR) Script Example Code - Multi Position"
#property script_show_inputs
#property strict

//CUSTOM INCLUDE FILE - ENSURE THE FOLLOWING INCLUDE FILE IS LOCATED IN ..\[DATA_FOLDER]\MQL5\Include\Darwinex\DWEX Portfolio Risk Man Multi Position.mqh]
#include <Darwinex\DWEX Portfolio Risk Man Multi Position.mqh>

//INPUTS
input ENUM_TIMEFRAMES VaRTimeframe  = PERIOD_D1;   //Value at Risk Timeframe
input int             StdDevPeriods = 21;          //Std Deviation Periods
input int             CorrelPeriods = 42;          //Pearson Correlation Coeff Periods

void OnStart()
{
   CPortfolioRiskMan PortfolioRisk(VaRTimeframe, StdDevPeriods, CorrelPeriods);
   
   string AssetNames[]    = {"AUDCAD", "EURUSD", "GBPJPY", "USDCAD"};
   double AssetLotSizes[] = { 0.1,      -0.1,     0.15,     0.2    };      //+ve - LONG,  -ve - SHORT
   
   if(PortfolioRisk.CalculateVaR(AssetNames, AssetLotSizes))
      MessageBox("Value at Risk for " + IntegerToString(ArraySize(AssetNames)) + " specified positions: " + DoubleToString(PortfolioRisk.MultiPositionVaR, 2));
}
   
