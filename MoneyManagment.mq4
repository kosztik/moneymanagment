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
extern color positionColor = LightGreen;  // Új szín a pozíciók megjelenítéséhez
extern int Position = 1;

// Bemeneti paraméterek a százalékokhoz
extern int riskPercent1 = 1;
extern int riskPercent2 = 5;
extern int riskPercent3 = 10;

// Új paraméterek a devizapár nevének megjelenítéséhez
extern int symbolFontSize = 60;
extern color symbolColor = SlateGray;

// Új paraméter a profit számításához
extern int targetPips = 500;

// Betűtípus beállítások
extern string fontName = "Courier New";
extern int tableFontSize = 8;

// Formázási beállítások
extern int lotDigits = 2;       // Lot méret tizedesjegyek száma
extern int profitDigits = 2;    // Profit tizedesjegyek száma
extern int profitWidth = 8;     // Profit mező szélessége

// Frissítési beállítások
extern int refreshSeconds = 1800;  // Frissítési idő másodpercekben

double riskedMoney;
const double RISK_MULTIPLIER = 0.1;

// Objektum nevek
string tableHeaderObjectName = "TableHeader";
string tableRisk1ObjectName = "TableRisk1";
string tableRisk2ObjectName = "TableRisk2";
string tableRisk3ObjectName = "TableRisk3";
string symbolObjectName = "SymbolName";
string positionHeaderObjectName = "PositionHeader";  // Új objektum a pozíciók fejlécéhez
string positionInfoObjectName = "PositionInfo";      // Új objektum a pozíciók információihoz

