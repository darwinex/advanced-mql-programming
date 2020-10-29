   
   //+--------------------------------------------------------------------------------+
   //| custom-perf-metric-CAGRoverMeanDD.mq5                                          |
   //|                                                                                |
   //| DISCLAIMER AND TERMS OF USE OF THIS EXPERT ADVISOR                             |
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
   //+--------------------------------------------------------------------------------+
   
   #property link          "https://www.darwinex.com"
   #property description   "Custom Performance Metric EA Code Example - CAGR/MeanDD - Darwinex Video Series"
   #property strict
   
   #include <StdLibErr.mqh>
   #include <Math\Stat\Stat.mqh>                   //Required for MathStandardDeviation()
   
   enum ENUM_POS_SIZE_METHOD
   {
      MIN_LOT_SIZE,                                //Minimum Lot Size ('Broker min lots' for symbol used)
      FIXED_LOT_SIZE,                              //Fixed Lot Size (Specify the lot size to use)
      RELATIVE_LOT_SIZE                            //Relative Lot Size (Relative to Equity)
   };
   enum ENUM_CUSTOM_PERF_CRITERIUM_METHOD
   {
      NO_CUSTOM_METRIC,                            //No Custom Metric
      STANDARD_PROFIT_FACTOR,                      //Standard Profit Factor
      MODIFIED_PROFIT_FACTOR,                      //Modified Profit Factor
      CAGR_OVER_MEAN_DD                            //CAGR/MeanDD
   };
   enum ENUM_DIAGNOSTIC_LOGGING_LEVEL
   {
      DIAG_LOGGING_NONE,                           //NONE
      DIAG_LOGGING_LOW,                            //LOW - Major Diagnostics Only
      DIAG_LOGGING_MEDIUM,                         //MEDIUM - Medium level logging
      DIAG_LOGGING_HIGH                            //HIGH - All Diagnostics (Warning - Use with caution)
   };
   
   input ENUM_POS_SIZE_METHOD                PositionSizingMethod   = RELATIVE_LOT_SIZE;        //Position Sizing Method
   input ENUM_CUSTOM_PERF_CRITERIUM_METHOD   CustomPerfCriterium    = CAGR_OVER_MEAN_DD;        //Custom Performance Criterium
   input ENUM_DIAGNOSTIC_LOGGING_LEVEL       DiagnosticLoggingLevel = DIAG_LOGGING_LOW;         //Diagnostic Logging Level
   
   //Globals
   int      PreviousHourlyTasksRun  = -1;          //Set to -1 so that hourly tasks run immediately
   double   EquityHistoryArray[];                  //Used to store equity at intermittent time intervals when using the Strategy Tester in order to calculate CAGR/MeanDD perf metric
   datetime BackTestFirstDate;                     //Used in the CAGR/MeanDD Calc
   datetime BackTestFinalDate;                     //Used in the CAGR/MeanDD Calc
   
   int OnInit()
   {
      //## YOUR OWN CODE HERE ##
     
      //THE FOLLOWING CODE SEGMENT IS SUPPLIED AS AN ILLUSTRATION OF HOW AN INITIAL SANITY CHECK CAN BE PERFORMED TO ENSURE THAT YOUR 
      //CHOSEN POSITION SIZING METHOD IS PROPERLY ALIGNED TO THE CHOSEN PERFORMANCE METRIC
      if(MQLInfoInteger(MQL_TESTER))
      {
         if(PositionSizingMethod == RELATIVE_LOT_SIZE && CustomPerfCriterium == STANDARD_PROFIT_FACTOR)
         {
            Print("You have attempted to test the EA in the Strategy Tester using a RELATIVE_LOT_SIZE which is not compatible with the CustomPerfCriterium of STANDARD_PROFIT_FACTOR (Trades when equity is high have a disproportionate effect on the Profit Factor calculation than trades taken when equity is low)");
            return(INIT_PARAMETERS_INCORRECT);
         }
         else if((PositionSizingMethod == MIN_LOT_SIZE || PositionSizingMethod == FIXED_LOT_SIZE) && CustomPerfCriterium == CAGR_OVER_MEAN_DD)
         {
            Print("You have attempted to test the EA in the Strategy Tester using " + EnumToString((ENUM_POS_SIZE_METHOD)PositionSizingMethod) + " which is not compatible with the CustomPerfCriterium of CAGR_OVER_MEAN_DD (The CAGR/MeanDD calculation requires position sizing relative to equity, in order to produce proportional drawdowns throughout the entire backtest)");
            return(INIT_PARAMETERS_INCORRECT);                                        
         }
      }
      
      //SET UP EQUITY HISTORY ARRAY AND FIRST DATE - USED TO CALCULATE CAGR/MeanDD
      if(MQLInfoInteger(MQL_TESTER))
      {
         BackTestFirstDate = TimeCurrent();
         ArrayResize(EquityHistoryArray, 1);    
         EquityHistoryArray[0] = AccountInfoDouble(ACCOUNT_EQUITY); 
      } 
      
      return(INIT_SUCCEEDED);     
   }

   void OnTick()
   {
      //## YOUR OWN CODE HERE ##
      
      if(MQLInfoInteger(MQL_TESTER)) //Only run in live account
      {
         MqlDateTime currentDateTime;
         TimeCurrent(currentDateTime);
         
         if(currentDateTime.hour != PreviousHourlyTasksRun)
         {
            int currentArraySize = ArraySize(EquityHistoryArray);
            ArrayResize(EquityHistoryArray, currentArraySize + 1);  
            EquityHistoryArray[currentArraySize] = AccountInfoDouble(ACCOUNT_EQUITY);
         }
         
         PreviousHourlyTasksRun = currentDateTime.hour;
      }
   }
   
   double OnTester()  
   {
      double customPerformanceMetric;  
      
      if(CustomPerfCriterium == STANDARD_PROFIT_FACTOR)
      {
         customPerformanceMetric = TesterStatistics(STAT_PROFIT_FACTOR);
      }
      else if(CustomPerfCriterium == MODIFIED_PROFIT_FACTOR)
      {
         int numTrades = ModifiedProfitFactor(customPerformanceMetric);
         
         //IF NUMBER OF TRADES < 250 THEN NO STATISTICAL SIGNIFICANCE, SO DISREGARD RESULTS (PROBABLE THAT GOOD 
         //RESULTS CAUSED BY RANDOM CHANCE / LUCK, THAT WOULD NOT BE REPEATABLE IN FUTURE PERFORMANCE).
         //IF THE TRADING SYSTEM USUALLY GENERATES A NUMBER OF TRADES GREATLY IN EXCESS OF THIS THEN ADVISABLE TO INCREASE THIS THRESHOLD VALUE
         if(numTrades < 250)
            customPerformanceMetric = 0.0;
      } 
      else if(CustomPerfCriterium == CAGR_OVER_MEAN_DD)
      {
         int numTrades = CagrOverMeanDD(customPerformanceMetric);
         
         //IF NUMBER OF TRADES < 250 THEN NO STATISTICAL SIGNIFICANCE, SO DISREGARD RESULTS (PROBABLE THAT GOOD 
         //RESULTS CAUSED BY RANDOM CHANCE / LUCK, THAT WOULD NOT BE REPEATABLE IN FUTURE PERFORMANCE).
         //IF THE TRADING SYSTEM USUALLY GENERATES A NUMBER OF TRADES GREATLY IN EXCESS OF THIS THEN ADVISABLE TO INCREASE THIS THRESHOLD VALUE
         if(numTrades < 250)
            customPerformanceMetric = 0.0;
      }
      else if(CustomPerfCriterium == NO_CUSTOM_METRIC)
      {
         customPerformanceMetric = 0.0;
      }
      else
      {
         Print("Error: Custom Performance Criterium requested (", EnumToString(CustomPerfCriterium), ") not implemented in OnTester()");
         customPerformanceMetric = 0.0;
      }
      
      Print("Custom Perfromance Metric = ", DoubleToString(customPerformanceMetric, 3));
      
      return customPerformanceMetric;
   }
   
   int CagrOverMeanDD(double& CAGRoverAvgDD)
   {
      HistorySelect(0, TimeCurrent());   
      int numTrades = 0;

      //##########################
      //ASCERTAIN NUMBER OF TRADES (USED TO ELIMINATE PARAMETER VALUES WITH STATISTICAL SIGNIFCANCE ISSUES)
      //##########################
      
      for(int dealID = 0; dealID < HistoryDealsTotal(); dealID++) 
      { 
         ulong dealTicket = HistoryDealGetTicket(dealID); 
         
         if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
            numTrades++;                       
      } 
      
      //###################################
      //CAGR OVER MEAN DRAWDOWN CALCULATION
      //###################################
      
      int numEquityValues = ArraySize(EquityHistoryArray);
      
      double startingEquity   = EquityHistoryArray[0];
      double finalEquity      = EquityHistoryArray[numEquityValues-1];  
      double currentEquity    = EquityHistoryArray[0];   //Gets overwritten as loop below progresses
      double maxEquity        = EquityHistoryArray[0];   //Gets overwritten as loop below progresses
      double sumDDValues      = 0.0;
      int    numDDValues      = 0;
      
      //Loop through equity array in time order
      for(int arrayLoop = 1; arrayLoop < numEquityValues; arrayLoop++)
      {
         currentEquity = EquityHistoryArray[arrayLoop];
         
         if(currentEquity > maxEquity)
            maxEquity = currentEquity;
         
         sumDDValues += ((maxEquity - currentEquity) / maxEquity) * 100.0;
         numDDValues++;
      }
      
      finalEquity = currentEquity;
      
      //On rare occasions, MetaTrader allows the final equity to pass below zero and become negative before the test ceases. When this happens it causes major issues with the CAGR calculation. So we set to zero manually when this is the case.
      if(finalEquity < 0.0)
         finalEquity = 0.0;
      
      BackTestFinalDate = TimeCurrent();
   
      double BackTestDuration = double(BackTestFinalDate - BackTestFirstDate);        //This is the back test duration in seconds, but cast to double to avoid problems below...
      BackTestDuration = ((((BackTestDuration / 60.0) / 60.0) / 24.0) / 365.0);       //... so convert to years
      
      double cagr = (MathPow((finalEquity / startingEquity), (1 / BackTestDuration)) - 1) * 100.0;
      double meanDD = 0.0;
      
      if(numDDValues != 0)
         meanDD = sumDDValues / numDDValues;
      
      //Remember CAGRoverAvgDD passed in by ref
      CAGRoverAvgDD = 0.0;
      
      if(meanDD != 0.0)
         CAGRoverAvgDD = cagr / meanDD;
      
      return numTrades;
   }  
   
   
   int ModifiedProfitFactor(double& dCustomPerformanceMetric)
   {
      HistorySelect(0, TimeCurrent());   
      int numDeals = HistoryDealsTotal();  
      double sumProfit = 0.0;
      double sumLosses = 0.0;
      int numTrades = 0;
      
      //OUTPUT DIAGNOSTIC DEAL DATA
      int outputFileHandle = INVALID_HANDLE;
      if(DiagnosticLoggingLevel >= 1)
      {
         string outputFileName = "DEAL_DIAGNOSTIC_INFO\\deal_log.csv";
         outputFileHandle = FileOpen(outputFileName, FILE_WRITE|FILE_CSV, "\t");
         FileWrite(outputFileHandle, "LIST OF DEALS IS BACKTEST");   
         FileWrite(outputFileHandle, "TICKET", "DEAL_ORDER", "DEAL_POSITION_ID", "DEAL_SYMBOL", "DEAL_TYPE", 
                                       "DEAL_ENTRY", "DEAL_REASON", "DEAL_TIME", "DEAL_VOLUME", "DEAL_PRICE", 
                                       "DEAL_COMMISSION", "DEAL_SWAP", "DEAL_PROFIT", "DEAL_MAGIC", "DEAL_COMMENT");
      }
      
      //LOOP THROUGH DEALS IN DATETIME ORDER 
      int positionCount = 0;
      double positionNetProfit[];
      double positionVolume[];
      
      for(int dealID = 0; dealID < numDeals; dealID++) 
      { 
         //GET THIS DEAL'S TICKET NUMBER 
         ulong dealTicket = HistoryDealGetTicket(dealID); 
         
         if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            positionCount++;
            ArrayResize(positionNetProfit, positionCount);
            ArrayResize(positionVolume, positionCount);
            
            positionNetProfit[positionCount - 1] = HistoryDealGetDouble(dealTicket, DEAL_PROFIT) +
                                                   HistoryDealGetDouble(dealTicket, DEAL_SWAP) + 
                                                   (2 * HistoryDealGetDouble(dealTicket, DEAL_COMMISSION));  //*2 BASED ON ENTRY AND EXIT COMMISSION MODEL     
            
            positionVolume[positionCount - 1] = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
         }
         
         //######################
         //OUTPUT DEAL PROPERTIES
         //###################### 
         
         if(DiagnosticLoggingLevel >= 1)
         {
            FileWrite(outputFileHandle, IntegerToString(dealTicket), 
                                        IntegerToString(HistoryDealGetInteger(dealTicket, DEAL_ORDER)),
                                        IntegerToString(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID)),
                                        HistoryDealGetString(dealTicket, DEAL_SYMBOL),
                                        EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE)),
                                        EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY)),
                                        EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(dealTicket, DEAL_REASON)),
                                        TimeToString((datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME), TIME_DATE|TIME_SECONDS),
                                        DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_VOLUME), 2),
                                        DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_PRICE), 5),
                                        DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_COMMISSION), 2),
                                        DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_SWAP), 2),
                                        DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_PROFIT), 2),
                                        IntegerToString(HistoryDealGetInteger(dealTicket, DEAL_MAGIC)),
                                        HistoryDealGetString(dealTicket, DEAL_COMMENT)
                                        );
         }
                                        
      } 
      
      //###################################
      //1. CALCULATE STANDARD PROFIT FACTOR
      //###################################
      
      double sumOfProfit = 0;
      double sumOfLosses = 0;
      
      for(int positionNum = 1; positionNum <= positionCount; positionNum++)
      {
         if(positionNetProfit[positionNum - 1] > 0)
            sumOfProfit += positionNetProfit[positionNum - 1];
         else
            sumOfLosses += positionNetProfit[positionNum - 1];
      }
      
      double standardProfitFactor = NULL;
      
      if(sumOfLosses != 0)
         standardProfitFactor = MathAbs(sumOfProfit / sumOfLosses);
      
      //WRITE OUT INTERMEDITE DIAGNOSTIC DATA
      if(DiagnosticLoggingLevel >= 1)
         FileWrite(outputFileHandle, "\nPROFIT FACTOR (STANDARD CALCULATION)", standardProfitFactor);
      
      //###################################
      //2. CALCULATE RELATIVE PROFIT FACTOR (INTERMEDIATE STEP)
      //################################### 
      
      sumOfProfit = 0;
      sumOfLosses = 0;   
      
      for(int positionNum = 1; positionNum <= positionCount; positionNum++)
      {
         positionNetProfit[positionNum - 1] /= positionVolume[positionNum - 1];
         
         if(positionNetProfit[positionNum - 1] > 0)
            sumOfProfit += positionNetProfit[positionNum - 1];
         else
            sumOfLosses += positionNetProfit[positionNum - 1];
      }                          
      
      double relativeProfitFactor = NULL;
      
      if(sumOfLosses != 0)
         relativeProfitFactor = MathAbs(sumOfProfit / sumOfLosses);
         
      //WRITE OUT INTERMEDITE DIAGNOSTIC DATA
      if(DiagnosticLoggingLevel >= 1)
         FileWrite(outputFileHandle, "\nPROFIT FACTOR (MODIFIED CALCULATION)", relativeProfitFactor);
      
      //#########################
      //3. EXCLUDE EXTREME TRADES
      //#########################
      
      double MeanRelNetProfit = MathMean(positionNetProfit);
      double StdDevRelNetProfit = MathStandardDeviation(positionNetProfit);
      
      double stdDevExcludeMultiple = 4.0; //Exclude trades that have values in excess of 4SD from the mean
      int numExcludedTrades = 0;
      sumOfProfit = 0;
      sumOfLosses = 0;
      
      for(int positionNum = 1; positionNum <= positionCount; positionNum++)
      {
         if(positionNetProfit[positionNum - 1] < MeanRelNetProfit-(stdDevExcludeMultiple*StdDevRelNetProfit)  ||  
            positionNetProfit[positionNum - 1] > MeanRelNetProfit+(stdDevExcludeMultiple*StdDevRelNetProfit))
         {
            numExcludedTrades++;
         }
         else
         {
            if(positionNetProfit[positionNum - 1] > 0)
               sumOfProfit += positionNetProfit[positionNum - 1];
            else
               sumOfLosses += positionNetProfit[positionNum - 1];
         }
      }
      
      dCustomPerformanceMetric = NULL;
      
      if(sumOfLosses != 0)
         dCustomPerformanceMetric = MathAbs(sumOfProfit / sumOfLosses);
         
      //WRITE OUT FINAL DIAGNOSTIC DATA
      if(DiagnosticLoggingLevel >= 1)
      {
         FileWrite(outputFileHandle, "\nEXCLUDING EXTREME (NEWS AFFECTED) TRADES:");
         FileWrite(outputFileHandle, "TOTAL TRADES BEFORE EXCLUSIONS", positionCount);
         FileWrite(outputFileHandle, "MEAN RELATIVE NET PROFIT", MeanRelNetProfit);
         FileWrite(outputFileHandle, "STD DEV RELATIVE NET PROFIT", StdDevRelNetProfit);
         FileWrite(outputFileHandle, "NUM TRADES EXCLUDED (> " + DoubleToString(stdDevExcludeMultiple, 1) + " SD)", numExcludedTrades, DoubleToString(((double)numExcludedTrades/positionCount)*100.0) + "%");
         FileWrite(outputFileHandle, "MODIFIED PROFIT FACTOR", dCustomPerformanceMetric);
         
         FileClose(outputFileHandle);
      }
      
      return positionCount;
   }  
   
