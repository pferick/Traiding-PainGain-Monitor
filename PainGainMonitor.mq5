//+------------------------------------------------------------------+
//|                                              PainGainMonitor.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- Variables Globales de Estado de Volatilidad (MAs) ---
bool   g_ma_is_red_extended     = false; // True si estamos en zona Roja (Sobre-extensión)
bool   g_ma_is_green_compressed = false; // True si estamos en zona Verde (Compresión)
int    g_ma_trend_direction     = 0;     // 1 = Alcista (20>200), -1 = Bajista (20<200)

//--- Inputs de Configuración ---

//--- Análisis de Tendencia ---
input string separador_trend="----------------"; // Trend Analysis Setup
input int AnnualTimeOffsetDays = 500; // Offset días líneas anuales
input int SemesterTimeOffsetDays = 15; // Offset días líneas semestrales

//--- Configuración RSI ---
input string separador_rsi="----------------"; // RSI Setup
input int RsiPeriod_D1 = 10;
input int RsiPeriod_H4 = 10;
input int RsiPeriod_H1 = 10;
input int RsiPeriod_M30 = 36;
input int RsiPeriod_M15 = 36;
input int RsiPeriod_M5 = 36;
input int RsiPeriod_M1 = 110;

//--- Configuración Volatilidad (ATR) ---
input string separador_vol="----------------"; // Volatility Inputs
input int ATR_Period = 14;

//--- Configuración Telegram ---
input string separador_tele="----------------"; // Telegram Configuration

//--- Bot 1 (Notificaciones Generales)
input bool EnableTelegramBot1 = false;
input string TelegramBotToken1 = ""; // Enter Token Here
input string TelegramChatID1 = "";   // Enter Chat ID Here

//--- Bot 2 (Alertas RSI)
input bool EnableTelegramBot2 = true;
input string TelegramBotToken2 = ""; // Enter Token Here
input string TelegramChatID2 = "";   // Enter Chat ID Here

//--- Bot 3 (Otras Alertas)
input bool EnableTelegramBot3 = false;
input string TelegramBotToken3 = ""; // Enter Token Here
input string TelegramChatID3 = "";   // Enter Chat ID Here

//--- Bot 4 (Monitor)
input bool EnableTelegramBot4 = false;
input string TelegramBotToken4 = ""; // Enter Token Here
input string TelegramChatID4 = "";   // Enter Chat ID Here

//--- Logging ---
input string separador_logs="----------------"; // Logging Inputs
input bool EnableFileLogs = true; // Guardar CSV con métricas

//--- Custom RGB Color Macro
#define RGB(r,g,b) ((color)((r) | ((g) << 8) | ((b) << 16)))

//--- Definiciones de Objetos Gráficos (Panel y Líneas) ---
#define BG_RECT "BackgroundRectangle"

// Etiquetas de Análisis (Columna 1)
#define LABEL_IMPULSE_STRENGTH "ImpulseStrengthLabel"
#define LABEL_IMPULSE_STRENGTH_PREV "ImpulseStrengthPrevLabel"
#define LABEL_PERCENT_FROM_HIGH "PercentFromHighLabel"
#define LABEL_PERCENT_FROM_LOW "PercentFromLowLabel"
#define LABEL_AVG_CANDLE_SIZE_S1 "AvgCandleSizeS1Label"
#define LABEL_AVG_CANDLE_SIZE_S2 "AvgCandleSizeS2Label"
#define LABEL_MA_DIST_CURR "MaDistCurrLabel"
#define LABEL_MA_DIST_MAX "MaDistMaxLabel"
#define LABEL_MA_DIST_MIN "MaDistMinLabel"
#define LABEL_MA_DIST_AVG "MaDistAvgLabel"

// Separadores
#define LABEL_SEPARATOR_1 "Separator1Label"
#define LABEL_SEPARATOR_2 "Separator2Label"
#define LABEL_SEPARATOR_MA "SeparatorMALabel"

// Trendlines
#define TRENDLINE_HIGH "DailyHighTrendline"
#define TRENDLINE_LOW "DailyLowTrendline"
#define TRENDLINE_HIGH_PREV "DailyHighTrendlinePrev"
#define TRENDLINE_LOW_PREV "DailyLowTrendlinePrev"
#define TRENDLINE_AVG "AvgPriceTrendline"
#define TRENDLINE_AVG_PREV "AvgPriceTrendlinePrev"
#define TRENDLINE_HIGH_CURR_S1 "DailyHighTrendlineCurrS1"
#define TRENDLINE_LOW_CURR_S1 "DailyLowTrendlineCurrS1"
#define TRENDLINE_HIGH_CURR_S2 "DailyHighTrendlineCurrS2"
#define TRENDLINE_LOW_CURR_S2 "DailyLowTrendlineCurrS2"
#define TRENDLINE_HIGH_PREV_S1 "DailyHighTrendlinePrevS1"
#define TRENDLINE_LOW_PREV_S1 "DailyLowTrendlinePrevS1"
#define TRENDLINE_HIGH_PREV_S2 "DailyHighTrendlinePrevS2"
#define TRENDLINE_LOW_PREV_S2 "DailyLowTrendlinePrevS2"
#define TEXT_HIGH_CURR_S1 "TextHighCurrS1"
#define TEXT_LOW_CURR_S1 "TextLowCurrS1"
#define TEXT_HIGH_CURR_S2 "TextHighCurrS2"
#define TEXT_LOW_CURR_S2 "TextLowCurrS2"
#define TEXT_HIGH_PREV_S1 "TextHighPrevS1"
#define TEXT_LOW_PREV_S1 "TextLowPrevS1"
#define TEXT_HIGH_PREV_S2 "TextHighPrevS2"
#define TEXT_LOW_PREV_S2 "TextLowPrevS2"
#define IMPULSE_HIGH_LINE "ImpulseHighLine"
#define IMPULSE_LOW_LINE "ImpulseLowLine"

// RSI Levels & Labels (Columna 2)
//--- RSI Line Objects Definitions
#define RSI_HIGH_LEVEL_LINE "RsiHighLevelLine"       // Top (Gold Solid)
#define RSI_LOW_LEVEL_LINE "RsiLowLevelLine"         // Bottom (Gold Solid)
#define RSI_MID_LEVEL_LINE "RsiMidLevelLine"         // Mid (Orange Solid)

#define RSI_SECOND_HIGH_LEVEL_LINE "RsiSecondHighLevelLine" // Mid-Top (Yellow Dotted)
#define RSI_SECOND_LOW_LEVEL_LINE "RsiSecondLowLevelLine"   // Mid-Bottom (Yellow Dotted)

#define RSI_UPPER_QUARTILE_LINE "RsiUpperQuartileLine"      // React-Top (Green Dotted)
#define RSI_LOWER_QUARTILE_LINE "RsiLowerQuartileLine"      // React-Bottom (Green Dotted)

#define RSI_LOW_TOP_LINE "RsiLowTopLine"             // Low-Top (Red Dotted)
#define RSI_LOW_BOTTOM_LINE "RsiLowBottomLine"       // Low-Bottom (Red Dotted)

// Panel RSI Labels
#define LABEL_RSI_TOP_STATUS "RsiTopStatusLabel"
#define LABEL_RSI_BOTTOM_STATUS "RsiBottomStatusLabel"
#define LABEL_RSI_MID_STATUS "RsiMidStatusLabel"
#define LABEL_RSI_MID_TOP_STATUS "RsiMidTopStatusLabel"
#define LABEL_RSI_MID_BOTTOM_STATUS "RsiMidBottomStatusLabel"
#define LABEL_REACT_TOP_STATUS "ReactTopStatusLabel"
#define LABEL_REACT_BOTTOM_STATUS "ReactBottomStatusLabel"
#define LABEL_RSI_LOW_TOP_STATUS "RsiLowTopStatusLabel"
#define LABEL_RSI_LOW_BOTTOM_STATUS "RsiLowBottomStatusLabel"
#define LABEL_RSI_SEPARATOR_1 "RsiSeparator1Label"
#define LABEL_RSI_SEPARATOR_2 "RsiSeparator2Label"

