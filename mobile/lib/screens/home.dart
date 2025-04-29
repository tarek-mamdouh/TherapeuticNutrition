import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/tts_service.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../widgets/accessibility_widgets.dart';
import 'image_upload.dart';
import 'nutrition_display.dart';
import 'chatbot.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  final Function(Locale) setLocale;
  final Function(ThemeMode) setThemeMode;
  final Function(bool) setHighContrast;
  final Function(double) setTextScaleFactor;
  final Locale currentLocale;
  final ThemeMode currentThemeMode;
  final bool highContrast;
  final double textScaleFactor;
  
  HomePage({
    required this.setLocale,
    required this.setThemeMode,
    required this.setHighContrast,
    required this.setTextScaleFactor,
    required this.currentLocale,
    required this.currentThemeMode,
    required this.highContrast,
    required this.textScaleFactor,
  });
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final TTSService _ttsService = TTSService();
  User? _currentUser;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Initialize TTS
      await _ttsService.initialize();
      
      // Get user profile
      _currentUser = await DatabaseService.instance.getFirstUser();
      
      // If no user exists, create a default one
      if (_currentUser == null) {
        _currentUser = User(
          name: 'User',
          age: 40,
          diabetesType: 'type2',
          preferences: '',
        );
        await DatabaseService.instance.saveUser(_currentUser!);
      }
    } catch (e) {
      print('Error initializing services: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(l10n.loading),
            ],
          ),
        ),
      );
    }
    
    // List of screens
    final List<Widget> screens = [
      ImageUploadScreen(ttsService: _ttsService),
      NutritionDisplayScreen(initialFoods: []),
      ChatbotScreen(ttsService: _ttsService),
      ProfileScreen(
        user: _currentUser!,
        setLocale: widget.setLocale,
        setThemeMode: widget.setThemeMode,
        setHighContrast: widget.setHighContrast,
        setTextScaleFactor: widget.setTextScaleFactor,
        currentLocale: widget.currentLocale,
        currentThemeMode: widget.currentThemeMode,
        highContrast: widget.highContrast,
        textScaleFactor: widget.textScaleFactor,
        onUserUpdated: (User updatedUser) {
          setState(() {
            _currentUser = updatedUser;
          });
        },
      ),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // Quick accessibility button
          AccessibilityButton(
            currentLocale: widget.currentLocale,
            currentThemeMode: widget.currentThemeMode,
            highContrast: widget.highContrast,
            textScaleFactor: widget.textScaleFactor,
            setLocale: widget.setLocale,
            setThemeMode: widget.setThemeMode,
            setHighContrast: widget.setHighContrast,
            setTextScaleFactor: widget.setTextScaleFactor,
          ),
        ],
      ),
      body: SafeArea(
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Read screen name for accessibility
          switch(index) {
            case 0:
              _ttsService.speak(l10n.scanFoodTab, languageCode: widget.currentLocale.languageCode);
              break;
            case 1:
              _ttsService.speak(l10n.nutritionTab, languageCode: widget.currentLocale.languageCode);
              break;
            case 2:
              _ttsService.speak(l10n.chatbotTab, languageCode: widget.currentLocale.languageCode);
              break;
            case 3:
              _ttsService.speak(l10n.profileTab, languageCode: widget.currentLocale.languageCode);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 14 * widget.textScaleFactor,
        unselectedFontSize: 12 * widget.textScaleFactor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: l10n.scanFoodTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: l10n.nutritionTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: l10n.chatbotTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: l10n.profileTab,
          ),
        ],
      ),
    );
  }
}
