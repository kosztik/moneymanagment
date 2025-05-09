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
extern color positionColor = LightGreen;
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
extern int lotDigits = 2;
extern int profitDigits = 2;
extern int profitWidth = 8;

// Frissítési beállítások
extern int refreshSeconds = 60;

// ÚJ: Paraméterek az order státusz dobozhoz
extern bool ShowOrderStatusBox = true;
extern int OrderStatusFontSize = 30;

double riskedMoney;
const double RISK_MULTIPLIER = 0.1;

// Objektum nevek
string tableHeaderObjectName = "TableHeader";
string tableRisk1ObjectName = "TableRisk1";
string tableRisk2ObjectName = "TableRisk2";
string tableRisk3ObjectName = "TableRisk3";
string symbolObjectName = "SymbolName";
string positionHeaderObjectName = "PositionHeader";
string positionInfoObjectName = "PositionInfo";
string orderStatusRectName = "OrderStatusRect";
string orderStatusTextName = "OrderStatusText";

// Változók az újraszámolás optimalizálásához
datetime lastUpdateTime = 0;
double lastAccountBalance = 0;
double lastAccountEquity = 0;
int lastOrdersTotal = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init() {
  // Ellenőrizzük az accountType értékét
  if (accountType < 1 || accountType > 3) {
    Print("Error: Invalid accountType value: ", accountType, ". Must be 1, 2, or 3. Setting to default (1).");
    accountType = 1;
  }

  // Ellenőrizzük az SLinFPips értékét
  if (SLinFPips <= 0) {
    Print("Error: Invalid SLinFPips value: ", SLinFPips, ". Must be greater than 0. Setting to default (400).");
    SLinFPips = 400;
  }

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
  ObjectDelete(orderStatusRectName);
  ObjectDelete(orderStatusTextName);
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

  // Ellenőrizzük, hogy változott-e a nyitott/függőben lévő orderek száma
  if (OrdersTotal() != lastOrdersTotal || ShowOrderStatusBox) {
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

  // ÚJ: Order státusz doboz megjelenítése
  DisplayOrderStatusBox();
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
  int ratio = 1; // Alapértelmezett érték
  double calculatedLot, accountMoney;

  // Naplózás a hibakereséshez
  // Print("LotCalculateWithRisk: riskPercent=", riskPercent, ", accountType=", accountType, ", SLinFPips=", SLinFPips);

  // Ellenőrizzük, hogy a szimbólum érvényes-e
  if (StringLen(Symbol()) == 0) {
    Print("Error: Invalid symbol.");
    return (0.0);
  }

  // Calculate risked money based on risk percentage
  accountMoney = withLoan ? AccountEquity() : AccountBalance();
  riskedMoney = (accountMoney * riskPercent) / 100;
  // Print("accountMoney=", accountMoney, ", riskedMoney=", riskedMoney);

  // Ratio beállítása
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
  default:
    Print("Error: Invalid accountType value: ", accountType, ". Using default ratio = 1.");
    ratio = 1;
    break;
  }
  //Print("ratio=", ratio);

  // Avoid division by zero if SLinFPips is 0
  if (SLinFPips == 0) {
    Print("Error: SLinFPips is 0, cannot calculate lot size.");
    return (0.0);
  }

  calculatedLot = (RISK_MULTIPLIER * riskedMoney) / (SLinFPips / ratio);
  // Print("calculatedLot (before modifier)=", calculatedLot);
  if (lotModifier > 0) calculatedLot = calculatedLot * lotModifier;
  // Print("calculatedLot (after modifier)=", calculatedLot, ", lotModifier=", lotModifier);

  // Normalize lot size based on broker limitations
  double minLot = MarketInfo(Symbol(), MODE_MINLOT);
  double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
  double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

  // Ellenőrizzük a MarketInfo értékeket
  if (minLot == 0 || maxLot == 0 || lotStep == 0) {
    Print("Error: Invalid MarketInfo values: minLot=", minLot, ", maxLot=", maxLot, ", lotStep=", lotStep);
    return (0.0);
  }

  calculatedLot = MathRound(calculatedLot / lotStep) * lotStep;

  if (calculatedLot < minLot) calculatedLot = minLot;
  if (calculatedLot > maxLot) calculatedLot = maxLot;

  return (NormalizeDouble(calculatedLot, 2));
}