// Botones de Utilidad
#define BUTTON_SEND_SCREENSHOT "SendScreenshotButton"
#define BUTTON_CLEANUP_FILES "CleanupFilesButton"
#define BUTTON_TEST_BOT2 "TestBot2Button"

//--- Variables Globales ---
datetime lastDailyUpdate = 0;
double yearlyHigh = 0;
double yearlyLow = 0;
double previousYearImpulseStrength = 0.0;
int rsi_handle = INVALID_HANDLE;
int atr_handle = INVALID_HANDLE;
int ma200_handle = INVALID_HANDLE;
int ma20_handle  = INVALID_HANDLE;

// RSI Levels dinámicos
double rsi_top_level = 0;
double rsi_bottom_level = 0;
double rsi_mid_top_level = 0;
double rsi_mid_bottom_level = 0;
double rsi_react_top_level = 0;
double rsi_react_bottom_level = 0;
double rsi_low_top_level = 0;
double rsi_low_bottom_level = 0;
double rsi_mid_level = 0;

// Flags de Alerta RSI
bool alert_sent_rsi_top = false;
bool alert_sent_rsi_bottom = false;
bool alert_sent_rsi_mid = false;
bool alert_sent_mid_top = false;
bool alert_sent_mid_bottom = false;
bool alert_sent_react_top = false;
bool alert_sent_react_bottom = false;
bool alert_sent_low_top = false;
bool alert_sent_low_bottom = false;

datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Genera nombre de archivo log                                     |
//+------------------------------------------------------------------+
string GetLogFileName(string prefix)
{
   return prefix + _Symbol + "_" + EnumToString(_Period) + ".csv";
}

//+------------------------------------------------------------------+
//| Initialization function                                          |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Inicializar Log de Métricas (Snapshot) ---
   if(EnableFileLogs)
   {
       int handle_ss = FileOpen(GetLogFileName("analysis_log_"), FILE_READ | FILE_WRITE | FILE_CSV | FILE_SHARE_READ);
       if(handle_ss != INVALID_HANDLE)
       {
           if(FileSize(handle_ss) == 0)
           {
               FileWriteString(handle_ss, "SYMBOL," + _Symbol + "\n");
               FileWriteString(handle_ss, "TIMEFRAME," + EnumToString(_Period) + "\n");
               FileWriteString(handle_ss, "Timestamp,RSI,ATR,MA_Dist_Percent,Trend_Dir\n");
           }
           FileClose(handle_ss);
       }
   }

   // --- Configuración Visual del Gráfico ---
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, RGB(46,0,79));
   ChartSetInteger(0, CHART_COLOR_GRID, clrDarkSlateGray);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrLime);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrMediumSeaGreen);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrHotPink);
   ChartSetInteger(0, CHART_SHOW_VOLUMES, false);
   ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);
   ChartRedraw(0);

   EventSetTimer(5); // Timer cada 5 segundos

   // --- Crear Panel de Fondo ---
   // Reducimos el ancho ya que quitamos columnas de trading
   ObjectCreate(0, BG_RECT, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, BG_RECT, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, BG_RECT, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, BG_RECT, OBJPROP_XSIZE, 580); // Ancho reducido
   ObjectSetInteger(0, BG_RECT, OBJPROP_YSIZE, 370);
   ObjectSetInteger(0, BG_RECT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, BG_RECT, OBJPROP_BGCOLOR, RGB(33,33,33));
   ObjectSetInteger(0, BG_RECT, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, BG_RECT, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, BG_RECT, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, BG_RECT, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, BG_RECT, OBJPROP_BACK, false);

   // --- Crear Etiquetas de Información ---
   int y_pos = 35;
   int x_pos = 20;
   int line_height = 15;
   string font_name = "Courier New";
   int font_size = 10;
   string separator_text = "-------------------------------------";

   #define CREATE_LABEL(name) \
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0); \
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x_pos); \
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y_pos); \
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); \
   ObjectSetString(0, name, OBJPROP_FONT, font_name); \
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size); \
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite); \
   ObjectSetInteger(0, name, OBJPROP_BACK, false); \
   y_pos += line_height;

   #define CREATE_SEPARATOR(name) \
   CREATE_LABEL(name) \
   ObjectSetString(0, name, OBJPROP_TEXT, separator_text);

   // --- Columna 1: Análisis de Mercado e Impulso ---
   CREATE_LABEL(LABEL_IMPULSE_STRENGTH)
   CREATE_LABEL(LABEL_IMPULSE_STRENGTH_PREV)
   CREATE_SEPARATOR(LABEL_SEPARATOR_1)
   CREATE_LABEL(LABEL_PERCENT_FROM_HIGH)
   CREATE_LABEL(LABEL_PERCENT_FROM_LOW)
   CREATE_SEPARATOR(LABEL_SEPARATOR_2)
   CREATE_LABEL(LABEL_AVG_CANDLE_SIZE_S1)
   CREATE_LABEL(LABEL_AVG_CANDLE_SIZE_S2)

   // --- Sección MA Distancia ---
   CREATE_SEPARATOR(LABEL_SEPARATOR_MA)
   ObjectSetString(0, LABEL_SEPARATOR_MA, OBJPROP_TEXT, "--- Distancia MA200 vs MA20 ---");
   CREATE_LABEL(LABEL_MA_DIST_CURR)
   CREATE_LABEL(LABEL_MA_DIST_MAX)
   CREATE_LABEL(LABEL_MA_DIST_MIN)
   CREATE_LABEL(LABEL_MA_DIST_AVG)

   #undef CREATE_LABEL
   #undef CREATE_SEPARATOR

   // --- Columna 2: Estado RSI ---
   y_pos = 35;
   x_pos = 300;

   #define CREATE_RSI_LABEL(name) \
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0); \
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x_pos); \
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y_pos); \
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); \
   ObjectSetString(0, name, OBJPROP_FONT, "Courier New"); \
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10); \
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite); \
   ObjectSetInteger(0, name, OBJPROP_BACK, false); \
   y_pos += line_height;
   
   #define CREATE_RSI_SEPARATOR(name) \
   CREATE_RSI_LABEL(name) \
   ObjectSetString(0, name, OBJPROP_TEXT, "-------------------------");

   // RSI Labels
   CREATE_RSI_LABEL(LABEL_RSI_TOP_STATUS)
   CREATE_RSI_LABEL(LABEL_REACT_TOP_STATUS)
   CREATE_RSI_LABEL(LABEL_RSI_MID_TOP_STATUS)
   CREATE_RSI_LABEL(LABEL_RSI_LOW_TOP_STATUS)
   CREATE_RSI_SEPARATOR(LABEL_RSI_SEPARATOR_1)
   CREATE_RSI_LABEL(LABEL_RSI_MID_STATUS)
   CREATE_RSI_SEPARATOR(LABEL_RSI_SEPARATOR_2)
   CREATE_RSI_LABEL(LABEL_RSI_LOW_BOTTOM_STATUS)
   CREATE_RSI_LABEL(LABEL_RSI_MID_BOTTOM_STATUS)
   CREATE_RSI_LABEL(LABEL_REACT_BOTTOM_STATUS)
   CREATE_RSI_LABEL(LABEL_RSI_BOTTOM_STATUS)

   #undef CREATE_RSI_LABEL
   #undef CREATE_RSI_SEPARATOR

   // --- Botones de Utilidad (Capturas y Test) ---
   // Botón Screenshot
   ObjectCreate(0, BUTTON_SEND_SCREENSHOT, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_YDISTANCE, 400);
   ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_XSIZE, 120);
   ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_YSIZE, 20);
   ObjectSetString(0, BUTTON_SEND_SCREENSHOT, OBJPROP_TEXT, "Enviar Screenshot");
   ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_BGCOLOR, clrRoyalBlue);
   ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_COLOR, clrWhite);

   // Botón Cleanup
   ObjectCreate(0, BUTTON_CLEANUP_FILES, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_XDISTANCE, 140);
   ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_YDISTANCE, 400);
   ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_XSIZE, 120);
   ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_YSIZE, 20);
   ObjectSetString(0, BUTTON_CLEANUP_FILES, OBJPROP_TEXT, "Limpiar Archivos");
   ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_BGCOLOR, clrDimGray);
   ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_COLOR, clrWhite);

   // Botón Test Bot
   ObjectCreate(0, BUTTON_TEST_BOT2, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_XDISTANCE, 270);
   ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_YDISTANCE, 400);
   ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_XSIZE, 120);
   ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_YSIZE, 20);
   ObjectSetString(0, BUTTON_TEST_BOT2, OBJPROP_TEXT, "Test Telegram");
   ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_BGCOLOR, clrDimGray);
   ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_COLOR, clrWhite);

   // --- Crear Handles de Indicadores ---
   int rsi_period = GetRsiPeriodForTimeframe(_Period);
   rsi_handle = iRSI(_Symbol, _Period, rsi_period, PRICE_CLOSE);
   if(rsi_handle == INVALID_HANDLE) { return(INIT_FAILED); }

   atr_handle = iATR(_Symbol, _Period, ATR_Period);
   if(atr_handle == INVALID_HANDLE) { return(INIT_FAILED); }

   ma200_handle = iMA(_Symbol, _Period, 200, 0, MODE_SMA, PRICE_CLOSE);
   ma20_handle  = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE);
   if(ma200_handle == INVALID_HANDLE || ma20_handle == INVALID_HANDLE) { return(INIT_FAILED); }

   if(!ChartIndicatorAdd(0, 1, rsi_handle)) { IndicatorRelease(rsi_handle); return(INIT_FAILED); }

   UpdateDailyData();

   string init_message = "AutoSynAnalyzer initialized on " + _Symbol + ", " + EnumToString(_Period) + ".";
   if(EnableTelegramBot1) SendTelegramMessage(init_message, 1);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Deinitialization function                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   RemoveRsiIndicator();

   if(rsi_handle != INVALID_HANDLE) IndicatorRelease(rsi_handle);
   if(atr_handle != INVALID_HANDLE) IndicatorRelease(atr_handle);
   if(ma200_handle != INVALID_HANDLE) IndicatorRelease(ma200_handle);
   if(ma20_handle != INVALID_HANDLE) IndicatorRelease(ma20_handle);

   ObjectDelete(0, BG_RECT);
   // Borrar Etiquetas de Análisis
   ObjectDelete(0, LABEL_IMPULSE_STRENGTH);
   ObjectDelete(0, LABEL_IMPULSE_STRENGTH_PREV);
   ObjectDelete(0, LABEL_PERCENT_FROM_HIGH);
   ObjectDelete(0, LABEL_PERCENT_FROM_LOW);
   ObjectDelete(0, LABEL_AVG_CANDLE_SIZE_S1);
   ObjectDelete(0, LABEL_AVG_CANDLE_SIZE_S2);
   ObjectDelete(0, LABEL_MA_DIST_CURR);
   ObjectDelete(0, LABEL_MA_DIST_MAX);
   ObjectDelete(0, LABEL_MA_DIST_MIN);
   ObjectDelete(0, LABEL_MA_DIST_AVG);
   ObjectDelete(0, LABEL_SEPARATOR_1);
   ObjectDelete(0, LABEL_SEPARATOR_2);
   ObjectDelete(0, LABEL_SEPARATOR_MA);

   // Borrar Etiquetas RSI
   ObjectDelete(0, LABEL_RSI_TOP_STATUS);
   ObjectDelete(0, LABEL_RSI_BOTTOM_STATUS);
   ObjectDelete(0, LABEL_RSI_MID_STATUS);
   ObjectDelete(0, LABEL_RSI_MID_TOP_STATUS);
   ObjectDelete(0, LABEL_RSI_MID_BOTTOM_STATUS);
   ObjectDelete(0, LABEL_REACT_TOP_STATUS);
   ObjectDelete(0, LABEL_REACT_BOTTOM_STATUS);
   ObjectDelete(0, LABEL_RSI_LOW_TOP_STATUS);
   ObjectDelete(0, LABEL_RSI_LOW_BOTTOM_STATUS);
   ObjectDelete(0, LABEL_RSI_SEPARATOR_1);
   ObjectDelete(0, LABEL_RSI_SEPARATOR_2);

   // Borrar Líneas de Tendencia e Impulso
   ObjectDelete(0, TRENDLINE_HIGH);
   ObjectDelete(0, TRENDLINE_LOW);
   ObjectDelete(0, TRENDLINE_HIGH_PREV);
   ObjectDelete(0, TRENDLINE_LOW_PREV);
   ObjectDelete(0, TRENDLINE_AVG);
   ObjectDelete(0, TRENDLINE_AVG_PREV);
   ObjectDelete(0, TRENDLINE_HIGH_CURR_S1);
   ObjectDelete(0, TRENDLINE_LOW_CURR_S1);
   ObjectDelete(0, TRENDLINE_HIGH_CURR_S2);
   ObjectDelete(0, TRENDLINE_LOW_CURR_S2);
   ObjectDelete(0, TRENDLINE_HIGH_PREV_S1);
   ObjectDelete(0, TRENDLINE_LOW_PREV_S1);
   ObjectDelete(0, TRENDLINE_HIGH_PREV_S2);
   ObjectDelete(0, TRENDLINE_LOW_PREV_S2);
   ObjectDelete(0, TEXT_HIGH_CURR_S1);
   ObjectDelete(0, TEXT_LOW_CURR_S1);
   ObjectDelete(0, TEXT_HIGH_CURR_S2);
   ObjectDelete(0, TEXT_LOW_CURR_S2);
   ObjectDelete(0, TEXT_HIGH_PREV_S1);
   ObjectDelete(0, TEXT_LOW_PREV_S1);
   ObjectDelete(0, TEXT_HIGH_PREV_S2);
   ObjectDelete(0, TEXT_LOW_PREV_S2);
   ObjectDelete(0, IMPULSE_HIGH_LINE);
   ObjectDelete(0, IMPULSE_LOW_LINE);

   // Borrar Botones
   ObjectDelete(0, BUTTON_SEND_SCREENSHOT);
   ObjectDelete(0, BUTTON_CLEANUP_FILES);
   ObjectDelete(0, BUTTON_TEST_BOT2);

   DeleteAllRsiObjects();
}

