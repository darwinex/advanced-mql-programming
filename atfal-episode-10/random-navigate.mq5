//+------------------------------------------------------------------+
//|                                     NaviagteToRandomChartPos.mq5 |
//|                                         Copyright 2021, Darwinex |
//|                                         https://www.darwinex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Darwinex"
#property link      "https://www.darwinex.com"
#property version   "1.00"

void OnStart()
{
   //Disable AutoScroll
   ChartSetInteger(0, CHART_AUTOSCROLL, false);
   
   //Set a shift from the right chart border
   ChartSetInteger(0, CHART_SHIFT, true);
   
   //Initialize the generation of random numbers
   MathSrand(GetTickCount());

   //Get Random Chart Shift between 0 and 5000
   int randomShift = int((MathRand() / 32767.0) * 5000);

   //Naviagte to random position
   ChartNavigate(0, CHART_END, -1 * randomShift); 
}
