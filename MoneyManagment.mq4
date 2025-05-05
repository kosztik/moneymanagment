#property copyright ""
#property link ""

#property indicator_chart_window
// #property indicator_buffers 2 // Felesleges, eltávolítva

// --- Input Parameters ---
extern string comment_Account = "--- Account Settings ---";
extern string comment_AccType = "Account Type: 1=Micro (1k), 2=Mini (10k), 3=Standard (100k)";
extern int accountType = 1; // 1: Micro (1000), 2: Mini (10000), 3: Standard (100000)
extern string comment_LotMod = "Lot Multiplier for specific brokers (e.g., XM Micro=10, otherwise=1)";
extern double lotModifier = 10.0; // Multiplier for display/input if needed
extern bool withLoan = false; // Use Equity instead of Balance

extern string comment_Risk = "--- Risk & SL ---";
extern int SLinPips = 400; // Stop Loss in Pips (e.g., 400 for 40.0 pips)
extern int riskPercent1 = 1;
extern int riskPercent2 = 5;
extern int riskPercent3 = 10;

extern string comment_Profit = "--- Profit Target ---";
extern int targetPips = 500; // Target profit in Pips (e.g., 500 for 50.0 pips)

extern string comment_Display = "--- Display Settings ---";
// Corner: 0=Top-Left, 1=Top-Right, 2=Bottom-Left, 3=Bottom-Right
extern int Position = 1; // Default to Top-Right corner
extern int tableOffsetX = 350; // Vízszintes távolság a saroktól (jobb saroknál jobbról balra) - Alapértelmezett visszaállítva 100-ra
extern color indicator_clr1 = Gold; // Header color
extern color indicator_clr2 = Aqua; // Data color
extern color positionColor = LightGreen; // Position info color

// Symbol Display
extern int symbolFontSize = 60;
extern color symbolColor = SlateGray;
extern string fontName = "Courier New";
extern int tableFontSize = 8;

// Formatting
extern int lotDigits = 2;    // Decimal places for Lot Size
extern int profitDigits = 2; // Decimal places for Profit
extern int profitWidth = 8;  // Width for Profit field alignment

// Refresh Rate
extern int refreshSeconds = 5; // Update frequency in seconds

// Order Status Box Parameters
extern string comment_OrderStatus = "--- Order Status Box ---";
extern bool ShowOrderStatusBox = true; // Mutassa az order státusz dobozt?
extern int OrderStatusFontSize = 30;   // Order státusz szöveg betűmérete

// --- Global Variables ---
// Object Names
string tableHeaderObjectName = "RiskTableHeader";
string tableRisk1ObjectName = "RiskTableRisk1";
string tableRisk2ObjectName = "RiskTableRisk2";
string tableRisk3ObjectName = "RiskTableRisk3";
string symbolObjectName = "RiskSymbolName";
string positionHeaderObjectName = "RiskPositionHeader";
string positionInfoObjectName = "RiskPositionInfo";
string orderStatusRectName = "OrderStatusRect";
string orderStatusTextName = "OrderStatusText";


