import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food.dart';
import '../utils/constants.dart';
import 'database_service.dart';

class NutritionService {
  // Singleton instance
  static final NutritionService _instance = NutritionService._internal();
  final DatabaseService _databaseService = DatabaseService.instance;
  
  // Factory constructor
  factory NutritionService() {
    return _instance;
  }
  
  // Private constructor for singleton pattern
  NutritionService._internal();
  
  // Get nutrition data for a food from online API
  Future<NutritionResponse> getNutritionFromApi(String foodName) async {
    try {
      // Make API request
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/nutrition/$foodName'),
      );
      
      // Check for successful response
      if (response.statusCode == 200) {
        // Parse response
        Map<String, dynamic> data = json.decode(response.body);
        return NutritionResponse.fromJson(data);
      } else {
        print('Failed to get nutrition data. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to get nutrition data with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting nutrition data: $e');
      throw Exception('Error getting nutrition data: $e');
    }
  }
  
  // Get nutrition data for a food from local database
  Future<NutritionResponse?> getNutritionFromLocal(String foodName) async {
    try {
      final db = await _databaseService.database;
      
      // Query foods table for food with name
      final List<Map<String, dynamic>> results = await db.query(
        'foods',
        where: 'LOWER(name) = ? OR LOWER(name_ar) = ?',
        whereArgs: [foodName.toLowerCase(), foodName.toLowerCase()],
      );
      
      if (results.isNotEmpty) {
        final foodData = results.first;
        
        // Create Food object
        final food = Food.fromJson(foodData);
        
        // Create explanation
        final explanation = _generateExplanation(food);
        
        return NutritionResponse(
          foodInfo: food,
          suitabilityExplanation: explanation,
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting local nutrition data: $e');
      return null;
    }
  }
  
  // Get nutrition data with fallback to local if online fails
  Future<NutritionResponse> getNutritionWithFallback(String foodName) async {
    try {
      // First try API
      return await getNutritionFromApi(foodName);
    } catch (e) {
      // Fall back to local database
      print('Falling back to local nutrition data: $e');
      final localData = await getNutritionFromLocal(foodName);
      
      if (localData != null) {
        return localData;
      }
      
      // If no data found in local database
      throw Exception('No nutrition data found for $foodName');
    }
  }
  
  // Generate explanation text based on food data
  String _generateExplanation(Food food) {
    String explanation = '';
    
    // Base explanation based on suitability
    switch (food.diabeticSuitability.toLowerCase()) {
      case 'safe':
        explanation = '${food.name} is generally safe for diabetic patients. ';
        break;
      case 'moderate':
        explanation = '${food.name} should be consumed in moderation by diabetic patients. ';
        break;
      case 'avoid':
        explanation = '${food.name} should generally be avoided by diabetic patients. ';
        break;
      default:
        explanation = 'No specific suitability information is available for ${food.name}. ';
    }
    
    // Add details based on nutritional values
    if (food.glycemicIndex > 0) {
      if (food.glycemicIndex < 55) {
        explanation += 'It has a low glycemic index of ${food.glycemicIndex}, which means it will cause a slower rise in blood sugar. ';
      } else if (food.glycemicIndex < 70) {
        explanation += 'It has a medium glycemic index of ${food.glycemicIndex}, so monitor your portion sizes. ';
      } else {
        explanation += 'It has a high glycemic index of ${food.glycemicIndex}, which can cause rapid blood sugar spikes. ';
      }
    }
    
    if (food.sugar > 10) {
      explanation += 'It contains ${food.sugar}g of sugar per serving, which is relatively high. ';
    } else if (food.sugar > 5) {
      explanation += 'It contains a moderate amount of sugar (${food.sugar}g per serving). ';
    } else {
      explanation += 'It\'s low in sugar (${food.sugar}g per serving). ';
    }
    
    if (food.carbs > 30) {
      explanation += 'With ${food.carbs}g of carbs, this is a high-carb food that should be carefully portioned. ';
    } else if (food.carbs > 15) {
      explanation += 'It contains a moderate amount of carbs (${food.carbs}g). ';
    } else {
      explanation += 'It\'s relatively low in carbs (${food.carbs}g). ';
    }
    
    return explanation;
  }
  
  // Get all foods from local database
  Future<List<Food>> getAllFoods() async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> results = await db.query('foods');
      
      return results.map((data) => Food.fromJson(data)).toList();
    } catch (e) {
      print('Error getting all foods: $e');
      return [];
    }
  }
  
  // Search foods by name
  Future<List<Food>> searchFoods(String query, String locale) async {
    try {
      final db = await _databaseService.database;
      
      String searchField = locale == 'ar' ? 'name_ar' : 'name';
      
      final List<Map<String, dynamic>> results = await db.query(
        'foods',
        where: 'LOWER($searchField) LIKE ?',
        whereArgs: ['%${query.toLowerCase()}%'],
      );
      
      return results.map((data) => Food.fromJson(data)).toList();
    } catch (e) {
      print('Error searching foods: $e');
      return [];
    }
  }
}
