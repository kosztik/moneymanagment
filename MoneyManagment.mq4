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
extern int refreshSeconds = 60;  // Frissítési idő másodpercekben

// ÚJ: Paraméterek az order státusz dobozhoz
extern bool ShowOrderStatusBox = true; // Mutassa az order státusz dobozt?
extern int OrderStatusFontSize = 30;   // Order státusz szöveg betűmérete

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
// ÚJ: Objektum nevek az order státusz dobozhoz
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
  // ÚJ: Order státusz objektumok törlése
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
  // (Figyelem: OrdersTotal() önmagában nem elég, ha egy order módosul, de a számuk nem)
  // A biztonság kedvéért frissítünk, ha az orderek száma változik,
  // vagy ha a ShowOrderStatusBox be van kapcsolva (mert egy order típusa/léte változhat)
  if (OrdersTotal() != lastOrdersTotal || ShowOrderStatusBox) {
     // Pontosabb lenne figyelni az orderek állapotát, de ez egyszerűbb
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

  // Végigmegyünk az összes nyitott pozíción (MODE_TRADES tartalmazza a nyitottakat és a függőket is)
  for (int i = 0; i < OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      // Csak a jelenlegi szimbólumra vonatkozó NYITOTT pozíciókat vesszük figyelembe
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

  // Avoid division by zero if SLinFPips is 0
  if (SLinFPips == 0) return (0.0);

  calculatedLot = (RISK_MULTIPLIER * riskedMoney) / (SLinFPips / ratio);
  if (lotModifier > 0) calculatedLot = calculatedLot * lotModifier;

  // Normalize lot size based on broker limitations
  double minLot = MarketInfo(Symbol(), MODE_MINLOT);
  double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
  double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

  calculatedLot = MathRound(calculatedLot / lotStep) * lotStep; // Adjust to lot step

  if (calculatedLot < minLot) calculatedLot = minLot;
  if (calculatedLot > maxLot) calculatedLot = maxLot;


  return (NormalizeDouble(calculatedLot, 2)); // NormalizeDouble might not be enough, use the step logic above
}

//+------------------------------------------------------------------+
double CalculateProfitForPips(double lotSize) {
  double pipValue = 0.0;
  double pointValue = MarketInfo(Symbol(), MODE_TICKVALUE); // Value of 1 tick (point) move for 1 standard lot
  double pointSize = MarketInfo(Symbol(), MODE_POINT);     // Size of 1 point (e.g., 0.00001)
  int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);      // Number of digits after decimal point

  // Calculate pip size (e.g., 0.0001 for 5-digit, 0.01 for JPY pairs)
  double pipSize = pointSize * 10;
  if (digits == 3 || digits == 5) {
      pipSize = pointSize * 10;
  } else {
      pipSize = pointSize; // For 2 or 4 digit pairs
  }
   // Correction: Pip size calculation needs refinement based on digits
   if (digits == 3 || digits == 5) pipSize = 10 * pointSize; // 1 pip = 10 points
   else pipSize = pointSize; // 1 pip = 1 point (e.g. JPY pairs)


  // Calculate value per pip for 1 standard lot
  double pipValuePerLot = pointValue / pointSize * pipSize;

  // Calculate profit based on actual lot size and target pips
  // Need to consider the lotModifier correctly
  double actualBrokerLotSize = lotSize;
  if (accountType == 1 && lotModifier > 0) { // Assuming micro account means lotModifier applies
      actualBrokerLotSize = lotSize / lotModifier;
  } else if (accountType == 2 && lotModifier > 0) { // Assuming mini account might also use modifier differently? Let's assume standard interpretation for mini/normal
       // If lotModifier is meant universally, adjust here. Assuming it's mainly for micro display vs broker lots.
       // Let's stick to the original logic for now, assuming lotModifier scales the displayed lot for micro.
       actualBrokerLotSize = lotSize / lotModifier; // Apply modifier if present, regardless of account type? Revisit this based on exact meaning.
       // Let's revert to the original simple calculation based on accountType as it was likely intended for that specific broker setup.
  }

  // Reverting to the simpler, potentially broker-specific calculation from the original code
  // as MarketInfo based calculation might be overly complex if the original worked for the user's setup.
  double actualLotSizeForCalc = lotSize;
   if (lotModifier > 0) {
     actualLotSizeForCalc = lotSize / lotModifier; // Use the modified lot size for pip value calc
   }

   switch (accountType) {
   case 1: // micro (e.g., 0.1 displayed lot = 0.1 micro lots = 0.01 standard lots? Check broker)
     // Assuming 1 displayed micro lot (after modifier) = $0.10 per pip
     pipValue = 0.10 * actualLotSizeForCalc; // If actualLotSizeForCalc=0.1 -> $0.01/pip. If actualLotSizeForCalc=1 -> $0.10/pip. This seems correct for micro lots.
     break;
   case 2: // mini (e.g., 0.1 displayed lot = 0.1 mini lots = 0.1 standard lots)
     pipValue = 1.0 * actualLotSizeForCalc; // If actualLotSizeForCalc=0.1 -> $0.10/pip. If actualLotSizeForCalc=1 -> $1.00/pip. Correct for mini lots.
     break;
   case 3: // standard (e.g., 0.1 displayed lot = 0.1 standard lots)
     pipValue = 10.0 * actualLotSizeForCalc; // If actualLotSizeForCalc=0.1 -> $1.00/pip. If actualLotSizeForCalc=1 -> $10.00/pip. Correct for standard lots.
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
  if (ObjectFind(objname) < 0) { // Csak akkor hozzuk létre, ha még nem létezik
     ObjectCreate(objname, OBJ_LABEL, 0, 0, 0);
  }
  ObjectSetText(objname, objtext, fontsize, fontname, clr);
  ObjectSet(objname, OBJPROP_CORNER, Cor);
  ObjectSet(objname, OBJPROP_XDISTANCE, x);
  ObjectSet(objname, OBJPROP_YDISTANCE, y);
  ObjectSet(objname, OBJPROP_SELECTABLE, false); // Ne legyen kijelölhető
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
  // Mindig töröljük az előző objektumokat a tiszta állapot érdekében
  ObjectDelete(orderStatusRectName);
  ObjectDelete(orderStatusTextName);

  if (!ShowOrderStatusBox) {
    return; // Funkció kikapcsolva, objektumok törölve
  }

  int foundOrderSide = -1; // -1: nincs, 0: buy oldal, 1: sell oldal
  string orderTypeText = "";
  color backgroundColor;
  int orderTypeFound = -1; // A konkrét order típusa

  // Végigmegyünk az összes nyitott ÉS függő orderen
  for (int i = OrdersTotal() - 1; i >= 0; i--) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
       // Csak az aktuális szimbólumra vonatkozó ordereket nézzük
       if (OrderSymbol() == Symbol()) {
         int type = OrderType();
         // Buy oldal (Buy, Buy Limit, Buy Stop)
         if (type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP) {
           foundOrderSide = 0; // Buy oldal
           orderTypeFound = type;
           backgroundColor = clrForestGreen; // Zöld háttér
           break; // Megtaláltuk az első releváns ordert, kilépünk
         }
         // Sell oldal (Sell, Sell Limit, Sell Stop)
         else if (type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP) {
           foundOrderSide = 1; // Sell oldal
           orderTypeFound = type;
           backgroundColor = clrFireBrick; // Piros háttér
           break; // Megtaláltuk az első releváns ordert, kilépünk
         }
       }
    }
  }

  // Ha nem találtunk releváns ordert, kilépünk (objektumok már törölve)
  if (foundOrderSide == -1) {
    return;
  }

  // Lekérjük az order típusának szövegét
  orderTypeText = GetOrderTypeString(orderTypeFound);

  // --- Objektumok létrehozása ---
  // Hozzávetőleges méretek kiszámítása a szöveg alapján
  // Ezek a szorzók finomhangolhatók a kinézet javításához
  double approxCharWidth = OrderStatusFontSize * 0.6;
  double approxCharHeight = OrderStatusFontSize * 1.5;
  double paddingX = 10; // Vízszintes padding
  double paddingY = 6;  // Függőleges padding

  double rectWidth = StringLen(orderTypeText) * approxCharWidth + paddingX;
  double rectHeight = approxCharHeight + paddingY;

  // Pozíciók kiszámítása (felső közép)
  int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS); // Chart szélessége pixelben
  int rectX = chartWidth / 2 - (int)(rectWidth / 2);
  int rectY = 10; // Távolság a tetejétől
  int textX = chartWidth / 2;
  int textY = rectY + (int)(rectHeight / 2);

  // Háttér téglalap létrehozása
  ObjectCreate(orderStatusRectName, OBJ_RECTANGLE, 0, 0, 0);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_CORNER, 0); // Bal felső sarokhoz igazítás
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_XDISTANCE, rectX);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_YDISTANCE, rectY);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_XSIZE, (int)rectWidth);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_YSIZE, (int)rectHeight);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_COLOR, backgroundColor);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_BACK, true); // Háttérbe rajzolás
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_SELECTABLE, false);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_HIDDEN, false); // Láthatóvá tétel

  // Szöveg címke létrehozása
  ObjectCreate(orderStatusTextName, OBJ_LABEL, 0, 0, 0);
  ObjectSetString(0, orderStatusTextName, OBJPROP_FONT, fontName); // Betűtípus beállítása
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_FONTSIZE, OrderStatusFontSize); // Betűméret
  ObjectSetString(0, orderStatusTextName, OBJPROP_TEXT, orderTypeText); // Szöveg beállítása
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_COLOR, clrWhite); // Szöveg színe fehér
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_CORNER, 0); // Bal felső sarokhoz igazítás
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_XDISTANCE, textX);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_YDISTANCE, textY);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_ANCHOR, ANCHOR_CENTER); // Középre igazítás (vízszintesen és függőlegesen is az X/Y ponthoz)
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_BACK, false); // Előtérbe rajzolás
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_SELECTABLE, false);
  ObjectSetInteger(0, orderStatusTextName, OBJPROP_HIDDEN, false); // Láthatóvá tétel
}
//+------------------------------------------------------------------+