// Optimization Variables
datetime lastUpdateTime = 0;
double lastAccountBalance = 0;
double lastAccountEquity = 0;
int lastOrdersTotal = 0;
string lastSymbol = "";
double lastTickValue = 0;
double lastPointSize = 0;
int lastDigits = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
  UpdateDisplay();
  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  ObjectDelete(0, tableHeaderObjectName);
  ObjectDelete(0, tableRisk1ObjectName);
  ObjectDelete(0, tableRisk2ObjectName);
  ObjectDelete(0, tableRisk3ObjectName);
  ObjectDelete(0, symbolObjectName);
  ObjectDelete(0, positionHeaderObjectName);
  ObjectDelete(0, positionInfoObjectName);
  ObjectDelete(0, orderStatusRectName);
  ObjectDelete(0, orderStatusTextName);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
    const int rates_total,
    const int prev_calculated,
    const datetime &time[],
    const double &open[],
    const double &high[],
    const double &low[],
    const double &close[],
    const long &tick_volume[],
    const long &volume[],
    const int &spread[]) {
  // Check if update is needed
  bool needUpdate = false;
  datetime currentTime = TimeCurrent();
  double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
  double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
  int currentOrdersTotal = OrdersTotal();
  string currentSymbol = Symbol();
  double currentTickValue = SymbolInfoDouble(currentSymbol, SYMBOL_TRADE_TICK_VALUE);
  double currentPointSize = SymbolInfoDouble(currentSymbol, SYMBOL_POINT);
  int currentDigits = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);

  if (currentTickValue == 0 || currentPointSize == 0 || currentDigits == 0) {
      currentTickValue = MarketInfo(currentSymbol, MODE_TICKVALUE);
      currentPointSize = MarketInfo(currentSymbol, MODE_POINT);
      currentDigits = (int)MarketInfo(currentSymbol, MODE_DIGITS);
  }

  if (currentTime >= lastUpdateTime + refreshSeconds) {
    needUpdate = true;
  }
  if (currentBalance != lastAccountBalance ||
      (withLoan && currentEquity != lastAccountEquity)) {
    needUpdate = true;
  }
  if (currentOrdersTotal != lastOrdersTotal) {
    needUpdate = true;
  }
  if (currentSymbol != lastSymbol || currentTickValue != lastTickValue ||
      currentPointSize != lastPointSize || currentDigits != lastDigits) {
    needUpdate = true;
  }

  if (needUpdate) {
    UpdateDisplay();
    lastUpdateTime = currentTime;
    lastAccountBalance = currentBalance;
    lastAccountEquity = currentEquity;
    lastOrdersTotal = currentOrdersTotal;
    lastSymbol = currentSymbol;
    lastTickValue = currentTickValue;
    lastPointSize = currentPointSize;
    lastDigits = currentDigits;
  }

  return (rates_total);
}

//+------------------------------------------------------------------+
//| Updates the display elements                                     |
//+------------------------------------------------------------------+
void UpdateDisplay() {
  double pipValuePerLot = CalculatePipValuePerLot();
  if (pipValuePerLot <= 0) {
    Print("Could not calculate Pip Value for ", Symbol(), ". Check MarketInfo/SymbolInfo.");
    ObjectDelete(0, tableRisk1ObjectName);
    ObjectDelete(0, tableRisk2ObjectName);
    ObjectDelete(0, tableRisk3ObjectName);
    ObjectDelete(0, positionHeaderObjectName);
    ObjectDelete(0, positionInfoObjectName);
    ObjectDelete(0, orderStatusRectName);
    ObjectDelete(0, orderStatusTextName);
    DisplayText(tableHeaderObjectName, "Error: Check Pip Value", fontName,
                tableFontSize, Red, tableOffsetX, 10, Position);
    return;
  }

  // --- Table Header ---
  string headerText = "Risk %  |  Lot Size  |  " +
                      DoubleToString(targetPips / GetPipMultiplier(), 1) +
                      " pips";
  DisplayText(tableHeaderObjectName, headerText, fontName, tableFontSize,
              indicator_clr1, tableOffsetX, 10, Position);

  // --- Calculate Lot Sizes and Profits ---
  double lot1 = LotCalculateWithRisk(riskPercent1, pipValuePerLot);
  double lot2 = LotCalculateWithRisk(riskPercent2, pipValuePerLot);
  double lot3 = LotCalculateWithRisk(riskPercent3, pipValuePerLot);

  double profit1Value = CalculateProfitForPips(lot1, pipValuePerLot);
  double profit2Value = CalculateProfitForPips(lot2, pipValuePerLot);
  double profit3Value = CalculateProfitForPips(lot3, pipValuePerLot);

  // --- Format Values ---
  string lot1Str = FormatDouble(lot1 * lotModifier, lotDigits, 8);
  string lot2Str = FormatDouble(lot2 * lotModifier, lotDigits, 8);
  string lot3Str = FormatDouble(lot3 * lotModifier, lotDigits, 8);

  string profit1Str = FormatDouble(profit1Value, profitDigits, profitWidth);
  string profit2Str = FormatDouble(profit2Value, profitDigits, profitWidth);
  string profit3Str = FormatDouble(profit3Value, profitDigits, profitWidth);

  // --- Display Table Rows ---
  string risk1Text = StringFormat("%5d%%  |  %s  |  $%s", riskPercent1,
                                  lot1Str, profit1Str);
  DisplayText(tableRisk1ObjectName, risk1Text, fontName, tableFontSize,
              indicator_clr2, tableOffsetX, 25, Position);

  string risk2Text = StringFormat("%5d%%  |  %s  |  $%s", riskPercent2,
                                  lot2Str, profit2Str);
  DisplayText(tableRisk2ObjectName, risk2Text, fontName, tableFontSize,
              indicator_clr2, tableOffsetX, 40, Position);

  string risk3Text = StringFormat("%5d%%  |  %s  |  $%s", riskPercent3,
                                  lot3Str, profit3Str);
  DisplayText(tableRisk3ObjectName, risk3Text, fontName, tableFontSize,
              indicator_clr2, tableOffsetX, 55, Position);

  // --- Display Position Info ---
  DisplayPositionInfo(pipValuePerLot);

  // --- Display Symbol Name ---
  string symbolName = Symbol();
  DisplayText(symbolObjectName, symbolName, fontName, symbolFontSize,
              symbolColor, 10, 10, 2); // Bal alsó sarok
  ObjectSetInteger(0, symbolObjectName, OBJPROP_BACK, true);

  // --- Display Order Status Box ---
  DisplayOrderStatusBox();
}

