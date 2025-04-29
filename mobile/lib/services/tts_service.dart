import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  // Singleton instance
  static final TTSService _instance = TTSService._internal();
  
  // Factory constructor
  factory TTSService() {
    return _instance;
  }
  
  // Private constructor for singleton pattern
  TTSService._internal();
  
  // Flutter TTS instance
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentLanguage = 'ar-SA'; // Default to Arabic
  
  // Initialize TTS
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set up TTS
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.5); // Slower for better understanding
      await _flutterTts.setPitch(1.0);
      
      // Set default language
      await setLanguage('ar');
      
      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }
  
  // Set language
  Future<void> setLanguage(String languageCode) async {
    await initialize();
    
    try {
      String languageTag;
      
      // Map language code to TTS-compatible language tag
      if (languageCode == 'ar') {
        languageTag = 'ar-SA'; // Arabic
      } else if (languageCode == 'en') {
        languageTag = 'en-US'; // English
      } else {
        languageTag = 'ar-SA'; // Default to Arabic
      }
      
      if (_currentLanguage != languageTag) {
        await _flutterTts.setLanguage(languageTag);
        _currentLanguage = languageTag;
      }
    } catch (e) {
      print('Error setting TTS language: $e');
    }
  }
  
  // Speak text
  Future<void> speak(String text, {String languageCode = 'ar'}) async {
    await initialize();
    
    // Stop any ongoing speech
    if (_isSpeaking) {
      await stop();
    }
    
    try {
      // Set language if different from current
      await setLanguage(languageCode);
      
      // Start speaking
      _isSpeaking = true;
      await _flutterTts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      print('Error speaking text: $e');
    }
  }
  
  // Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;
    
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }
  
  // Check if TTS is currently speaking
  bool get isSpeaking => _isSpeaking;
  
  // Speak food information
  Future<void> speakFoodInfo(
    String foodName,
    String calories,
    String carbs,
    String suitability,
    String languageCode
  ) async {
    String text;
    
    if (languageCode == 'ar') {
      text = 'الطعام: $foodName. '
          'السعرات الحرارية: $calories. '
          'الكربوهيدرات: $carbs جرام. '
          'مناسب لمرضى السكري: $suitability.';
    } else {
      text = 'Food: $foodName. '
          'Calories: $calories. '
          'Carbohydrates: $carbs grams. '
          'Diabetic suitability: $suitability.';
    }
    
    await speak(text, languageCode: languageCode);
  }
  
  // Dispose resources
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await stop();
      _isInitialized = false;
    } catch (e) {
      print('Error disposing TTS: $e');
    }
  }
}
