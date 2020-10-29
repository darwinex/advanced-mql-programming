
   //+--------------------------------------------------------------------------------+
   //| control-bar-opening-multi-symbol.mq5                                           |
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
   
   #property copyright     "Darwinex"
   #property link          "http://www.darwinex.com"
   #property description   "Bar Controlling Code (Multi Symbol) - Darwinex Advanced MQL Coding Video Series. Author: Martyn Tinsley, Trade Like A Machine Ltd"        
   
   #property strict
   
   enum ENUM_BAR_PROCESSING_METHOD
   {
      PROCESS_ALL_DELIVERED_TICKS,                 //Process All Delivered Ticks
      ONLY_PROCESS_TICKS_FROM_NEW_M1_BAR,          //Only Process Ticks From New M1 Bar
      ONLY_PROCESS_TICKS_FROM_NEW_TRADE_TF_BAR     //Only Process Ticks From New Bar in Trade TF
   };
   
   //################
   // Input Variables 
   //################
   
   input string                         TradeSymbols           = "AUDCAD|AUDJPY|AUDNZD|AUDUSD";       //Symbol(s)
   input ENUM_TIMEFRAMES                TradeTimeframe         = PERIOD_M15;                          //Trading Timeframe
   input ENUM_BAR_PROCESSING_METHOD     BarProcessingMethod    = ONLY_PROCESS_TICKS_FROM_NEW_M1_BAR;  //EA Bar Processing Method
   
   //################
   //Global Variables
   //################
   
   int      NumberOfTradeableSymbols;                    //Set in OnInit()
   string   SymbolArray[];                               //Set in OnInit()
   
   int      TicksReceivedCount                = 0;       //Number of ticks received by the EA
   int      TicksProcessedCount               = 0;       //Number of ticks processed by the EA (will depend on the BarProcessingMethod being used)
   datetime TimeLastTickProcessed[];                     //Used to control the processing of trades so that processing only happens at the desired intervals (to allow like-for-like back testing between the Strategy Tester and Live Trading)
   string   SymbolsProcessedThisIteration;
   
   int      iBarToUseForProcessing;                      //This will either be bar 0 or bar 1, and depends on the BarProcessingMethod - Set in OnInit()
   
   int OnInit()
   {
      //Populate SymbolArray and determine the number of symbols being traded
      NumberOfTradeableSymbols = StringSplit(TradeSymbols, '|', SymbolArray);
      
      ArrayResize(TimeLastTickProcessed, NumberOfTradeableSymbols);
      ArrayInitialize(TimeLastTickProcessed, D'1971.01.01 00:00');
      
      //################################
      //Determine which bar we will used (0 or 1) to perform processing of data
      //################################
      
      if(BarProcessingMethod == PROCESS_ALL_DELIVERED_TICKS)                        //Process data every tick that is 'delivered' to the EA
         iBarToUseForProcessing = 0;                                                //The rationale here is that it is only worth processing every tick if you are actually going to use bar 0 from the trade TF, the value of which changes throughout the bar in the Trade TF                                          //The rationale here is that we want to use values that are right up to date - otherwise it is pointless doing this every 10 seconds
      
      else if(BarProcessingMethod == ONLY_PROCESS_TICKS_FROM_NEW_M1_BAR)            //Process trades based on 'any' TF, every minute.
         iBarToUseForProcessing = 0;                                                //The rationale here is that it is only worth processing every minute if you are actually going to use bar 0 from the trade TF, the value of which changes throughout the bar in the Trade TF
         
      else if(BarProcessingMethod == ONLY_PROCESS_TICKS_FROM_NEW_TRADE_TF_BAR)      //Process when a new bar appears in the TF being used. So the M15 TF is processed once every 15 minutes, the TF60 is processed once every hour etc...
         iBarToUseForProcessing = 1;                                                //The rationale here is that if you only process data when a new bar in the trade TF appears, then it is better to use the indicator data etc from the last 'completed' bar, which will not subsequently change. (If using indicator values from bar 0 these will change throughout the evolution of bar 0) 
   
      Print("EA USING " + EnumToString(BarProcessingMethod) + " PROCESSING METHOD AND INDICATORS WILL USE BAR " + IntegerToString(iBarToUseForProcessing));
 
      //Perform immediate update to screen so that if out of hours (e.g. at the weekend), the screen will still update (this is also run in OnTick())
      if(!MQLInfoInteger(MQL_TESTER))
         OutputStatusToScreen(); 
         
      return(INIT_SUCCEEDED);     
   }

   void OnDeinit(const int reason)
   {
      Comment("");
   }
   
   void OnTick()
   {
      TicksReceivedCount++;

      //##################################
      //Loop through each tradeable Symbol to ascertain if we need to process this iteration
      //##################################
   
      SymbolsProcessedThisIteration = "";
      
      for(int SymbolLoop = 0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      {
         string CurrentSymbol = SymbolArray[SymbolLoop];
         
         //###############################################################
         //Control EA so that we only process trades at required intervals (Either 'Every Tick', 'TF Open Prices' or 'M1 Open Prices')
         //###############################################################
         
         bool ProcessThisIteration = false;     //Set to false by default and then set to true below if required
         
         if(BarProcessingMethod == PROCESS_ALL_DELIVERED_TICKS)
            ProcessThisIteration = true;
         
         else if(BarProcessingMethod == ONLY_PROCESS_TICKS_FROM_NEW_M1_BAR)    //Process trades from any TF, every minute.
         {
            if(TimeLastTickProcessed[SymbolLoop] != iTime(CurrentSymbol, PERIOD_M1, 0))
            {
               ProcessThisIteration = true;
               TimeLastTickProcessed[SymbolLoop] = iTime(CurrentSymbol, PERIOD_M1, 0);
            }
         }
         
         else if(BarProcessingMethod == ONLY_PROCESS_TICKS_FROM_NEW_TRADE_TF_BAR) //Process when a new bar appears in the TF being used. So the M15 TF is processed once every 15 minutes, the TF60 is processed once every hour etc...
         {
            if(TimeLastTickProcessed[SymbolLoop] != iTime(CurrentSymbol, TradeTimeframe, 0))      // TimeLastTickProcessed contains the last Time[0] we processed for this TF. If it's not the same as the current value, we know that we have a new bar in this TF, so need to process 
            {
               ProcessThisIteration = true;
               TimeLastTickProcessed[SymbolLoop] = iTime(CurrentSymbol, TradeTimeframe, 0);
            }
         }
         
         //#############################
         //Process Trades if appropriate
         //#############################

         if(ProcessThisIteration == true)
         {
            TicksProcessedCount++;

            SymbolsProcessedThisIteration += CurrentSymbol + "\n\r"; //Used to ouput to screen for visual confirmation of processing
         
            ProcessTradeClosures(SymbolLoop);
            ProcessTradeOpens(SymbolLoop);
            
            Alert("PROCESSING " + CurrentSymbol + " ON " + EnumToString(TradeTimeframe) + " CHART");
         }
      }
      
      //############################################
      //OUTPUT INFORMATION AND METRICS TO THE SCREEN (DO NOT OUTPUT ON EVERY TICK IN PRODUCTION, FOR PERFORMANCE REASONS - DONE HERE FOR ILLUSTRATIVE PURPOSES ONLY)
      //############################################
      
      if(!MQLInfoInteger(MQL_TESTER))
         OutputStatusToScreen();
   }
   
   void ProcessTradeClosures(int SymbolLoop)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      double localBuffer[];
      ArrayResize(localBuffer, 3);
      
      //Use CopyBuffer here to copy indicator buffer for this SymbolLoop to local buffer...
      
      ArraySetAsSeries(localBuffer, true);
      
      double currentIndValue  = localBuffer[iBarToUseForProcessing];
      double previousIndValue = localBuffer[iBarToUseForProcessing + 1];
   }
   
   void ProcessTradeOpens(int SymbolLoop)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      double localBuffer[];
      ArrayResize(localBuffer, 3);
      
      //Use CopyBuffer here to copy indicator buffer for this SymbolLoop to local buffer...
      
      ArraySetAsSeries(localBuffer, true);
      
      double currentIndValue  = localBuffer[iBarToUseForProcessing];
      double previousIndValue = localBuffer[iBarToUseForProcessing + 1];
   }
   
   void OutputStatusToScreen()
   {      
      double offsetInHours = (TimeCurrent() - TimeGMT()) / 3600.0;
      
      string OutputText = "\n\r";
     
      OutputText += "MT5 SERVER TIME: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " (OPERATING AT UTC/GMT" + StringFormat("%+.1f", offsetInHours) + ")\n\r\n\r";
      
      OutputText += Symbol() + " Ticks Received:   " + IntegerToString(TicksReceivedCount) + "\n\r";  
      OutputText += "Ticks Processed across all " + IntegerToString(NumberOfTradeableSymbols) + " symbols:   " + IntegerToString(TicksProcessedCount) + "\n\r";
      OutputText += "PROCESSING METHOD:   " + EnumToString(BarProcessingMethod) + "\n\r";
      OutputText += EnumToString(TradeTimeframe) + " BAR USED FOR PROCESSING INDICATORS / PRICE:   " + IntegerToString(iBarToUseForProcessing) + "\n\r\n\r";

      //SYMBOLS BEING TRADED
      OutputText += "SYMBOLS:   ";
      for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      {
         OutputText += " " + SymbolArray[SymbolLoop];
      }
      
      //Timeframe Info
      OutputText += "\n\rTRADING TIMEFRAME:   " + EnumToString(TradeTimeframe) + "\n\r";
      
      if(SymbolsProcessedThisIteration != "")
         SymbolsProcessedThisIteration = "\n\r" + SymbolsProcessedThisIteration;
         
      OutputText += "\n\rSYMBOLS PROCESSED THIS TICK:" + SymbolsProcessedThisIteration;
      
      Comment(OutputText);
   
      return;
   }
   
   