//+------------------------------------------------------------------+
//| Displays information about open positions                        |
//+------------------------------------------------------------------+
void DisplayPositionInfo(double pipValuePerLot) {
  string posHeaderText = "Current Positions  |  Lot Size  |  Est. Profit";
  DisplayText(positionHeaderObjectName, posHeaderText, fontName,
              tableFontSize, indicator_clr1, tableOffsetX, 75, Position);

  double totalLotStandard = 0;
  int openPositions = 0;

  for (int i = OrdersTotal() - 1; i >= 0; i--) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol() == Symbol() &&
          (OrderType() == OP_BUY || OrderType() == OP_SELL)) {
        double standardEquivalentLot = OrderLots();
        if (lotModifier != 0 && lotModifier != 1.0) {
           if (lotModifier > 0.00001) {
               standardEquivalentLot = OrderLots() / lotModifier;
           } else {
               Print("Warning: Invalid lotModifier (", lotModifier, ") in DisplayPositionInfo. Using 1.0.");
               standardEquivalentLot = OrderLots();
           }
        }
        totalLotStandard += standardEquivalentLot;
        openPositions++;
      }
    }
  }

  if (openPositions == 0) {
    DisplayText(positionInfoObjectName, "No open positions", fontName,
                tableFontSize, positionColor, tableOffsetX, 90, Position);
  } else {
    double totalEstimatedProfit =
        CalculateProfitForPips(totalLotStandard, pipValuePerLot);

    double displayLot = totalLotStandard;
     if (lotModifier != 0 && lotModifier != 1.0) {
        if (lotModifier > 0.00001) {
            displayLot = totalLotStandard * lotModifier;
        }
     }

    string totalLotStr = FormatDouble(displayLot, lotDigits, 8);
    string totalProfitStr = FormatDouble(totalEstimatedProfit, profitDigits, profitWidth);

    string posInfoText = StringFormat("%d positions  |  %s  |  $%s", openPositions, totalLotStr, totalProfitStr);
    DisplayText(positionInfoObjectName, posInfoText, fontName, tableFontSize,
                positionColor, tableOffsetX, 90, Position);
  }
}

