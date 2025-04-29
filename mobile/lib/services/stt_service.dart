import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

class STTService {
  // Singleton instance
  static final STTService _instance = STTService._internal();
  
  // Factory constructor
  factory STTService() {
    return _instance;
  }
  
  // Private constructor for singleton pattern
  STTService._internal();
  
  // Speech to text instance
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  // Initialize STT
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      return false;
    }
  }
  
  // Start listening
  Future<bool> listen({
    required String languageCode,
    required Function(String) onResult,
    required Function() onListeningComplete
  }) async {
    if (!await initialize()) {
      return false;
    }
    
    if (_isListening) {
      await stop();
    }
    
    try {
      // Determine localeId based on language code
      String localeId;
      if (languageCode == 'ar') {
        localeId = 'ar_SA'; // Arabic
      } else {
        localeId = 'en_US'; // English
      }
      
      _isListening = await _speech.listen(
        localeId: localeId,
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords);
        },
        listenFor: Duration(seconds: 30), // Maximum listening time
        pauseFor: Duration(seconds: 3), // Pause after user stops speaking
        onSoundLevelChange: (level) {
          // Could be used for visualization
        },
      );
      
      // Set callback for when listening completes
      _speech.statusListener = (String status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onListeningComplete();
        }
      };
      
      return _isListening;
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
      return false;
    }
  }
  
  // Stop listening
  Future<void> stop() async {
    if (!_isInitialized || !_isListening) return;
    
    try {
      _speech.stop();
      _isListening = false;
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }
  
  // Check if listening is active
  bool get isListening => _isListening;
  
  // Check if initialized
  bool get isAvailable => _isInitialized;
  
  // Get supported locales (languages)
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!await initialize()) {
      return [];
    }
    
    return _speech.locales();
  }
  
  // Check if a specific language is supported
  Future<bool> isLanguageSupported(String languageCode) async {
    if (!await initialize()) {
      return false;
    }
    
    final locales = await getAvailableLocales();
    
    // Look for a locale that matches the language code
    // (e.g., 'ar' should match 'ar_SA', 'ar_EG', etc.)
    return locales.any((locale) => 
      locale.localeId.startsWith(languageCode.toLowerCase() + '_')
    );
  }
}
