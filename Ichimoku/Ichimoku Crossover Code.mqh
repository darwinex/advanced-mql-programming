//+------------------------------------------------------------------+
//|                                      Ichimoku Crossover Code.mqh |
//|                Copyright 2022, Darwinex and Trade Like A Machine |
//|                                         https://www.darwinex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Darwinex and Trade Like A Machine"
#property link      "https://www.darwinex.com"
#property version   "1.00"
   
//###################################################################
// IMPORTANT NOTE: THIS IS NOT A FULLY FUNCTIONAL EXPERT ADVISOR.
// THESE ARE HELPER FUNCTIONS AND ARE DESIGNED TO BE INCLUDED IN
// AN EA TO ALLOW THE PROCESSING OF TENKAN-SEN / KIJUN-SEN CROSSOVERS
// FOR A FULL EXPLANATION, SEE https://youtu.be/YdVicbmvwio
//###################################################################
   
   bool GetIchimokuTenKijCrossOpenSignal_BullishCrossover()
   {
      //THIS ROUTINE, TO CHECK IF A CROSSOVER HAS OCCURRED IS NECESSARY BECAUSE OFTEN TENKAN-SEN AND KIJUN-SEN HAVE EXACTLY THE SAME VALUE FOR MULTIPLE CONSEQUITIVE BARS, AND SO 'CLEAN' CROSSOVERS 
      //IN THE SPACE OF JUST 2 BARS OFTEN DO NOT HAPPEN, AND IT TAKES MORE BARS FOR THE CROSSOVER TO COMPLETE
      
      IchimokuIndicator.Refresh(-1);  //UPDATE INDICATOR DATA
      
      //THIS COUNTER IS INCREMENTED IN THE LOOP BELOW
      int currBar = 0;
      
      double tenkanSen   = IchimokuIndicator.TenkanSen(currBar);      
      double kijunSen    = IchimokuIndicator.KijunSen(currBar);        
      
      if(NormalizeDouble(tenkanSen, 6) <= NormalizeDouble(kijunSen, 6)) 
         return false; //SINCE curr TenkanSen <= curr KijunSen IT IS IMPOSSIBLE THAT A 'BULLISH' CROSSOVER HAS OCCURRED. RETURN false
         
      //IF REACHING THIS POINT, IT IS 'POSSIBLE' THAT A BULLISH CROSSOVER HAS JUST OCCURRED, BECAUSE TENKAN-SEN IS ABOVE KIJUN-SEN, 'BUT' PREVIOUS BARS NEED TO BE CHECKED BEFORE WE KNOW
      
      while(true)
      {
         currBar++; //INCREMENT THE BAR THAT WILL BE CHECKED NEXT
         
         tenkanSen   = IchimokuIndicator.TenkanSen(currBar);      
         kijunSen    = IchimokuIndicator.KijunSen(currBar);   
         
         if(NormalizeDouble(tenkanSen, 6) > NormalizeDouble(kijunSen, 6))
            return false;  //THE ORIGINAL CHECK FROM THE MOST RECENT BAR (iBarToUseForProcessing) DETERMINED TENKAN-SEN WAS 'ABOVE' KIJUN-SEN. THIS IS STILL THE CASE WITH THE PREV BAR AND SO A CROSSOVER CANNOT HAVE JUST OCCURRED - RETURN false
         
         if(NormalizeDouble(tenkanSen, 6) < NormalizeDouble(kijunSen, 6))
            return true;   //TENKAN-SEN WAS 'BELOW' KIJUN-SEN SO A CROSSOVER HAS OCCURED - RETURN true
            
         //OTHERWISE IT MEANS THAT TENKAN-SEN AND KIJUN-SEN HAVE EQUAL VALUES, SO NEED TO GO BACK ANOTHER BAR IN THE WHILE LOOP AND CONTINUE CHECKING
      }
   }
   
   bool GetIchimokuTenKijCrossOpenSignal_BearishCrossover()
   {
      //THIS ROUTINE, TO CHECK IF A CROSSOVER HAS OCCURRED IS NECESSARY BECAUSE OFTEN TENKAN-SEN AND KIJUN-SEN HAVE EXACTLY THE SAME VALUE FOR MULTIPLE CONSEQUITIVE BARS, AND SO 'CLEAN' CROSSOVERS 
      //IN THE SPACE OF JUST 2 BARS OFTEN DO NOT HAPPEN, AND IT TAKES MORE BARS FOR THE CROSSOVER TO COMPLETE
      
      IchimokuIndicator.Refresh(-1);  //UPDATE INDICATOR DATA
      
      //THIS COUNTER IS INCREMENTED IN THE LOOP BELOW
      int currBar = 0;
      
      double tenkanSen   = IchimokuIndicator.TenkanSen(currBar);      
      double kijunSen    = IchimokuIndicator.KijunSen(currBar);        
      
      if(NormalizeDouble(tenkanSen, 6) >= NormalizeDouble(kijunSen, 6)) 
         return false; //SINCE curr TenkanSen >= curr KijunSen IT IS IMPOSSIBLE THAT A 'BEARISH' CROSSOVER HAS OCCURRED. RETURN false
         
      //IF REACHING THIS POINT, IT IS 'POSSIBLE' THAT A BEARISH CROSSOVER HAS JUST OCCURRED, BECAUSE TENKAN-SEN IS BELOW KIJUN-SEN, 'BUT' PREVIOUS BARS NEED TO BE CHECKED BEFORE WE KNOW
      
      while(true)
      {
         currBar++; //INCREMENT THE BAR THAT WILL BE CHECKED NEXT
         
         tenkanSen   = IchimokuIndicator.TenkanSen(currBar);      
         kijunSen    = IchimokuIndicator.KijunSen(currBar);   
         
         if(NormalizeDouble(tenkanSen, 6) < NormalizeDouble(kijunSen, 6))
            return false;  //THE ORIGINAL CHECK FROM THE MOST RECENT BAR (iBarToUseForProcessing) DETERMINED TENKAN-SEN WAS 'BELOW' KIJUN-SEN. THIS IS STILL THE CASE WITH THE PREV BAR AND SO A CROSSOVER CANNOT HAVE JUST OCCURRED - RETURN false
         
         if(NormalizeDouble(tenkanSen, 6) > NormalizeDouble(kijunSen, 6))
            return true;   //TENKAN-SEN WAS 'ABOVE' KIJUN-SEN SO A CROSSOVER HAS OCCURED - RETURN true
            
         //OTHERWISE IT MEANS THAT TENKAN-SEN AND KIJUN-SEN HAVE EQUAL VALUES, SO NEED TO GO BACK ANOTHER BAR IN THE WHILE LOOP AND CONTINUE CHECKING
      }
   }