//+------------------------------------------------------------------+
//| Calculates Lot Size based on risk %                              |
//+------------------------------------------------------------------+
double LotCalculateWithRisk(int riskPercent, double pipValuePerLot) {
  double accountMoney = withLoan ? AccountInfoDouble(ACCOUNT_EQUITY)
                                 : AccountInfoDouble(ACCOUNT_BALANCE);
  if (riskPercent < 0) riskPercent = 0;
  double moneyToRisk = (accountMoney * riskPercent) / 100.0;

  if (pipValuePerLot <= 0) {
     Print("Cannot calculate lot size. Pip Value per Lot is zero or negative: ", pipValuePerLot);
     return(0.0);
  }
  if (SLinPips <= 0) {
     Print("Cannot calculate lot size. SLinPips must be positive: ", SLinPips);
     return(0.0);
  }

  double pipMultiplier = GetPipMultiplier();
  if (pipMultiplier <= 0) {
      Print("Cannot calculate lot size. Invalid Pip Multiplier.");
      return(0.0);
  }

  double lossPerStandardLot = (SLinPips / pipMultiplier) * pipValuePerLot;

  if (lossPerStandardLot <= 0) {
    Print("Cannot calculate lot size. Loss per standard lot is zero or negative: ", lossPerStandardLot, " (SLinPips=", SLinPips, ", pipMultiplier=", pipMultiplier, ", pipValuePerLot=", pipValuePerLot, ")");
    return (0.0);
  }

  double calculatedLotStandard = moneyToRisk / lossPerStandardLot;

  string symbol = Symbol();
  double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
  double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   if (minLot == 0 && maxLot == 0 && lotStep == 0) {
      minLot = MarketInfo(symbol, MODE_MINLOT);
      maxLot = MarketInfo(symbol, MODE_MAXLOT);
      lotStep = MarketInfo(symbol, MODE_LOTSTEP);
   }

  if (minLot < 0) minLot = 0;
  if (maxLot <= 0) maxLot = 10000;
  if (lotStep <= 0) lotStep = 0.01;

  calculatedLotStandard = MathMax(minLot, calculatedLotStandard);
  calculatedLotStandard = MathMin(maxLot, calculatedLotStandard);

  if (lotStep > 0) {
      int step_digits = 0;
      double temp_step = lotStep;
      // Kicsit pontosabb tizedesjegy számítás a lépésközhöz
      while(MathAbs(temp_step * MathPow(10, step_digits) - MathRound(temp_step * MathPow(10, step_digits))) > 0.00000001 && step_digits < 8) {
         step_digits++;
      }
      calculatedLotStandard = NormalizeDouble(MathFloor(calculatedLotStandard / lotStep + 0.0000001) * lotStep, step_digits);
  }

   int lot_digits_norm = 0;
   double temp_step_norm = lotStep;
    while(MathAbs(temp_step_norm * MathPow(10, lot_digits_norm)) - MathRound(temp_step_norm * MathPow(10, lot_digits_norm)) > 0.00000001 && lot_digits_norm < 8) {
       lot_digits_norm++;
    }

  return (NormalizeDouble(calculatedLotStandard, lot_digits_norm));
}


//+------------------------------------------------------------------+
//| Calculates Profit for a given Lot Size and Target Pips           |
//+------------------------------------------------------------------+
double CalculateProfitForPips(double standardLotSize, double pipValuePerLot) {
  if (pipValuePerLot <= 0 || standardLotSize < 0) {
    return (0.0);
  }
  if (targetPips == 0) return(0.0);

  double pipMultiplier = GetPipMultiplier();
   if (pipMultiplier <= 0) {
      Print("Cannot calculate profit. Invalid Pip Multiplier.");
      return(0.0);
  }

   double profit = standardLotSize * pipValuePerLot * (targetPips / pipMultiplier);

  return (NormalizeDouble(profit, profitDigits));
}

//+------------------------------------------------------------------+
//| Calculates Pip Value per Standard Lot in Account Currency        |
//+------------------------------------------------------------------+
double CalculatePipValuePerLot() {
  string symbol = Symbol();
  double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
  double pointSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

  if (tickValue == 0 || pointSize == 0 || digits == 0) {
      tickValue = MarketInfo(symbol, MODE_TICKVALUE);
      pointSize = MarketInfo(symbol, MODE_POINT);
      digits = (int)MarketInfo(symbol, MODE_DIGITS);
  }

  if (pointSize == 0) {
      Print("Error: Point size is zero for ", symbol, ". Cannot calculate Pip Value.");
      return 0.0;
  }
  if (tickValue == 0) {
       Print("Error: Tick value is zero for ", symbol, ". Cannot calculate Pip Value.");
       return 0.0;
  }

  double pipSize = pointSize;
  if (digits == 5 || digits == 3) {
    pipSize = 10 * pointSize;
  } else if (digits == 4 || digits == 2 || digits == 1 || digits == 0) {
     pipSize = pointSize;
  } else {
     Print("Warning: Unexpected digits (", digits, ") in CalculatePipValuePerLot. Assuming 1 pip = 1 point.");
     pipSize = pointSize;
  }

  double pipValuePerStandardLot = (tickValue / pointSize) * pipSize;

  if(pipValuePerStandardLot < 0) pipValuePerStandardLot = 0;

  return pipValuePerStandardLot;
}


//+------------------------------------------------------------------+
//| Gets the multiplier for converting Pips input to points          |
//+------------------------------------------------------------------+
double GetPipMultiplier() {
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    if (digits == 0) {
        digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
    }

    if (digits == 5 || digits == 3) {
        return 10.0;
    } else if (digits == 4 || digits == 2 || digits == 1 || digits == 0) {
        return 1.0;
    } else {
        Print("Warning: Unexpected number of digits (", digits, ") for ", Symbol(), ". Assuming 1 pip = 1 point.");
        return 1.0;
    }
}


