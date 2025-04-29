import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home.dart';
import 'services/database_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await DatabaseService.instance.initializeDatabase();
  
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(DiabetesNutritionApp());
}

class DiabetesNutritionApp extends StatefulWidget {
  @override
  _DiabetesNutritionAppState createState() => _DiabetesNutritionAppState();
}

class _DiabetesNutritionAppState extends State<DiabetesNutritionApp> {
  Locale _locale = Locale('ar'); // Default to Arabic
  ThemeMode _themeMode = ThemeMode.light;
  bool _highContrast = false;
  double _textScaleFactor = 1.0;
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Get language preference (default to Arabic)
      final String languageCode = prefs.getString('languageCode') ?? 'ar';
      _locale = Locale(languageCode);
      
      // Get theme preferences
      _themeMode = prefs.getBool('darkMode') ?? false 
          ? ThemeMode.dark 
          : ThemeMode.light;
      
      // Get accessibility preferences
      _highContrast = prefs.getBool('highContrast') ?? false;
      _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    });
  }
  
  void _setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    
    setState(() {
      _locale = locale;
    });
  }
  
  void _setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', themeMode == ThemeMode.dark);
    
    setState(() {
      _themeMode = themeMode;
    });
  }
  
  void _setHighContrast(bool highContrast) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrast', highContrast);
    
    setState(() {
      _highContrast = highContrast;
    });
  }
  
  void _setTextScaleFactor(double textScaleFactor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScaleFactor', textScaleFactor);
    
    setState(() {
      _textScaleFactor = textScaleFactor;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Choose appropriate theme based on accessibility settings
    ThemeData theme;
    ThemeData darkTheme;
    
    if (_highContrast) {
      // High contrast light theme
      theme = ThemeData.light().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontSizeFactor: _textScaleFactor,
          displayColor: Colors.black,
          bodyColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 18 * _textScaleFactor),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      );
      
      // High contrast dark theme
      darkTheme = ThemeData.dark().copyWith(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          surface: Colors.black,
          background: Colors.black,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontSizeFactor: _textScaleFactor,
          displayColor: Colors.white,
          bodyColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            textStyle: TextStyle(fontSize: 18 * _textScaleFactor),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      );
    } else {
      // Regular light theme
      theme = ThemeData.light().copyWith(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontSizeFactor: _textScaleFactor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16 * _textScaleFactor),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
      );
      
      // Regular dark theme
      darkTheme = ThemeData.dark().copyWith(
        primaryColor: AppColors.primaryDark,
        scaffoldBackgroundColor: Colors.grey[900],
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryDark,
          secondary: AppColors.secondaryDark,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontSizeFactor: _textScaleFactor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16 * _textScaleFactor),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'Diabetes Nutrition',
      theme: theme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      debugShowCheckedModeBanner: false,
      supportedLocales: [
        Locale('ar'), // Arabic
        Locale('en'), // English
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomePage(
        setLocale: _setLocale,
        setThemeMode: _setThemeMode,
        setHighContrast: _setHighContrast,
        setTextScaleFactor: _setTextScaleFactor,
        currentLocale: _locale,
        currentThemeMode: _themeMode,
        highContrast: _highContrast,
        textScaleFactor: _textScaleFactor,
      ),
    );
  }
}