//+------------------------------------------------------------------+
//| OnTick (Solo para procesos rápidos de señal, no trading)         |
//+------------------------------------------------------------------+
void OnTick()
{
   // No hay lógica de trading aquí.
   // Las alertas RSI se manejan en OnTimer o al cierre de vela.
}

//+------------------------------------------------------------------+
//| Timer function: Mantenimiento y GUI                              |
//+------------------------------------------------------------------+
void OnTimer()
{
   // 1. Cálculos Históricos (MA Distancia)
   UpdateMADistanceMetrics();

   // 2. Actualización del Panel Visual
   UpdateInfo();

   // 3. Notificaciones y Logs
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime > lastBarTime)
   {
      lastBarTime = currentBarTime;
      CheckRsiAlerts();
      LogSnapshot();
   }

   // 4. Actualización Diaria (Trendlines)
   datetime now = TimeCurrent();
   if((int)(now / 86400) != (int)(lastDailyUpdate / 86400))
   {
      UpdateDailyData();
      lastDailyUpdate = now;
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update information function (Solo Análisis)                      |
//+------------------------------------------------------------------+
void UpdateInfo()
{
    UpdateRsiStatusLabels();

    MqlTick last_tick;
    if(SymbolInfoTick(_Symbol, last_tick))
    {
        double currentPrice = last_tick.bid;
        if(yearlyHigh > 0)
        {
            double percentFromHigh = ((currentPrice - yearlyHigh) / yearlyHigh) * 100;
            string highText = "Distancia Max Anual: " + StringFormat("%.2f%%", percentFromHigh);
            ObjectSetString(0, LABEL_PERCENT_FROM_HIGH, OBJPROP_TEXT, highText);
        }
        if(yearlyLow > 0)
        {
            double percentFromLow = ((currentPrice - yearlyLow) / yearlyLow) * 100;
            string lowText = "Distancia Min Anual: " + StringFormat("%.2f%%", percentFromLow);
            ObjectSetString(0, LABEL_PERCENT_FROM_LOW, OBJPROP_TEXT, lowText);
        }
    }
}

//+------------------------------------------------------------------+
//| Telegram Functions                                               |
//+------------------------------------------------------------------+
void SendTelegramMessage(string message, int bot_index)
{
   string bot_token = "";
   string chat_id = "";
   bool bot_enabled = false;

   switch(bot_index)
   {
      case 1: bot_enabled = EnableTelegramBot1; bot_token = TelegramBotToken1; chat_id = TelegramChatID1; break;
      case 2: bot_enabled = EnableTelegramBot2; bot_token = TelegramBotToken2; chat_id = TelegramChatID2; break;
      case 3: bot_enabled = EnableTelegramBot3; bot_token = TelegramBotToken3; chat_id = TelegramChatID3; break;
      case 4: bot_enabled = EnableTelegramBot4; bot_token = TelegramBotToken4; chat_id = TelegramChatID4; break;
   }

   if(!bot_enabled || bot_token == "" || chat_id == "") return;

   string url = "https://api.telegram.org/bot" + bot_token + "/sendMessage";
   string headers = "Content-Type: application/json";
   char post_data[];
   uchar result_data[];
   string result_headers;

   string escaped_message = message;
   StringReplace(escaped_message, "\\", "\\\\");
   StringReplace(escaped_message, "\"", "\\\"");
   StringReplace(escaped_message, "\r", "\\r");
   StringReplace(escaped_message, "\n", "\\n");

   string json_payload = "{\"chat_id\":\"" + chat_id + "\",\"text\":\"" + escaped_message + "\"}";
   StringToCharArray(json_payload, post_data, 0, StringLen(json_payload), CP_UTF8);

   WebRequest("POST", url, headers, 5000, post_data, result_data, result_headers);
}

void SendTelegramScreenshot(int bot_index, string file_name)
{
   string bot_token = "";
   string chat_id = "";
   bool bot_enabled = false;

   switch(bot_index)
   {
      case 1: bot_enabled = EnableTelegramBot1; bot_token = TelegramBotToken1; chat_id = TelegramChatID1; break;
      case 2: bot_enabled = EnableTelegramBot2; bot_token = TelegramBotToken2; chat_id = TelegramChatID2; break;
      case 3: bot_enabled = EnableTelegramBot3; bot_token = TelegramBotToken3; chat_id = TelegramChatID3; break;
      case 4: bot_enabled = EnableTelegramBot4; bot_token = TelegramBotToken4; chat_id = TelegramChatID4; break;
   }

   if(!bot_enabled || bot_token == "" || chat_id == "") return;

   string url = "https://api.telegram.org/bot" + bot_token + "/sendPhoto";
   string boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW";
   string headers = "Content-Type: multipart/form-data; boundary=" + boundary;
   char post_data[];
   uchar result_data[];
   string result_headers;

   string body = "--" + boundary + "\r\n" +
                 "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n" +
                 chat_id + "\r\n" +
                 "--" + boundary + "\r\n" +
                 "Content-Disposition: form-data; name=\"photo\"; filename=\"" + file_name + "\"\r\n" +
                 "Content-Type: image/png\r\n\r\n";

   int file_handle = FileOpen(file_name, FILE_READ | FILE_BIN);
   if(file_handle == INVALID_HANDLE) return;
   long file_size = FileSize(file_handle);
   uchar file_content[];
   FileReadArray(file_handle, file_content);
   FileClose(file_handle);

   char body_array[];
   int body_size = StringToCharArray(body, body_array) - 1;
   string footer = "\r\n--" + boundary + "--\r\n";
   char footer_array[];
   int footer_size = StringToCharArray(footer, footer_array) - 1;

   ArrayResize(post_data, body_size + (int)file_size + footer_size);
   int offset = 0;
   ArrayCopy(post_data, body_array, offset, 0, body_size);
   offset += body_size;
   ArrayCopy(post_data, file_content, offset, 0, (int)file_size);
   offset += (int)file_size;
   ArrayCopy(post_data, footer_array, offset, 0, footer_size);

   WebRequest("POST", url, headers, 10000, post_data, result_data, result_headers);
}

//+------------------------------------------------------------------+
//| RSI Helpers                                                      |
//+------------------------------------------------------------------+
int GetRsiPeriodForTimeframe(ENUM_TIMEFRAMES timeframe)
{
   switch(timeframe)
   {
      case PERIOD_D1: return RsiPeriod_D1;
      case PERIOD_H4: return RsiPeriod_H4;
      case PERIOD_H1: return RsiPeriod_H1;
      case PERIOD_M30: return RsiPeriod_M30;
      case PERIOD_M15: return RsiPeriod_M15;
      case PERIOD_M5: return RsiPeriod_M5;
      case PERIOD_M1: return RsiPeriod_M1;
      default: return RsiPeriod_M1;
   }
}

//+------------------------------------------------------------------+
//| Delete all RSI-related chart objects                             |
//+------------------------------------------------------------------+
void DeleteAllRsiObjects()
{
   // Líneas
   ObjectDelete(0, RSI_HIGH_LEVEL_LINE);
   ObjectDelete(0, RSI_LOW_LEVEL_LINE);
   ObjectDelete(0, RSI_MID_LEVEL_LINE);
   ObjectDelete(0, RSI_SECOND_HIGH_LEVEL_LINE);
   ObjectDelete(0, RSI_SECOND_LOW_LEVEL_LINE);
   ObjectDelete(0, RSI_UPPER_QUARTILE_LINE);
   ObjectDelete(0, RSI_LOWER_QUARTILE_LINE);
   ObjectDelete(0, RSI_LOW_TOP_LINE);
   ObjectDelete(0, RSI_LOW_BOTTOM_LINE);

   // Etiquetas del Panel (Ya se borran en OnDeinit global, pero por seguridad)
   ObjectDelete(0, LABEL_RSI_TOP_STATUS);
   ObjectDelete(0, LABEL_REACT_TOP_STATUS);
   ObjectDelete(0, LABEL_RSI_MID_TOP_STATUS);
   ObjectDelete(0, LABEL_RSI_LOW_TOP_STATUS);
   ObjectDelete(0, LABEL_RSI_MID_STATUS);
   ObjectDelete(0, LABEL_RSI_LOW_BOTTOM_STATUS);
   ObjectDelete(0, LABEL_RSI_MID_BOTTOM_STATUS);
   ObjectDelete(0, LABEL_REACT_BOTTOM_STATUS);
   ObjectDelete(0, LABEL_RSI_BOTTOM_STATUS);
}

void RemoveRsiIndicator()
{
   int subwindow = 1;
   for(int i = ChartIndicatorsTotal(0, subwindow) - 1; i >= 0; i--)
   {
      string indicator_name = ChartIndicatorName(0, subwindow, i);
      if(StringFind(indicator_name, "RSI") != -1)
      {
         ChartIndicatorDelete(0, subwindow, indicator_name);
      }
   }
}

void UpdateSingleRsiLabel(string label_name, string prefix, double current_rsi, double level, double range)
{
   string text;
   color label_color;
   if(level == 0)
   {
      ObjectSetString(0, label_name, OBJPROP_TEXT, prefix + ": Calculando...");
      ObjectSetInteger(0, label_name, OBJPROP_COLOR, clrGray);
      return;
   }
   if(current_rsi >= level - range && current_rsi <= level + range)
   {
      text = prefix + ": Rango alcanzado";
      label_color = clrGreen;
   }
   else if(current_rsi < level)
   {
      text = prefix + ": Por debajo del rango";
      label_color = clrWhite;
   }
   else
   {
      text = prefix + ": Por encima del rango";
      label_color = clrWhite;
   }
   ObjectSetString(0, label_name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, label_name, OBJPROP_COLOR, label_color);
}

//+------------------------------------------------------------------+
//| Update RSI Status Labels on the Panel                            |
//+------------------------------------------------------------------+
void UpdateRsiStatusLabels()
{
   if(rsi_handle == INVALID_HANDLE) return;

   // Obtener RSI Actual
   double rsi_buffer[1];
   if(CopyBuffer(rsi_handle, 0, 0, 1, rsi_buffer) <= 0) return;
   double current_rsi = rsi_buffer[0];
   
   if(current_rsi <= 0 || current_rsi >= 100) return;

   // Definir rango de sensibilidad (ej. +/- 0.5 puntos)
   double range = 0.5;

   // Actualizar cada etiqueta individualmente
   UpdateSingleRsiLabel(LABEL_RSI_TOP_STATUS,    "RSI-TOP",        current_rsi, rsi_top_level, range);
   UpdateSingleRsiLabel(LABEL_REACT_TOP_STATUS,  "REACT-TOP",      current_rsi, rsi_react_top_level, range);
   UpdateSingleRsiLabel(LABEL_RSI_MID_TOP_STATUS,"RSI-MID-TOP",    current_rsi, rsi_mid_top_level, range);
   UpdateSingleRsiLabel(LABEL_RSI_LOW_TOP_STATUS,"RSI-LOW-TOP",    current_rsi, rsi_low_top_level, range);

   UpdateSingleRsiLabel(LABEL_RSI_MID_STATUS,    "RSI-MID",        current_rsi, rsi_mid_level, range);

   UpdateSingleRsiLabel(LABEL_RSI_LOW_BOTTOM_STATUS, "RSI-LOW-BOTTOM", current_rsi, rsi_low_bottom_level, range);
   UpdateSingleRsiLabel(LABEL_RSI_MID_BOTTOM_STATUS, "RSI-MID-BOTTOM", current_rsi, rsi_mid_bottom_level, range);
   UpdateSingleRsiLabel(LABEL_REACT_BOTTOM_STATUS,   "REACT-BOTTOM",   current_rsi, rsi_react_bottom_level, range);
   UpdateSingleRsiLabel(LABEL_RSI_BOTTOM_STATUS,     "RSI-BOTTOM",     current_rsi, rsi_bottom_level, range);
}

void TriggerAlert(int bot_index, string level_name, string order_type)
{
   string message = "RSI ALERT: " + _Symbol + " (" + EnumToString(_Period) + ")\n";
   message += "--------------\n";
   message += "Rango RSI alcanzado: " + level_name + "\n";
   message += "Posible dirección: " + order_type;
   SendTelegramMessage(message, bot_index);

   string file_name = _Symbol + "_" + EnumToString(_Period) + "_Alert_" + TimeToString(TimeCurrent(), "yyyy.MM.dd_HH-mm-ss") + ".png";
   ChartRedraw();
   Sleep(500);
   if(ChartScreenShot(0, file_name, 1920, 1080, ALIGN_CENTER))
   {
      SendTelegramScreenshot(bot_index, file_name);
      FileDelete(file_name);
   }
}

void check_and_alert(double current_rsi, double level, int flag_index, string name, string order_type, double range, int bot_index)
{
   bool flag = false;
   switch(flag_index)
   {
      case 0: flag = alert_sent_rsi_top; break;
      case 1: flag = alert_sent_mid_top; break;
      case 2: flag = alert_sent_react_top; break;
      case 3: flag = alert_sent_low_top; break;
      case 4: flag = alert_sent_rsi_bottom; break;
      case 5: flag = alert_sent_mid_bottom; break;
      case 6: flag = alert_sent_react_bottom; break;
      case 7: flag = alert_sent_low_bottom; break;
      case 8: flag = alert_sent_rsi_mid; break;
   }

   if(current_rsi >= level - range && current_rsi <= level + range)
   {
      if(!flag)
      {
         TriggerAlert(bot_index, name, order_type);
         switch(flag_index)
         {
            case 0: alert_sent_rsi_top = true; break;
            case 1: alert_sent_mid_top = true; break;
            case 2: alert_sent_react_top = true; break;
            case 3: alert_sent_low_top = true; break;
            case 4: alert_sent_rsi_bottom = true; break;
            case 5: alert_sent_mid_bottom = true; break;
            case 6: alert_sent_react_bottom = true; break;
            case 7: alert_sent_low_bottom = true; break;
            case 8: alert_sent_rsi_mid = true; break;
         }
      }
   }
   else
   {
      switch(flag_index)
      {
         case 0: alert_sent_rsi_top = false; break;
         case 1: alert_sent_mid_top = false; break;
         case 2: alert_sent_react_top = false; break;
         case 3: alert_sent_low_top = false; break;
         case 4: alert_sent_rsi_bottom = false; break;
         case 5: alert_sent_mid_bottom = false; break;
         case 6: alert_sent_react_bottom = false; break;
         case 7: alert_sent_low_bottom = false; break;
         case 8: alert_sent_rsi_mid = false; break;
      }
   }
}

void CheckRsiAlerts()
{
   if(rsi_handle == INVALID_HANDLE) return;
   double rsi_buffer[1];
   if(CopyBuffer(rsi_handle, 0, 0, 1, rsi_buffer) <= 0) return;
   double current_rsi = rsi_buffer[0];
   if(current_rsi <= 0 || current_rsi >= 100) return;

   int bot_index = 2; // Alertas RSI al Bot 2
   double range = 0.5;

   check_and_alert(current_rsi, rsi_top_level, 0, "RSI-TOP", "SELL", range, bot_index);
   check_and_alert(current_rsi, rsi_bottom_level, 4, "RSI-BOTTOM", "BUY", range, bot_index);
   check_and_alert(current_rsi, rsi_mid_level, 8, "RSI-MID", "NEUTRAL", range, bot_index);
   check_and_alert(current_rsi, rsi_mid_top_level, 1, "RSI-MID-TOP", "SELL", range, bot_index);
   check_and_alert(current_rsi, rsi_mid_bottom_level, 5, "RSI-MID-BOTTOM", "BUY", range, bot_index);
   check_and_alert(current_rsi, rsi_react_top_level, 2, "REACT-TOP", "SELL", range, bot_index);
   check_and_alert(current_rsi, rsi_react_bottom_level, 6, "REACT-BOTTOM", "BUY", range, bot_index);
   check_and_alert(current_rsi, rsi_low_top_level, 3, "RSI-LOW-TOP", "SELL", range, bot_index);
   check_and_alert(current_rsi, rsi_low_bottom_level, 7, "RSI-LOW-BOTTOM", "BUY", range, bot_index);
}

//+------------------------------------------------------------------+
//| Analyze and Draw RSI Levels (Full Detail)                        |
//+------------------------------------------------------------------+
void AnalyzeAndDrawRsiLevels()
{
   // 1. Definir rango de tiempo (Últimos 2 años)
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.year -= 2;
   datetime startTime = StructToTime(dt);

   // 2. Obtener datos RSI
   int bars = Bars(_Symbol, _Period, startTime, TimeCurrent());
   if(bars <= 0 || rsi_handle == INVALID_HANDLE) return;

   double rsi_values[];
   if(CopyBuffer(rsi_handle, 0, 0, bars, rsi_values) <= 0) return;

   // 3. Encontrar Máximo y Mínimo Histórico
   double highest_rsi = 0;
   double lowest_rsi = 100;
   bool first_valid_found = false;

   for(int i = 0; i < ArraySize(rsi_values); i++)
   {
      if(rsi_values[i] <= 0 || rsi_values[i] >= 100) continue; // Filtrar errores

      if(!first_valid_found)
      {
         highest_rsi = rsi_values[i];
         lowest_rsi = rsi_values[i];
         first_valid_found = true;
      }
      else
      {
         if(rsi_values[i] > highest_rsi) highest_rsi = rsi_values[i];
         if(rsi_values[i] < lowest_rsi) lowest_rsi = rsi_values[i];
      }
   }

   if(!first_valid_found) return;

   // 4. Calcular Niveles Intermedios (Subdivisión Binaria)
   // Niveles Principales
   rsi_top_level = highest_rsi;
   rsi_bottom_level = lowest_rsi;
   rsi_mid_level = (highest_rsi + lowest_rsi) / 2.0;

   // Niveles Secundarios (Mid-Top / Mid-Bottom)
   rsi_mid_top_level = (highest_rsi + rsi_mid_level) / 2.0;
   rsi_mid_bottom_level = (lowest_rsi + rsi_mid_level) / 2.0;

   // Niveles Terciarios (React y Low)
   rsi_react_top_level = (highest_rsi + rsi_mid_top_level) / 2.0;    // ~87.5%
   rsi_react_bottom_level = (lowest_rsi + rsi_mid_bottom_level) / 2.0; // ~12.5%
   
   rsi_low_top_level = (rsi_mid_level + rsi_mid_top_level) / 2.0;    // ~62.5%
   rsi_low_bottom_level = (rsi_mid_level + rsi_mid_bottom_level) / 2.0; // ~37.5%

   // 5. Dibujar Líneas en la Ventana del Indicador (Window 1)
   // Nota: Usamos subwindow=1 asumiendo que el RSI es el primer indicador añadido.
   int subwindow = 1;

   // --- TOP & BOTTOM (SOLID GOLD) ---
   ObjectCreate(0, RSI_HIGH_LEVEL_LINE, OBJ_HLINE, subwindow, 0, rsi_top_level);
   ObjectSetInteger(0, RSI_HIGH_LEVEL_LINE, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, RSI_HIGH_LEVEL_LINE, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, RSI_HIGH_LEVEL_LINE, OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, RSI_LOW_LEVEL_LINE, OBJ_HLINE, subwindow, 0, rsi_bottom_level);
   ObjectSetInteger(0, RSI_LOW_LEVEL_LINE, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, RSI_LOW_LEVEL_LINE, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, RSI_LOW_LEVEL_LINE, OBJPROP_STYLE, STYLE_SOLID);

   // --- MID (SOLID ORANGE) ---
   ObjectCreate(0, RSI_MID_LEVEL_LINE, OBJ_HLINE, subwindow, 0, rsi_mid_level);
   ObjectSetInteger(0, RSI_MID_LEVEL_LINE, OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(0, RSI_MID_LEVEL_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, RSI_MID_LEVEL_LINE, OBJPROP_STYLE, STYLE_SOLID);

   // --- MID-TOP & MID-BOTTOM (YELLOW DOTTED) ---
   ObjectCreate(0, RSI_SECOND_HIGH_LEVEL_LINE, OBJ_HLINE, subwindow, 0, rsi_mid_top_level);
   ObjectSetInteger(0, RSI_SECOND_HIGH_LEVEL_LINE, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, RSI_SECOND_HIGH_LEVEL_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, RSI_SECOND_HIGH_LEVEL_LINE, OBJPROP_STYLE, STYLE_DOT);

   ObjectCreate(0, RSI_SECOND_LOW_LEVEL_LINE, OBJ_HLINE, subwindow, 0, rsi_mid_bottom_level);
   ObjectSetInteger(0, RSI_SECOND_LOW_LEVEL_LINE, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, RSI_SECOND_LOW_LEVEL_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, RSI_SECOND_LOW_LEVEL_LINE, OBJPROP_STYLE, STYLE_DOT);

   // --- REACT TOP & BOTTOM (LIME/GREEN DOTTED) ---
   ObjectCreate(0, RSI_UPPER_QUARTILE_LINE, OBJ_HLINE, subwindow, 0, rsi_react_top_level);
   ObjectSetInteger(0, RSI_UPPER_QUARTILE_LINE, OBJPROP_COLOR, clrLime); // O clrChartreuse
   ObjectSetInteger(0, RSI_UPPER_QUARTILE_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, RSI_UPPER_QUARTILE_LINE, OBJPROP_STYLE, STYLE_DOT);

   ObjectCreate(0, RSI_LOWER_QUARTILE_LINE, OBJ_HLINE, subwindow, 0, rsi_react_bottom_level);
   ObjectSetInteger(0, RSI_LOWER_QUARTILE_LINE, OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, RSI_LOWER_QUARTILE_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, RSI_LOWER_QUARTILE_LINE, OBJPROP_STYLE, STYLE_DOT);

   // --- LOW-TOP & LOW-BOTTOM (RED/ORANGE DOTTED) ---
   ObjectCreate(0, RSI_LOW_TOP_LINE, OBJ_HLINE, subwindow, 0, rsi_low_top_level);
   ObjectSetInteger(0, RSI_LOW_TOP_LINE, OBJPROP_COLOR, clrOrangeRed);
   ObjectSetInteger(0, RSI_LOW_TOP_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, RSI_LOW_TOP_LINE, OBJPROP_STYLE, STYLE_DOT);

   ObjectCreate(0, RSI_LOW_BOTTOM_LINE, OBJ_HLINE, subwindow, 0, rsi_low_bottom_level);
   ObjectSetInteger(0, RSI_LOW_BOTTOM_LINE, OBJPROP_COLOR, clrOrangeRed);
   ObjectSetInteger(0, RSI_LOW_BOTTOM_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, RSI_LOW_BOTTOM_LINE, OBJPROP_STYLE, STYLE_DOT);
}

//+------------------------------------------------------------------+
//| Análisis de Tendencias y MA                                      |
//+------------------------------------------------------------------+
datetime FindClosestTime(datetime time_to_check)
{
   datetime time_after_array[1];
   datetime time_after = 0;
   if(CopyTime(_Symbol, PERIOD_D1, time_to_check, 1, time_after_array) > 0) time_after = time_after_array[0];

   int bar_index_before = iBarShift(_Symbol, PERIOD_D1, time_to_check, false);
   datetime time_before = 0;
   if(bar_index_before >= 0) time_before = iTime(_Symbol, PERIOD_D1, bar_index_before);

   if(time_after > 0 && time_before > 0)
      return (MathAbs((long)time_to_check - (long)time_before) < MathAbs((long)time_after - (long)time_to_check)) ? time_before : time_after;
   else if(time_after > 0) return time_after;
   else if(time_before > 0) return time_before;
   return 0;
}

double ProcessAnnualPeriod(datetime startDate, datetime endDate, string highLineName, string lowLineName, string avgLineName, color lineColor, int timeOffsetDays, string impulseLabelName, string impulseLabelPrefix, bool isCurrentYearPeriod)
{
   MqlRates rates[];
   int ratesCount = CopyRates(_Symbol, PERIOD_D1, startDate, endDate, rates);
   if(ratesCount <= 0) return 0.0;

   double highestPrice = 0, lowestPrice = 0;
   datetime highestTime = 0, lowestTime = 0;
   for(int i = 0; i < ratesCount; i++)
   {
      if(rates[i].high > highestPrice) { highestPrice = rates[i].high; highestTime = rates[i].time; }
      if(lowestPrice == 0 || rates[i].low < lowestPrice) { lowestPrice = rates[i].low; lowestTime = rates[i].time; }
   }

   if(isCurrentYearPeriod) { yearlyHigh = highestPrice; yearlyLow = lowestPrice; }

   long timeOffset = timeOffsetDays * 86400;

   if(highestTime > 0)
   {
      datetime start_time = FindClosestTime(highestTime - timeOffset);
      datetime end_time = FindClosestTime(highestTime + timeOffset);
      if(start_time > 0 && end_time > 0)
      {
         ObjectCreate(0, highLineName, OBJ_TREND, 0, start_time, highestPrice, end_time, highestPrice);
         ObjectSetInteger(0, highLineName, OBJPROP_COLOR, lineColor);
         ObjectSetInteger(0, highLineName, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, highLineName, OBJPROP_BACK, true);
      }
   }

   if(lowestTime > 0)
   {
      datetime start_time = FindClosestTime(lowestTime - timeOffset);
      datetime end_time = FindClosestTime(lowestTime + timeOffset);
      if(start_time > 0 && end_time > 0)
      {
         ObjectCreate(0, lowLineName, OBJ_TREND, 0, start_time, lowestPrice, end_time, lowestPrice);
         ObjectSetInteger(0, lowLineName, OBJPROP_COLOR, lineColor);
         ObjectSetInteger(0, lowLineName, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, lowLineName, OBJPROP_BACK, true);
      }
   }

   if(highestPrice > 0)
   {
      double impulseStrength = ((lowestPrice - highestPrice) / highestPrice) * 100;
      string impulseText = impulseLabelPrefix + StringFormat("%.2f%%", impulseStrength);
      ObjectSetString(0, impulseLabelName, OBJPROP_TEXT, impulseText);
      return impulseStrength;
   }
   return 0.0;
}

void ProcessSemesterPeriod(datetime startDate, datetime endDate, int year, int semesterNum, bool isCurrentYear)
{
   MqlRates rates[];
   int ratesCount = CopyRates(_Symbol, PERIOD_D1, startDate, endDate, rates);
   if(ratesCount <= 0) return;

   double highestPrice = 0, lowestPrice = 0;
   datetime highestTime = 0, lowestTime = 0;
   for(int i = 0; i < ratesCount; i++)
   {
      if(rates[i].high > highestPrice) { highestPrice = rates[i].high; highestTime = rates[i].time; }
      if(lowestPrice == 0 || rates[i].low < lowestPrice) { lowestPrice = rates[i].low; lowestTime = rates[i].time; }
   }
   // ... Lógica de dibujo simplificada para semestres ...
}

void UpdateDailyData()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int current_year = dt.year;
   datetime now = TimeCurrent();

   // Definir rangos (simplificado)
   dt.year = current_year; dt.mon = 1; dt.day = 1; dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime start_curr_year = StructToTime(dt);

   dt.year = current_year - 1;
   datetime start_prev_year = StructToTime(dt);
   dt.mon = 12; dt.day = 31; dt.hour = 23; dt.min = 59; dt.sec = 59;
   datetime end_prev_year = StructToTime(dt);

   ProcessAnnualPeriod(start_curr_year, now, TRENDLINE_HIGH, TRENDLINE_LOW, TRENDLINE_AVG, clrYellow, AnnualTimeOffsetDays, LABEL_IMPULSE_STRENGTH, "Fuerza Impulso: ", true);
   previousYearImpulseStrength = ProcessAnnualPeriod(start_prev_year, end_prev_year, TRENDLINE_HIGH_PREV, TRENDLINE_LOW_PREV, TRENDLINE_AVG_PREV, clrMagenta, AnnualTimeOffsetDays, LABEL_IMPULSE_STRENGTH_PREV, "Fuerza Impulso Ant: ", false);

   AnalyzeAndDrawRsiLevels();
   CalculateAvgCandleSizeForSemester(1);
   CalculateAvgCandleSizeForSemester(2);
}

void DrawImpulseLines()
{
   if(previousYearImpulseStrength == 0.0 || yearlyHigh == 0.0 || yearlyLow == 0.0) return;
   double impulseAbs = MathAbs(previousYearImpulseStrength);
   double highLinePrice = yearlyHigh * (1 - impulseAbs / 100.0);
   double lowLinePrice = yearlyLow * (1 + impulseAbs / 100.0);

   long timeOffset = (long)AnnualTimeOffsetDays * 86400;
   datetime now = TimeCurrent();
   datetime startTime = FindClosestTime(now - timeOffset);
   datetime endTime = FindClosestTime(now + timeOffset);
   if(startTime == 0 || endTime == 0) return;

   ObjectCreate(0, IMPULSE_HIGH_LINE, OBJ_TREND, 0, startTime, highLinePrice, endTime, highLinePrice);
   ObjectSetInteger(0, IMPULSE_HIGH_LINE, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, IMPULSE_HIGH_LINE, OBJPROP_WIDTH, 3);
   
   ObjectCreate(0, IMPULSE_LOW_LINE, OBJ_TREND, 0, startTime, lowLinePrice, endTime, lowLinePrice);
   ObjectSetInteger(0, IMPULSE_LOW_LINE, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, IMPULSE_LOW_LINE, OBJPROP_WIDTH, 3);
}

void CalculateAvgCandleSizeForSemester(int semester)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int current_year = dt.year;
   datetime start_semester, end_semester;
   string label_name;

   if(semester == 1)
   {
      dt.year = current_year; dt.mon = 1; dt.day = 1; dt.hour = 0; dt.min = 0; dt.sec = 0;
      start_semester = StructToTime(dt);
      dt.mon = 6; dt.day = 30; dt.hour = 23; dt.min = 59; dt.sec = 59;
      end_semester = StructToTime(dt);
      label_name = LABEL_AVG_CANDLE_SIZE_S1;
   }
   else
   {
      dt.year = current_year; dt.mon = 7; dt.day = 1; dt.hour = 0; dt.min = 0; dt.sec = 0;
      start_semester = StructToTime(dt);
      dt.mon = 12; dt.day = 31; dt.hour = 23; dt.min = 59; dt.sec = 59;
      end_semester = StructToTime(dt);
      label_name = LABEL_AVG_CANDLE_SIZE_S2;
   }

   datetime now = TimeCurrent();
   if(now < start_semester) return;

   MqlRates rates[];
   int ratesCount = CopyRates(_Symbol, PERIOD_H4, start_semester, (now < end_semester ? now : end_semester), rates);
   if(ratesCount <= 0) return;

   double totalSize = 0;
   for(int i = 0; i < ratesCount; i++) totalSize += (rates[i].high - rates[i].low);
   double avgSizeInPoints = (totalSize / ratesCount) / _Point;

   string avgSizeText = "Prom Vela (4H S"+IntegerToString(semester)+"): " + StringFormat("%.0f", avgSizeInPoints) + " Pts";
   ObjectSetString(0, label_name, OBJPROP_TEXT, avgSizeText);
}