//+------------------------------------------------------------------+
//| Formats a double value with padding                              |
//+------------------------------------------------------------------+
string FormatDouble(double value, int digits, int width) {
  string result = DoubleToString(value, digits);
  int currentLength = StringLen(result);
  if (currentLength < width) {
    string padding = "";
    for (int i = 0; i < width - currentLength; i++) {
      padding = padding + " ";
    }
    result = padding + result;
  }
  return result;
}

//+------------------------------------------------------------------+
//| Displays text on the chart                                       |
//+------------------------------------------------------------------+
void DisplayText(string objname, string objtext, string fontname, int fontsize,
                 color clr, int x, int y, int corner) {
  if (ObjectFind(0, objname) < 0) {
    if (!ObjectCreate(0, objname, OBJ_LABEL, 0, 0, 0)) {
        Print("Error creating label '", objname, "': ", GetLastError());
        return;
    }
    ObjectSetString(0, objname, OBJPROP_FONT, fontname);
    ObjectSetInteger(0, objname, OBJPROP_FONTSIZE, fontsize);
    ObjectSetInteger(0, objname, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, objname, OBJPROP_SELECTED, false);
  }

  ObjectSetString(0, objname, OBJPROP_TEXT, objtext);
  ObjectSetInteger(0, objname, OBJPROP_COLOR, clr);
  ObjectSetInteger(0, objname, OBJPROP_CORNER, corner);
  ObjectSetInteger(0, objname, OBJPROP_XDISTANCE, x);
  ObjectSetInteger(0, objname, OBJPROP_YDISTANCE, y);
}

//+------------------------------------------------------------------+
//| Gets order type as string                                        |
//+------------------------------------------------------------------+
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
//| Displays the order status box                                    |
//+------------------------------------------------------------------+
void DisplayOrderStatusBox() {
  ObjectDelete(0, orderStatusRectName);
  ObjectDelete(0, orderStatusTextName);

  if (!ShowOrderStatusBox) {
    return;
  }

  int foundOrderSide = -1;
  string orderTypeText = "";
  color backgroundColor;
  int orderTypeFound = -1;

  for (int i = OrdersTotal() - 1; i >= 0; i--) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
       if (OrderSymbol() == Symbol()) {
         int type = OrderType();
         if (type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP) {
           foundOrderSide = 0;
           orderTypeFound = type;
           backgroundColor = clrForestGreen;
           break;
         }
         else if (type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP) {
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

  double approxCharWidth = OrderStatusFontSize * 0.6;
  double approxCharHeight = OrderStatusFontSize * 1.5;
  double paddingX = 10;
  double paddingY = 6;

  double rectWidth = StringLen(orderTypeText) * approxCharWidth + paddingX * 2;
  double rectHeight = approxCharHeight + paddingY * 2;

  long chartWidthLong = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
  if (chartWidthLong <= 0) {
      Print("Error: Could not get chart width for Order Status Box.");
      return;
  }
  int chartWidth = (int)chartWidthLong;

  int rectX = chartWidth / 2 - (int)(rectWidth / 2);
  int rectY = 10;
  int textX = chartWidth / 2;
  int textY = rectY + (int)(rectHeight / 2);

  if (!ObjectCreate(0, orderStatusRectName, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
      Print("Error creating rectangle label '", orderStatusRectName, "': ", GetLastError());
      return;
  }
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_CORNER, 0);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_XDISTANCE, rectX);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_YDISTANCE, rectY);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_XSIZE, (int)rectWidth);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_YSIZE, (int)rectHeight);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_COLOR, backgroundColor);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_BGCOLOR, backgroundColor);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_BACK, true);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_SELECTABLE, false);
  ObjectSetInteger(0, orderStatusRectName, OBJPROP_HIDDEN, false);

  if (!ObjectCreate(0, orderStatusTextName, OBJ_LABEL, 0, 0, 0)) {
       Print("Error creating label '", orderStatusTextName, "': ", GetLastError());
       ObjectDelete(0, orderStatusRectName);
       return;
  }
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

// Felesleges függvény eltávolítva:
// double LotCalculate() { ... }