//+------------------------------------------------------------------+
double CalculateProfitForPips(double lotSize) {
  double pipValue = 0.0;
  double pointValue = MarketInfo(Symbol(), MODE_TICKVALUE);
  double pointSize = MarketInfo(Symbol(), MODE_POINT);
  int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);

  // Calculate pip size
  double pipSize = pointSize * 10;
  if (digits == 3 || digits == 5) {
    pipSize = pointSize * 10;
  } else {
    pipSize = pointSize;
  }

  // Calculate value per pip for 1 standard lot
  double pipValuePerLot = pointValue / pointSize * pipSize;

  // Calculate profit based on actual lot size and target pips
  double actualBrokerLotSize = lotSize;
  if (accountType == 1 && lotModifier > 0) {
    actualBrokerLotSize = lotSize / lotModifier;
  } else if (accountType == 2 && lotModifier > 0) {
    actualBrokerLotSize = lotSize / lotModifier;
  }

  double actualLotSizeForCalc = lotSize;
  if (lotModifier > 0) {
    actualLotSizeForCalc = lotSize / lotModifier;
  }

  switch (accountType) {
  case 1:
    pipValue = 0.10 * actualLotSizeForCalc;
    break;
  case 2:
    pipValue = 1.0 * actualLotSizeForCalc;
    break;
  case 3:
    pipValue = 10.0 * actualLotSizeForCalc;
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
  if (ObjectFind(objname) < 0) {
    ObjectCreate(objname, OBJ_LABEL, 0, 0, 0);
  }
  ObjectSetText(objname, objtext, fontsize, fontname, clr);
  ObjectSet(objname, OBJPROP_CORNER, Cor);
  ObjectSet(objname, OBJPROP_XDISTANCE, x);
  ObjectSet(objname, OBJPROP_YDISTANCE, y);
  ObjectSet(objname, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
// ÚJ: Segédfüggvény az order típusának szöveges lekéréséhez
string GetOrderTypeString(int orderType) {
  switch (orderType) {
    case OP_BUY: return "BUY";
    case OP_SELL: return "SELL";
    case OP_BUYLIMIT: return "BUY LIMIT";
    case OP_SELLLIMIT: return "SELL LIMIT";
    case OP_BUYSTOP: return "BUY STOP";
    case OP_SELLSTOP: return "SELL STOP";
    default: return "UNKNOWN";
  }
}

//+------------------------------------------------------------------+
// ÚJ: Megjeleníti az order státusz dobozt a chart tetején középen
void DisplayOrderStatusBox() {
  // Mindig töröljük az előző objektumokat
  ObjectDelete(orderStatusRectName);
  ObjectDelete(orderStatusTextName);

  if (!ShowOrderStatusBox) {
    return;
  }

  int foundOrderSide = -1;
  string orderTypeText = "";
  color backgroundColor;
  int orderTypeFound = -1;

  // Végigmegyünk az összes nyitott ÉS függő orderen
  for (int i = OrdersTotal() - 1; i >= 0; i--) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol() == Symbol()) {
        int type = OrderType();
        if (type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP) {
          foundOrderSide = 0;
          orderTypeFound = type;
          backgroundColor = clrForestGreen;
          break;
        } else if (type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP) {
          foundOrderSide = 1;
          orderTypeFound = type;
          backgroundColor = clrFireBrick;
          break;
        }
      }
    }
  }

  if (foundOrderSide == -1) {
    return;
  }

  orderTypeText = GetOrderTypeString(orderTypeFound);

  // Objektumok létrehozása
  double approxCharWidth = OrderStatusFontSize * 0.6;
  double approxCharHeight = OrderStatusFontSize * 1.5;
  double paddingX = 10;
  double paddingY = 6;

  double rectWidth = StringLen(orderTypeText) * approxCharWidth + paddingX;
  double rectHeight = approxCharHeight + paddingY;

  int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
  int rectX = chartWidth / 2 - (int)(rectWidth / 2);
  int rectY = 10;
  int textX = chartWidth / 2;
  int textY = rectY + (int)(rectHeight / 2);

  // Háttér téglalap
  ObjectCreate(orderStatusRectName, OBJ_RECTANGLE, 0, 0, 0);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_CORNER, 0);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_XDISTANCE, rectX);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_YDISTANCE, rectY);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_XSIZE, (int)rectWidth);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_YSIZE, (int)rectHeight);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_COLOR, backgroundColor);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_BACK, true);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_SELECTABLE, false);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_HIDDEN, false);

  // Szöveg címke
  ObjectCreate(orderStatusTextName, OBJ_LABEL, 0, 0, 0);
  ObjectSetString(0, orderStatusTextName, OBJPROP_FONT, fontName);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_FONTSIZE, OrderStatusFontSize);
  ObjectSetString(0, orderStatusTextName, OBJPROP_TEXT, orderTypeText);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_COLOR, clrWhite);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_CORNER, 0);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_XDISTANCE, textX);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_YDISTANCE, textY);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_ANCHOR, ANCHOR_CENTER);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_BACK, false);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_SELECTABLE, false);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_HIDDEN, false);
}
//+------------------------------------------------------------------+