//+------------------------------------------------------------------+
//| Calcula Distancias MA200 vs MA20                                 |
//+------------------------------------------------------------------+
void UpdateMADistanceMetrics()
{
   datetime time_end = TimeCurrent();
   datetime time_start = time_end - (PeriodSeconds(PERIOD_D1) * 365 * 2);

   // We reuse global handles initialized in OnInit
   if(ma200_handle == INVALID_HANDLE || ma20_handle == INVALID_HANDLE) return;

   double buf_ma200[];
   double buf_ma20[];
   ArraySetAsSeries(buf_ma200, true);
   ArraySetAsSeries(buf_ma20, true);

   int copied200 = CopyBuffer(ma200_handle, 0, time_start, time_end, buf_ma200);
   int copied20  = CopyBuffer(ma20_handle, 0, time_start, time_end, buf_ma20);

   if(copied200 > 0 && copied20 > 0)
   {
      int limit = MathMin(copied200, copied20);
      double max_dist_percent = 0.0;
      double min_dist_percent = DBL_MAX;
      double sum_dist_percent = 0.0;
      int count = 0;

      for(int i = 0; i < limit; i++)
      {
         double val200 = buf_ma200[i];
         double val20  = buf_ma20[i];
         if(val200 <= 0 || val20 <= 0) continue;
         double dist_percent = (MathAbs(val200 - val20) / val200) * 100.0;
         if(dist_percent > 50.0) continue;

         if(dist_percent > max_dist_percent) max_dist_percent = dist_percent;
         if(dist_percent < min_dist_percent) min_dist_percent = dist_percent;
         sum_dist_percent += dist_percent;
         count++;
      }

      double avg_dist_percent = (count > 0) ? (sum_dist_percent / count) : 0.0;
      if(min_dist_percent == DBL_MAX) min_dist_percent = 0.0;

      double current_dist_percent = 0.0;
      if(limit > 0 && buf_ma200[0] > 0 && buf_ma20[0] > 0)
      {
         current_dist_percent = (MathAbs(buf_ma200[0] - buf_ma20[0]) / buf_ma200[0]) * 100.0;

         if(buf_ma20[0] > buf_ma200[0]) g_ma_trend_direction = 1;
         else g_ma_trend_direction = -1;

         if(max_dist_percent > 0 && current_dist_percent >= max_dist_percent * 0.95) g_ma_is_red_extended = true;
         else g_ma_is_red_extended = false;

         if(avg_dist_percent > 0 && current_dist_percent <= (avg_dist_percent * 0.5)) g_ma_is_green_compressed = true;
         else g_ma_is_green_compressed = false;
      }

      string time_str = EnumToString(_Period);
      StringReplace(time_str, "PERIOD_", "");

      string txtCurr = "Dist Actual (" + time_str + "): " + StringFormat("%.2f%%", current_dist_percent);
      ObjectSetString(0, LABEL_MA_DIST_CURR, OBJPROP_TEXT, txtCurr);
      if(g_ma_is_red_extended) ObjectSetInteger(0, LABEL_MA_DIST_CURR, OBJPROP_COLOR, clrRed);
      else if(g_ma_is_green_compressed) ObjectSetInteger(0, LABEL_MA_DIST_CURR, OBJPROP_COLOR, clrLime);
      else ObjectSetInteger(0, LABEL_MA_DIST_CURR, OBJPROP_COLOR, clrWhite);

      ObjectSetString(0, LABEL_MA_DIST_MAX, OBJPROP_TEXT, "Dist Max: " + StringFormat("%.2f%%", max_dist_percent));
      ObjectSetString(0, LABEL_MA_DIST_MIN, OBJPROP_TEXT, "Dist Min: " + StringFormat("%.2f%%", min_dist_percent));

      string statusText = "Dist Prom: " + StringFormat("%.2f%%", avg_dist_percent);
      if(g_ma_is_red_extended) { statusText = "⛔ EXTENSION MAXIMA DETECTADA"; ObjectSetInteger(0, LABEL_MA_DIST_AVG, OBJPROP_COLOR, clrRed); }
      else if(g_ma_is_green_compressed) { statusText = "⚡ COMPRESION DETECTADA"; ObjectSetInteger(0, LABEL_MA_DIST_AVG, OBJPROP_COLOR, clrLime); }
      else { ObjectSetInteger(0, LABEL_MA_DIST_AVG, OBJPROP_COLOR, clrSilver); }

      ObjectSetString(0, LABEL_MA_DIST_AVG, OBJPROP_TEXT, statusText);
   }
   // No release here
}

