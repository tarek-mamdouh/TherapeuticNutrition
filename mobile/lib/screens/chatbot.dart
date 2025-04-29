import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/food.dart';
import '../services/chatbot_service.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../widgets/accessibility_widgets.dart';
import 'nutrition_display.dart';

class ChatbotScreen extends StatefulWidget {
  final TTSService ttsService;
  
  ChatbotScreen({required this.ttsService});
  
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  final STTService _sttService = STTService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  
  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }
  
  void _addWelcomeMessage() async {
    final locale = Localizations.localeOf(context).languageCode;
    String welcomeMessage = '';
    
    if (locale == 'ar') {
      welcomeMessage = 'مرحبًا! أنا مساعدك الغذائي. يمكنك سؤالي عن الأطعمة المناسبة لمرضى السكري أو نصائح غذائية. كيف يمكنني مساعدتك اليوم؟';
    } else {
      welcomeMessage = 'Hello! I\'m your nutrition assistant. You can ask me about foods suitable for diabetics or dietary advice. How can I help you today?';
    }
    
    setState(() {
      _messages.add(ChatMessage(
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
        relatedFoods: [],
      ));
    });
    
    // Read welcome message aloud
    await Future.delayed(Duration(milliseconds: 500));
    widget.ttsService.speak(welcomeMessage, languageCode: locale);
  }
  
  Future<void> _sendMessage() async {
    final question = _questionController.text.trim();
    
    if (question.isEmpty) return;
    
    final locale = Localizations.localeOf(context).languageCode;
    
    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
        relatedFoods: [],
      ));
      _isLoading = true;
    });
    
    // Clear input field
    _questionController.clear();
    
    // Scroll to bottom
    _scrollToBottom();
    
    try {
      // Get response from chatbot
      final response = await _chatbotService.getChatResponseWithFallback(question, locale);
      
      // Add bot response to chat
      setState(() {
        _messages.add(ChatMessage(
          text: response.answer,
          isUser: false,
          timestamp: DateTime.now(),
          relatedFoods: response.relatedFoods,
        ));
        _isLoading = false;
      });
      
      // Speak the response
      widget.ttsService.speak(response.answer, languageCode: locale);
      
      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      print('Error getting chat response: $e');
      
      // Add error message
      final errorMsg = locale == 'ar'
          ? 'عذرًا، حدث خطأ. يرجى المحاولة مرة أخرى.'
          : 'Sorry, an error occurred. Please try again.';
      
      setState(() {
        _messages.add(ChatMessage(
          text: errorMsg,
          isUser: false,
          timestamp: DateTime.now(),
          relatedFoods: [],
        ));
        _isLoading = false;
      });
      
      // Scroll to bottom
      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _startListening() async {
    final locale = Localizations.localeOf(context).languageCode;
    
    setState(() {
      _isListening = true;
    });
    
    bool success = await _sttService.listen(
      languageCode: locale,
      onResult: (String text) {
        setState(() {
          _questionController.text = text;
        });
      },
      onListeningComplete: () {
        setState(() {
          _isListening = false;
        });
        
        // If we got some text, send the message
        if (_questionController.text.isNotEmpty) {
          _sendMessage();
        }
      },
    );
    
    if (!success) {
      setState(() {
        _isListening = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.speechRecognitionFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _stopListening() {
    _sttService.stop();
    setState(() {
      _isListening = false;
    });
  }
  
  void _viewFoodDetails(Food food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutritionDisplayScreen(initialFoods: [food]),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    
    return Scaffold(
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(child: Text(l10n.noMessagesYet))
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      
                      return Column(
                        crossAxisAlignment: message.isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Message bubble
                          Container(
                            margin: EdgeInsets.only(
                              top: 8,
                              bottom: message.relatedFoods.isNotEmpty ? 4 : 8,
                              left: message.isUser ? 48 : 0,
                              right: message.isUser ? 0 : 48,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SemanticsWrapper(
                                  label: message.isUser
                                      ? l10n.yourMessage + ': ' + message.text
                                      : l10n.chatbotMessage + ': ' + message.text,
                                  child: Text(
                                    message.text,
                                    style: TextStyle(
                                      color: message.isUser
                                          ? Colors.white
                                          : Theme.of(context).textTheme.bodyLarge!.color,
                                    ),
                                  ),
                                ),
                                if (!message.isUser)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.volume_up,
                                        size: 18,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () {
                                        widget.ttsService.speak(
                                          message.text,
                                          languageCode: locale,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Timestamp
                          Padding(
                            padding: EdgeInsets.only(
                              left: message.isUser ? 48 : 16,
                              right: message.isUser ? 16 : 48,
                              bottom: message.relatedFoods.isNotEmpty ? 4 : 16,
                            ),
                            child: Text(
                              _formatTimestamp(message.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          
                          // Related foods (if any)
                          if (message.relatedFoods.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(
                                left: 16,
                                right: 48,
                                bottom: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.relatedFoods,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    height: 40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: message.relatedFoods.length,
                                      itemBuilder: (context, foodIndex) {
                                        final food = message.relatedFoods[foodIndex];
                                        return Container(
                                          margin: EdgeInsets.only(right: 8),
                                          child: ActionChip(
                                            avatar: CircleAvatar(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              child: Text(
                                                food.getLocalizedName(locale).substring(0, 1).toUpperCase(),
                                                style: TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                            label: Text(food.getLocalizedName(locale)),
                                            onPressed: () => _viewFoodDetails(food),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          
          // Loading indicator
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(l10n.thinking),
                ],
              ),
            ),
          
          // Input area
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[100],
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Voice input button
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: _isLoading
                      ? null
                      : (_isListening ? _stopListening : _startListening),
                  tooltip: _isListening ? l10n.stopListening : l10n.startListening,
                ),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: l10n.typeYourQuestion,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading && !_isListening,
                  ),
                ),
                
                // Send button
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isLoading || _questionController.text.isEmpty
                      ? null
                      : _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: l10n.sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    
    if (messageDate == today) {
      // Today, show the time
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      // Yesterday
      return locale == 'ar' ? 'أمس' : 'Yesterday';
    } else {
      // Other days, show the date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
  
  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Food> relatedFoods;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.relatedFoods,
  });
}
