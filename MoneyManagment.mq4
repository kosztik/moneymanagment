
#property copyright ""
#property link      ""

#property indicator_chart_window
#property indicator_buffers 2
extern string comment0 = "Default settings are optimized to xm micro accounts";
extern string comment1 = "1- micro, 2- mini, 3- normal";
extern string comment2 = "1 pip=$0.001, 1 pip=$0.01, 1 pip=$0.1";
extern int accountType = 1;
extern int riskInPercent = 1;
extern string comment3 = "For example xm micro accounts where 0.1 lot = 1 micro lot";
extern int lotModifier = 10;
extern int SLinFPips = 400;
extern bool withLoan = 0;
extern string comment4 ="Clear arrows";
extern bool clearArrows = 1;
extern color indicator_clr1= Gold;
extern color indicator_clr2= Aqua;
extern int       Position =1;

double riskedMoney;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   ObjectDelete("lot");
   ObjectDelete("lot1");
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
//----
  DisplayText("Lot","Trade with Risk 1%, 2%, 10% :","Arial",8,indicator_clr1,90,10,Position);
  DisplayText("Lot1",LotCalculate1(1)+", "+LotCalculate1(2)+", "+LotCalculate1(10),"Arial",8,indicator_clr2,10,10,Position);
//----
   return(0);
  }
//+------------------------------------------------------------------+
double LotCalculate() {
   int ratio;
   double calculatedLot, accountMoney;
   // kiszamolom a equity risInPercent százalékát
   if (withLoan == 1) {
      accountMoney = AccountEquity();
   } else {
      accountMoney = AccountBalance();
   }
   riskedMoney = (accountMoney * riskInPercent) / 100;
   
   switch ( accountType )                           // Operator header 
      {                                          // Opening brace
      case 1: ratio = 100; break;                   // One of the 'case' variations 
      case 2: ratio = 10;  break;                  // One of the 'case' variations 
      case 3: ratio = 1;   break;
      //[default: Operators]                        // Variation without any parameter
      }   
      
   calculatedLot = (0.1*riskedMoney) /(SLinFPips/ratio) ;
   if (lotModifier>0) calculatedLot = calculatedLot * lotModifier;
   
  return( NormalizeDouble(calculatedLot, 2) );    
}


double LotCalculate1(int q) {
   int ratio;
   double calculatedLot, accountMoney;
   // kiszamolom a equity risInPercent százalékát
   if (withLoan == 1) {
      accountMoney = AccountEquity();
   } else {
      accountMoney = AccountBalance();
   }
   riskedMoney = (accountMoney * q) / 100;
   
   switch ( accountType )                           // Operator header 
      {                                          // Opening brace
      case 1: ratio = 100; break;                   // One of the 'case' variations 
      case 2: ratio = 10;  break;                  // One of the 'case' variations 
      case 3: ratio = 1;   break;
      //[default: Operators]                        // Variation without any parameter
      }   
      
   calculatedLot = (0.1*riskedMoney) /(SLinFPips/ratio) ;
   if (lotModifier>0) calculatedLot = calculatedLot * lotModifier;
   
  return( NormalizeDouble(calculatedLot, 2) );    
}
//+------------------------------------------------------------------+
void DisplayText(string objname, string objtext, string fontname, int fontsize, int clr, int x, int y,int Cor)
   {
      ObjectCreate(objname,OBJ_LABEL,0,0,0);
      ObjectSetText(objname,objtext,fontsize,fontname,clr);
      ObjectSet(objname,OBJPROP_CORNER,Cor);
      ObjectSet(objname,OBJPROP_XDISTANCE,x);
      ObjectSet(objname,OBJPROP_YDISTANCE,y);
   }
//+------------------------------------------------------------------+   