//+------------------------------------------------------------------+
//| Log Snapshot (Solo métricas, sin equity)                         |
//+------------------------------------------------------------------+
void LogSnapshot()
{
   if(!EnableFileLogs) return;

   double rsi_buffer[1];
   double atr_buffer[1];
   double current_rsi = 0;
   double current_atr = 0;

   if(CopyBuffer(rsi_handle, 0, 0, 1, rsi_buffer) > 0) current_rsi = rsi_buffer[0];
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) > 0) current_atr = atr_buffer[0];

   // Obtener Distancia MA actual (recalculada brevemente para el log)
   // Para simplicidad, se podría hacer global, pero aquí leemos la lógica visual
   // Asumimos que UpdateMADistanceMetrics ya corrió.
   
   int handle = FileOpen(GetLogFileName("analysis_log_"), FILE_READ | FILE_WRITE | FILE_CSV | FILE_SHARE_READ);
   if(handle != INVALID_HANDLE)
   {
      FileSeek(handle, 0, SEEK_END);
      string log_row = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "," +
                       StringFormat("%.2f", current_rsi) + "," +
                       StringFormat("%.*f", _Digits, current_atr) + "," +
                       (g_ma_is_red_extended ? "EXTENDED" : (g_ma_is_green_compressed ? "COMPRESSED" : "NORMAL")) + "," +
                       IntegerToString(g_ma_trend_direction) + "\n";
      FileWriteString(handle, log_row);
      FileClose(handle);
   }
}