// Változók az újraszámolás optimalizálásához
datetime lastUpdateTime = 0;
double lastAccountBalance = 0;
double lastAccountEquity = 0;
int lastOrdersTotal = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init() {
  // Első megjelenítés
  UpdateDisplay();
  return (0);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit() {
  // Töröljük az objektumokat
  ObjectDelete(tableHeaderObjectName);
  ObjectDelete(tableRisk1ObjectName);
  ObjectDelete(tableRisk2ObjectName);
  ObjectDelete(tableRisk3ObjectName);
  ObjectDelete(symbolObjectName);
  ObjectDelete(positionHeaderObjectName);
  ObjectDelete(positionInfoObjectName);
  return (0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start() {
  // Ellenőrizzük, hogy szükséges-e frissíteni
  bool needUpdate = false;
  
  // Ellenőrizzük, hogy eltelt-e a megadott idő
  if (TimeCurrent() >= lastUpdateTime + refreshSeconds) {
    needUpdate = true;
  }
  
  // Ellenőrizzük, hogy változott-e a számla egyenlege vagy tőkéje
  if (AccountBalance() != lastAccountBalance || 
      (withLoan && AccountEquity() != lastAccountEquity)) {
    needUpdate = true;
  }
  
  // Ellenőrizzük, hogy változott-e a nyitott pozíciók száma
  if (OrdersTotal() != lastOrdersTotal) {
    needUpdate = true;
  }
  
  // Ha szükséges, frissítjük a megjelenítést
  if (needUpdate) {
    UpdateDisplay();
  }
  
  return (0);
}

//+------------------------------------------------------------------+
// Frissíti a megjelenítést
void UpdateDisplay() {
  // Frissítjük az utolsó frissítés idejét és a számla adatokat
  lastUpdateTime = TimeCurrent();
  lastAccountBalance = AccountBalance();
  lastAccountEquity = AccountEquity();
  lastOrdersTotal = OrdersTotal();
  
  // Táblázat fejléc
  string headerText = "Risk %  |  Lot Size  |  " + IntegerToString(targetPips) + " pips";
  DisplayText(tableHeaderObjectName, headerText, fontName, tableFontSize, indicator_clr1, 10, 10, Position);
  
  // Lot méretek kiszámítása
  double lot1 = LotCalculateWithRisk(riskPercent1);
  double lot2 = LotCalculateWithRisk(riskPercent2);
  double lot3 = LotCalculateWithRisk(riskPercent3);
  
  // Profit kiszámítása
  double profit1Value = CalculateProfitForPips(lot1);
  double profit2Value = CalculateProfitForPips(lot2);
  double profit3Value = CalculateProfitForPips(lot3);
  
  // Formázott értékek
  string lot1Str = FormatDouble(lot1, lotDigits, 8);
  string lot2Str = FormatDouble(lot2, lotDigits, 8);
  string lot3Str = FormatDouble(lot3, lotDigits, 8);
  
  string profit1Str = FormatDouble(profit1Value, profitDigits, profitWidth);
  string profit2Str = FormatDouble(profit2Value, profitDigits, profitWidth);
  string profit3Str = FormatDouble(profit3Value, profitDigits, profitWidth);
  
  // Táblázat sorok
  string risk1Text = StringFormat("%5d%%  |  %s  |  $%s", 
                     riskPercent1, 
                     lot1Str, 
                     profit1Str);
  DisplayText(tableRisk1ObjectName, risk1Text, fontName, tableFontSize, indicator_clr2, 10, 25, Position);
  
  string risk2Text = StringFormat("%5d%%  |  %s  |  $%s", 
                     riskPercent2, 
                     lot2Str, 
                     profit2Str);
  DisplayText(tableRisk2ObjectName, risk2Text, fontName, tableFontSize, indicator_clr2, 10, 40, Position);
  
  string risk3Text = StringFormat("%5d%%  |  %s  |  $%s", 
                     riskPercent3, 
                     lot3Str, 
                     profit3Str);
  DisplayText(tableRisk3ObjectName, risk3Text, fontName, tableFontSize, indicator_clr2, 10, 55, Position);
  
  // Pozíciók információinak megjelenítése
  DisplayPositionInfo();
              
  // Devizapár nevének megjelenítése
  string symbolName = Symbol();
  // Ha tartalmazza a "micro" szót, akkor eltávolítjuk
  string microStr = "micro";
  int pos = StringFind(symbolName, microStr);
  
  if (pos >= 0) {
    string result = "";
    if (pos > 0) {
      result = StringSubstr(symbolName, 0, pos);
    }
    result = result + StringSubstr(symbolName, pos + StringLen(microStr));
    symbolName = result;
  }
  
  // Bal alsó sarokba írjuk ki (Position = 2 a bal alsó sarok)
  DisplayText(symbolObjectName, symbolName, fontName, symbolFontSize, symbolColor, 10, 10, 2);
  
  // Beállítjuk, hogy a háttérben legyen
  ObjectSet(symbolObjectName, OBJPROP_BACK, true);
}

//+------------------------------------------------------------------+
// Megjeleníti a nyitott pozíciók információit
void DisplayPositionInfo() {
  // Pozíciók fejléce
  string posHeaderText = "Current Positions  |  Lot Size  |  Est. Profit";
  DisplayText(positionHeaderObjectName, posHeaderText, fontName, tableFontSize, indicator_clr1, 10, 75, Position);
  
  // Összesített lot méret és becsült profit
  double totalLot = 0;
  double totalEstimatedProfit = 0;
  int openPositions = 0;
  
  // Végigmegyünk az összes nyitott pozíción
  for (int i = 0; i < OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      // Csak a jelenlegi szimbólumra vonatkozó pozíciókat vesszük figyelembe
      if (OrderSymbol() == Symbol() && (OrderType() == OP_BUY || OrderType() == OP_SELL)) {
        totalLot += OrderLots();
        openPositions++;
      }
    }
  }
  
  // Ha nincs nyitott pozíció, akkor ezt jelezzük
  if (openPositions == 0) {
    DisplayText(positionInfoObjectName, "No open positions", fontName, tableFontSize, positionColor, 10, 90, Position);
  } else {
    // Becsült profit kiszámítása a célpipek alapján
    totalEstimatedProfit = CalculateProfitForPips(totalLot);
    
    // Formázott értékek
    string totalLotStr = FormatDouble(totalLot, lotDigits, 8);
    string totalProfitStr = FormatDouble(totalEstimatedProfit, profitDigits, profitWidth);
    
    // Pozíciók információinak megjelenítése
    string posInfoText = StringFormat("%d positions  |  %s  |  $%s", 
                         openPositions, 
                         totalLotStr, 
                         totalProfitStr);
    DisplayText(positionInfoObjectName, posInfoText, fontName, tableFontSize, positionColor, 10, 90, Position);
  }
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
double CalculateProfitForPips(double lotSize) {
  double pipValue = 0.0;
  
  // A tényleges lot méret kiszámítása a lotModifier figyelembevételével
  double actualLotSize = lotSize;
  if (lotModifier > 0) {
    actualLotSize = lotSize / lotModifier;
  }
  
  // Pip érték kiszámítása a számlatípus alapján
  switch (accountType) {
  case 1: // micro
    pipValue = 0.10 * actualLotSize; // 0.1 lot = $0.10 per pip
    break;
  case 2: // mini
    pipValue = 1.0 * actualLotSize; // 0.1 lot = $1.00 per pip
    break;
  case 3: // standard
    pipValue = 10.0 * actualLotSize; // 0.1 lot = $10.00 per pip
    break;
  }
  
  double profit = pipValue * targetPips;
  
  return (profit);
}

//+------------------------------------------------------------------+
// Segédfüggvény a számok formázásához adott szélességgel
string FormatDouble(double value, int digits, int width) {
  string result = DoubleToStr(value, digits);
  
  // Ha a szám rövidebb, mint a kívánt szélesség, akkor kiegészítjük szóközökkel
  int currentLength = StringLen(result);
  if (currentLength < width) {
    for (int i = 0; i < width - currentLength; i++) {
      result = " " + result;
    }
  }
  
  return result;
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
