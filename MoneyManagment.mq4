#property copyright ""
#property link ""

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
extern string comment4 = "Clear arrows";
extern bool clearArrows = 1;
extern color indicator_clr1 = Gold;
extern color indicator_clr2 = Aqua;
extern int Position = 1;

// Bemeneti paraméterek a százalékokhoz
extern int riskPercent1 = 1;
extern int riskPercent2 = 5;
extern int riskPercent3 = 10;

double riskedMoney;
const double RISK_MULTIPLIER = 0.1;

// Objektum nevek
string lotObjectName = "Lot";
string lot1ObjectName = "Lot1";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init() {
  return (0);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit() {
  // Töröljük az objektumokat
  ObjectDelete(lotObjectName);
  ObjectDelete(lot1ObjectName);
  return (0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start() {
  DisplayText(
      lotObjectName,
      "Trade with Risk " + IntegerToString(riskPercent1) + "%, " +
          IntegerToString(riskPercent2) + "%, " +
          IntegerToString(riskPercent3) + "% :",
      "Arial", 8, indicator_clr1, 90, 10, Position);

  DisplayText(lot1ObjectName,
              LotCalculateWithRisk(riskPercent1) + ", " +
                  LotCalculateWithRisk(riskPercent2) + ", " +
                  LotCalculateWithRisk(riskPercent3),
              "Arial", 8, indicator_clr2, 10, 10, Position);
  return (0);
}

//+------------------------------------------------------------------+
double LotCalculate() {
  return LotCalculateWithRisk(riskInPercent);
}

double LotCalculateWithRisk(int riskPercent) {
  int ratio;
  double calculatedLot, accountMoney;

  // Calculate risked money based on risk percentage
  accountMoney = withLoan ? AccountEquity() : AccountBalance();
  riskedMoney = (accountMoney * riskPercent) / 100;

  switch (accountType) {
  case 1:
    ratio = 100;
    break;
  case 2:
    ratio = 10;
    break;
  case 3:
    ratio = 1;
    break;
  }

  calculatedLot = (RISK_MULTIPLIER * riskedMoney) / (SLinFPips / ratio);
  if (lotModifier > 0) calculatedLot = calculatedLot * lotModifier;

  return (NormalizeDouble(calculatedLot, 2));
}

//+------------------------------------------------------------------+
void DisplayText(string objname, string objtext, string fontname, int fontsize,
                 int clr, int x, int y, int Cor) {
  ObjectCreate(objname, OBJ_LABEL, 0, 0, 0);
  ObjectSetText(objname, objtext, fontsize, fontname, clr);
  ObjectSet(objname, OBJPROP_CORNER, Cor);
  ObjectSet(objname, OBJPROP_XDISTANCE, x);
  ObjectSet(objname, OBJPROP_YDISTANCE, y);
}
//+------------------------------------------------------------------+