//+------------------------------------------------------------------+
//| Cleanup Screenshot Files                                         |
//+------------------------------------------------------------------+
void CleanupScreenshotFiles()
{
   int deleted_count = 0;
   long search_handle;
   string file_name;
   search_handle = FileFindFirst("*.png", file_name);
   if(search_handle != INVALID_HANDLE)
   {
      do { if(FileDelete(file_name)) deleted_count++; } while(FileFindNext(search_handle, file_name));
      FileFindClose(search_handle);
   }
   Alert("Limpieza completada. " + IntegerToString(deleted_count) + " archivos borrados.");
}

//+------------------------------------------------------------------+
//| OnChartEvent                                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == BUTTON_SEND_SCREENSHOT)
      {
         string file_name = "Manual_Snap_" + _Symbol + ".png";
         ChartScreenShot(0, file_name, 1920, 1080, ALIGN_CENTER);
         SendTelegramScreenshot(1, file_name);
         ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_STATE, false);
      }
      if(sparam == BUTTON_CLEANUP_FILES)
      {
         CleanupScreenshotFiles();
         ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_STATE, false);
      }
      if(sparam == BUTTON_TEST_BOT2)
      {
         SendTelegramMessage("Test Bot 2: Sistema de Análisis Activo.", 2);
         ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_STATE, false);
      }
   }

   // Lógica de Arrastrar Panel
   if(id == CHARTEVENT_OBJECT_DRAG && sparam == BG_RECT)
   {
      int x = (int)lparam;
      int y = (int)dparam;
      int line_height = 15;

      // Mover Columna 1
      int col1_x = x + 20;
      int col1_y = y + 15;
      ObjectSetInteger(0, LABEL_IMPULSE_STRENGTH, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_IMPULSE_STRENGTH, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_IMPULSE_STRENGTH_PREV, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_IMPULSE_STRENGTH_PREV, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_SEPARATOR_1, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_SEPARATOR_1, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_PERCENT_FROM_HIGH, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_PERCENT_FROM_HIGH, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_PERCENT_FROM_LOW, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_PERCENT_FROM_LOW, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_SEPARATOR_2, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_SEPARATOR_2, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_AVG_CANDLE_SIZE_S1, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_AVG_CANDLE_SIZE_S1, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_AVG_CANDLE_SIZE_S2, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_AVG_CANDLE_SIZE_S2, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_SEPARATOR_MA, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_SEPARATOR_MA, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_MA_DIST_CURR, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_MA_DIST_CURR, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_MA_DIST_MAX, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_MA_DIST_MAX, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_MA_DIST_MIN, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_MA_DIST_MIN, OBJPROP_YDISTANCE, col1_y); col1_y += line_height;
      ObjectSetInteger(0, LABEL_MA_DIST_AVG, OBJPROP_XDISTANCE, col1_x); ObjectSetInteger(0, LABEL_MA_DIST_AVG, OBJPROP_YDISTANCE, col1_y);

      // Mover Columna 2 (RSI)
      int col2_x = x + 300;
      int col2_y = y + 15;
      ObjectSetInteger(0, LABEL_RSI_TOP_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_TOP_STATUS, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_REACT_TOP_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_REACT_TOP_STATUS, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_RSI_MID_TOP_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_MID_TOP_STATUS, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_RSI_LOW_TOP_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_LOW_TOP_STATUS, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_RSI_SEPARATOR_1, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_SEPARATOR_1, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_RSI_MID_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_MID_STATUS, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_RSI_SEPARATOR_2, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_SEPARATOR_2, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_RSI_LOW_BOTTOM_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_LOW_BOTTOM_STATUS, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_RSI_MID_BOTTOM_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_MID_BOTTOM_STATUS, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_REACT_BOTTOM_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_REACT_BOTTOM_STATUS, OBJPROP_YDISTANCE, col2_y); col2_y += line_height;
      ObjectSetInteger(0, LABEL_RSI_BOTTOM_STATUS, OBJPROP_XDISTANCE, col2_x); ObjectSetInteger(0, LABEL_RSI_BOTTOM_STATUS, OBJPROP_YDISTANCE, col2_y);

      // Mover Botones
      int btn_y = y + 340;
      ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_XDISTANCE, x + 10); ObjectSetInteger(0, BUTTON_SEND_SCREENSHOT, OBJPROP_YDISTANCE, btn_y);
      ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_XDISTANCE, x + 140); ObjectSetInteger(0, BUTTON_CLEANUP_FILES, OBJPROP_YDISTANCE, btn_y);
      ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_XDISTANCE, x + 270); ObjectSetInteger(0, BUTTON_TEST_BOT2, OBJPROP_YDISTANCE, btn_y);
   }
}
//+------------------------------------------------------------------+
