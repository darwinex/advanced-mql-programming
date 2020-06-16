
   //+--------------------------------------------------------------------------------+
   //| multi-symbol.mq5                                                               |
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
   
   //NOTE 1: If using the code in this EA to help convert your own EA to have a multi-symbol capability
   //        always remember to take a safe copy of your EA code before making any changes.
   
   //NOTE 2: Testing using multiple symbols takes longer than testing a single symbol because the EA
   //        needs to process multiple price data streams, multiple indicators etc.
   
   //NOTE 3: Backtesting multiple symbols simultaneously can increase the demand for resources considerably on 
   //        the host PC. Monitor memory to ensure this is not causing paging to occur since this will slow down
   //        the process considerably. If paging does occur, additional memory may need to be purchased.
   
   #property link          "https://www.darwinex.com"
   #property description   "Multi Symbol EA Code Example - Darwinex Video Series"
   #property strict
  
   #include <StdLibErr.mqh>
   
   //INPUTS
   input string   TradeSymbols         = "AUDCAD|AUDJPY|AUDNZD|AUDUSD|EURUSD";   //Symbol(s) or ALL or CURRENT
   input int      BBandsPeriods        = 20;       //Bollinger Bands Periods
   input double   BBandsDeviations     = 1.0;      //Bollinger Bands Deviations
   
   //GENERAL GLOBALS   
   string   AllSymbolsString           = "AUDCAD|AUDJPY|AUDNZD|AUDUSD|CADJPY|EURAUD|EURCAD|EURGBP|EURJPY|EURNZD|EURUSD|GBPAUD|GBPCAD|GBPJPY|GBPNZD|GBPUSD|NZDCAD|NZDJPY|NZDUSD|USDCAD|USDCHF|USDJPY";
   int      NumberOfTradeableSymbols;              
   string   SymbolArray[];                        
   int      TicksReceivedCount         = 0;     
   
   //INDICATOR HANDLES
   int handle_BollingerBands[];  
   //Place additional indicator handles here as required 

   //OPEN TRADE ARRAYS
   ulong    OpenTradeOrderTicket[];    //To store 'order' ticket for trades
   //Place additional trade arrays here as required to assist with open trade management
   
   int OnInit()
   {
      if(TradeSymbols == "CURRENT")  //Override TradeSymbols input variable and use the current chart symbol only
      {
         NumberOfTradeableSymbols = 1;
         
         ArrayResize(SymbolArray, 1);
         SymbolArray[0] = Symbol(); 

         Print("EA will process ", SymbolArray[0], " only");
      }
      else
      {  
         string TradeSymbolsToUse = "";
         
         if(TradeSymbols == "ALL")
            TradeSymbolsToUse = AllSymbolsString;
         else
            TradeSymbolsToUse = TradeSymbols;
         
         //CONVERT TradeSymbolsToUse TO THE STRING ARRAY SymbolArray
         NumberOfTradeableSymbols = StringSplit(TradeSymbolsToUse, '|', SymbolArray);
         
         Print("EA will process: ", TradeSymbolsToUse);
      }
      
      //RESIZE OPEN TRADE ARRAYS (based on how many symbols are being traded)
      ResizeCoreArrays();
      
      //RESIZE INDICATOR HANDLE ARRAYS
      ResizeIndicatorHandleArrays();
      
      Print("All arrays sized to accomodate ", NumberOfTradeableSymbols, " symbols");
      
      //INITIALIZE ARAYS
      for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
         OpenTradeOrderTicket[SymbolLoop] = 0;
      
      //INSTANTIATE INDICATOR HANDLES
      if(!SetUpIndicatorHandles())
         return(INIT_FAILED); 
      
      return(INIT_SUCCEEDED);     
   }
   
   void OnDeinit(const int reason)
   {
      Comment("\n\rMulti-Symbol EA Stopped");
   }

   void OnTick()
   {
      TicksReceivedCount++;
      string indicatorMetrics = "";
      
      //LOOP THROUGH EACH SYMBOL TO CHECK FOR ENTRIES AND EXITS, AND THEN OPEN/CLOSE TRADES AS APPROPRIATE
      for(int SymbolLoop = 0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      {
         string CurrentIndicatorValues; //passed by ref below
         
         //GET OPEN SIGNAL (BOLLINGER BANDS SIMPLY USED AS AN EXAMPLE)
         string OpenSignalStatus = GetBBandsOpenSignalStatus(SymbolLoop, CurrentIndicatorValues);      
         StringConcatenate(indicatorMetrics, indicatorMetrics, SymbolArray[SymbolLoop], "  |  ", CurrentIndicatorValues, "  |  OPEN_STATUS=", OpenSignalStatus, "  |  ");
         
         //GET CLOSE SIGNAL (BOLLINGER BANDS SIMPLY USED AS AN EXAMPLE)
         string CloseSignalStatus = GetBBandsCloseSignalStatus(SymbolLoop);
         StringConcatenate(indicatorMetrics, indicatorMetrics, "CLOSE_STATUS=", CloseSignalStatus, "\n\r");
         
         //PROCESS TRADE OPENS
         if((OpenSignalStatus == "LONG" || OpenSignalStatus == "SHORT") && OpenTradeOrderTicket[SymbolLoop] == 0)
            ProcessTradeOpen(SymbolLoop, OpenSignalStatus);
         
         //PROCESS TRADE CLOSURES
         else if((CloseSignalStatus == "CLOSE_LONG" || CloseSignalStatus == "CLOSE_SHORT") && OpenTradeOrderTicket[SymbolLoop] != 0)
            ProcessTradeClose(SymbolLoop, CloseSignalStatus);
      }
      
      //OUTPUT INFORMATION AND METRICS TO THE CHART (No point wasting time on this code if in the Strategy Tester)
      if(!MQLInfoInteger(MQL_TESTER))
         OutputStatusToChart(indicatorMetrics);   
   }
   
   void ResizeCoreArrays()
   {
      ArrayResize(OpenTradeOrderTicket, NumberOfTradeableSymbols);
      //Add other trade arrays here as required
   }
 
   void ResizeIndicatorHandleArrays()
   {
      //Indicator Handles
      ArrayResize(handle_BollingerBands, NumberOfTradeableSymbols);
      //Add other indicators here as required by your EA
   }
   
   //SET UP REQUIRED INDICATOR HANDLES (arrays because of multi-symbol capability in EA)
   bool SetUpIndicatorHandles()
   {  
      //Bollinger Bands
      for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      {
         //Reset any previous error codes so that only gets set if problem setting up indicator handle
         ResetLastError();
      
         handle_BollingerBands[SymbolLoop] = iBands(SymbolArray[SymbolLoop], Period(), BBandsPeriods, 0, BBandsDeviations, PRICE_CLOSE);
         
         if(handle_BollingerBands[SymbolLoop] == INVALID_HANDLE) 
         { 
            string outputMessage = "";
            
            if(GetLastError() == 4302)
               outputMessage = "Symbol needs to be added to the MarketWatch";
            else
               StringConcatenate(outputMessage, "(error code ", GetLastError(), ")");
  
            MessageBox("Failed to create handle of the iBands indicator for " + SymbolArray[SymbolLoop] + "/" + EnumToString(Period()) + "\n\r\n\r" + 
                        outputMessage +
                        "\n\r\n\rEA will now terminate.");
                         
            //Don't proceed
            return false;
         } 
         
         Print("Handle for iBands / ", SymbolArray[SymbolLoop], " / ", EnumToString(Period()), " successfully created");
      }
      
      //All completed without errors so return true
      return true;
   }
   
   string GetBBandsOpenSignalStatus(int SymbolLoop, string& signalDiagnosticMetrics)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      //Need to copy values from indicator buffers to local buffers
      int    numValuesNeeded = 3;
      double bufferUpper[];
      double bufferLower[];
      
      bool fillSuccessUpper = tlamCopyBuffer(handle_BollingerBands[SymbolLoop], UPPER_BAND, bufferUpper, numValuesNeeded, CurrentSymbol, "BBANDS");
      bool fillSuccessLower = tlamCopyBuffer(handle_BollingerBands[SymbolLoop], LOWER_BAND, bufferLower, numValuesNeeded, CurrentSymbol, "BBANDS");
      
      if(fillSuccessUpper == false  ||  fillSuccessLower == false)
         return("FILL_ERROR");     //No need to log error here. Already done from tlamCopyBuffer() function
      
      double CurrentBBandsUpper = bufferUpper[0];
      double CurrentBBandsLower = bufferLower[0];
      
      double CurrentClose = iClose(CurrentSymbol, Period(), 0);
       
      //SET METRICS FOR BBANDS WHICH GET RETURNED TO CALLING FUNCTION BY REF FOR OUTPUT TO CHART
      StringConcatenate(signalDiagnosticMetrics, "UPPER=", DoubleToString(CurrentBBandsUpper, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)), "  |  LOWER=", DoubleToString(CurrentBBandsLower, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)), "  |  CLOSE=" + DoubleToString(CurrentClose, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)));
      
      
      //INSERT YOUR OWN ENTRY LOGIC HERE
      //e.g.
      //if(CurrentClose > CurrentBBandsUpper)
      //   return("SHORT");
      //else if(CurrentClose < CurrentBBandsLower)
      //   return("LONG");
      //else
           return("NO_TRADE");
   }
   
   string GetBBandsCloseSignalStatus(int SymbolLoop)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      //Need to copy values from indicator buffers to local buffers
      int    numValuesNeeded = 3;
      double bufferUpper[];
      double bufferLower[];
      
      bool fillSuccessUpper = tlamCopyBuffer(handle_BollingerBands[SymbolLoop], UPPER_BAND, bufferUpper, numValuesNeeded, CurrentSymbol, "BBANDS");
      bool fillSuccessLower = tlamCopyBuffer(handle_BollingerBands[SymbolLoop], LOWER_BAND, bufferLower, numValuesNeeded, CurrentSymbol, "BBANDS");
      
      if(fillSuccessUpper == false  ||  fillSuccessLower == false)
         return("FILL_ERROR");     //No need to log error here. Already done from tlamCopyBuffer() function
      
      double CurrentBBandsUpper = bufferUpper[0];
      double CurrentBBandsLower = bufferLower[0];
      
      double CurrentClose = iClose(CurrentSymbol, Period(), 0);
       
      //INSERT YOUR OWN ENTRY LOGIC HERE
      //e.g.
      //if(CurrentClose < CurrentBBandsLower)
      //   return("CLOSE_SHORT");
      //else if(CurrentClose > CurrentBBandsUpper)
      //   return("CLOSE_LONG");
      //else
           return("NO_CLOSE_SIGNAL");
   }
   
   bool tlamCopyBuffer(int ind_handle,            // handle of the indicator 
                       int buffer_num,            // for indicators with multiple buffers
                       double &localArray[],      // local array 
                       int numBarsRequired,       // number of values to copy 
                       string symbolDescription,  
                       string indDesc)
   {
      
      int availableBars;
      bool success = false;
      int failureCount = 0;
      
      //Sometimes a delay in prices coming through can cause failure, so allow 3 attempts
      while(!success)
      {
         availableBars = BarsCalculated(ind_handle);
         
         if(availableBars < numBarsRequired)
         {
            failureCount++;
            
            if(failureCount >= 3)
            {
               Print("Failed to calculate sufficient bars in tlamCopyBuffer() after ", failureCount, " attempts (", symbolDescription, "/", indDesc, " - Required=", numBarsRequired, " Available=", availableBars, ")");
               return(false);
            }
            
            Print("Attempt ", failureCount, ": Insufficient bars calculated for ", symbolDescription, "/", indDesc, "(Required=", numBarsRequired, " Available=", availableBars, ")");
            
            //Sleep for 0.1s to allow time for price data to become usable
            Sleep(100);
         }
         else
         {
            success = true;
            
            if(failureCount > 0) //only write success message if previous failures registered
               Print("Succeeded on attempt ", failureCount+1);
         }
      }
       
      ResetLastError(); 
      
      int numAvailableBars = CopyBuffer(ind_handle, buffer_num, 0, numBarsRequired, localArray);
      
      if(numAvailableBars != numBarsRequired) 
      { 
         Print("Failed to copy data from indicator with error code ", GetLastError(), ". Bars required = ", numBarsRequired, " but bars copied = ", numAvailableBars);
         return(false); 
      } 
      
      //Ensure that elements indexed like in a timeseries (with index 0 being the current, 1 being one bar back in time etc.)
      ArraySetAsSeries(localArray, true);
      
      return(true); 
   }
   
   void ProcessTradeOpen(int SymbolLoop, string TradeDirection)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      //INSERT YOUR PRE-CHECKS HERE
      
      //SETUP MqlTradeRequest orderRequest and MqlTradeResult orderResult HERE 
      //Ensure that CurrentSymbol is used as the symbol 
      
      //bool success = OrderSend(orderRequest, orderResult);
      
      //CHECK FOR ERRORS AND HANDLE EXCEPTIONS HERE
      
      //SET TRADE ARRAY TO PREVENT FUTURE TRADES BEING OPENED UNTIL THIS IS CLOSED
      //OpenTradeOrderTicket[SymbolLoop] = orderResult.order;
   }
   
   void ProcessTradeClose(int SymbolLoop, string CloseDirection)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      //INCLUSE PRE-CLOSURE CHECKS HERE
      
      //SETUP CTrade tradeObject HERE
         
      //bool bCloseCheck = tradeObject.PositionClose(OpenTradeOrderTicket[SymbolLoop], 0); 
      
      //CHECK FOR ERRORS AND HANDLE EXCEPTIONS HERE
      
      //IF SUCCESSFUL SET TRADE ARRAY TO 0 TO ALLOW FUTURE TRADES TO BE OPENED
      //OpenTradeOrderTicket[SymbolLoop] = 0;
   }
   
   void OutputStatusToChart(string additionalMetrics)
   {      
      //GET GMT OFFSET OF MT5 SERVER
      double offsetInHours = (TimeCurrent() - TimeGMT()) / 3600.0;
 
      //SYMBOLS BEING TRADED
      string symbolsText = "SYMBOLS BEING TRADED: ";
      for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
         StringConcatenate(symbolsText, symbolsText, " ", SymbolArray[SymbolLoop]);
      
      Comment("\n\rMT5 SERVER TIME: ", TimeCurrent(), " (OPERATING AT UTC/GMT", StringFormat("%+.1f", offsetInHours), ")\n\r\n\r",
               Symbol(), " TICKS RECEIVED: ", TicksReceivedCount, "\n\r\n\r",
               symbolsText,
               "\n\r\n\r", additionalMetrics);
   }
