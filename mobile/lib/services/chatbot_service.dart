import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food.dart';
import '../utils/constants.dart';
import 'database_service.dart';

class ChatbotService {
  // Singleton instance
  static final ChatbotService _instance = ChatbotService._internal();
  final DatabaseService _databaseService = DatabaseService.instance;
  
  // Factory constructor
  factory ChatbotService() {
    return _instance;
  }
  
  // Private constructor for singleton pattern
  ChatbotService._internal();
  
  // Get chat response from API
  Future<ChatResponse> getChatResponseFromApi(String question, String language) async {
    try {
      // Make API request
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'question': question,
          'language': language,
        }),
      );
      
      // Check for successful response
      if (response.statusCode == 200) {
        // Parse response
        Map<String, dynamic> data = json.decode(response.body);
        return ChatResponse.fromJson(data);
      } else {
        print('Failed to get chat response. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to get chat response with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting chat response: $e');
      throw Exception('Error getting chat response: $e');
    }
  }
  
  // Get chat response from local database
  Future<ChatResponse?> getChatResponseFromLocal(String question, String language) async {
    try {
      final db = await _databaseService.database;
      
      // Extract keywords from question (words with at least 3 letters)
      List<String> keywords = question
          .toLowerCase()
          .split(RegExp(r'\s+|[^\w\s]'))
          .where((word) => word.length >= 3)
          .toList();
      
      if (keywords.isEmpty) {
        return null;
      }
      
      // Build query to search for keywords in questions or answers
      String queryField = language == 'ar' ? 'question_ar' : 'question';
      String answerField = language == 'ar' ? 'answer_ar' : 'answer';
      
      List<String> conditions = [];
      List<dynamic> whereArgs = [];
      
      for (var keyword in keywords) {
        conditions.add('LOWER($queryField) LIKE ? OR LOWER(tags) LIKE ?');
        whereArgs.add('%$keyword%');
        whereArgs.add('%$keyword%');
      }
      
      String whereClause = conditions.join(' OR ');
      
      // Query QA table
      final List<Map<String, dynamic>> results = await db.query(
        'qa',
        columns: [queryField, answerField, 'tags'],
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      if (results.isNotEmpty) {
        // Find most relevant result (simplistic approach - pick first match)
        final qaData = results.first;
        
        // Get answer
        final answer = qaData[answerField];
        
        // Get related foods based on tags
        List<Food> relatedFoods = [];
        if (qaData['tags'] != null && qaData['tags'].isNotEmpty) {
          List<String> tags = qaData['tags'].split(',');
          
          for (var tag in tags) {
            if (tag.trim().isNotEmpty) {
              // Search for related foods
              final foodResults = await db.query(
                'foods',
                where: 'LOWER(name) LIKE ? OR LOWER(name_ar) LIKE ?',
                whereArgs: ['%${tag.trim()}%', '%${tag.trim()}%'],
                limit: 3,
              );
              
              if (foodResults.isNotEmpty) {
                relatedFoods.addAll(
                  foodResults.map((data) => Food.fromJson(data))
                );
              }
            }
          }
        }
        
        return ChatResponse(
          answer: answer,
          relatedFoods: relatedFoods,
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting local chat response: $e');
      return null;
    }
  }
  
  // Generate a fallback response when no match is found
  ChatResponse generateFallbackResponse(String language) {
    String answer = language == 'ar'
        ? 'ليس لدي معلومات محددة حول ذلك. يرجى محاولة السؤال عن أطعمة محددة، أو نصائح غذائية لمرضى السكري، أو إرشادات غذائية عامة لمرض السكري.'
        : 'I don\'t have specific information about that. Please try asking about specific foods, nutritional advice for diabetics, or general diabetes dietary guidelines.';
    
    return ChatResponse(
      answer: answer,
      relatedFoods: [],
    );
  }
  
  // Get chat response with fallback to local if online fails
  Future<ChatResponse> getChatResponseWithFallback(String question, String language) async {
    try {
      // First try API
      return await getChatResponseFromApi(question, language);
    } catch (e) {
      // Fall back to local database
      print('Falling back to local chat response: $e');
      final localResponse = await getChatResponseFromLocal(question, language);
      
      if (localResponse != null) {
        return localResponse;
      }
      
      // If no match found, return fallback response
      return generateFallbackResponse(language);
    }
  }
}

// Chat response model
class ChatResponse {
  final String answer;
  final List<Food> relatedFoods;
  
  ChatResponse({
    required this.answer,
    required this.relatedFoods,
  });
  
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    List<Food> foods = [];
    
    if (json['related_foods'] != null) {
      foods = (json['related_foods'] as List)
          .map((foodJson) => Food.fromJson(foodJson))
          .toList();
    }
    
    return ChatResponse(
      answer: json['answer'],
      relatedFoods: foods,
    );
  }
}
