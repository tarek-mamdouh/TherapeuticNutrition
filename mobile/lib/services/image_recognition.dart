import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/food.dart';
import '../utils/constants.dart';

class ImageRecognitionService {
  // Singleton instance
  static final ImageRecognitionService _instance = ImageRecognitionService._internal();
  
  // Factory constructor
  factory ImageRecognitionService() {
    return _instance;
  }
  
  // Private constructor for singleton pattern
  ImageRecognitionService._internal();
  
  // Recognize food from image
  Future<List<FoodDetection>> recognizeFood(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/api/predict'));
      
      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path)
      );
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      // Check for successful response
      if (response.statusCode == 200) {
        // Parse JSON response
        List<dynamic> data = json.decode(response.body);
        List<FoodDetection> detections = data.map((item) => FoodDetection.fromJson(item)).toList();
        return detections;
      } else {
        print('Failed to recognize food. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to recognize food with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error recognizing food: $e');
      throw Exception('Error recognizing food: $e');
    }
  }
  
  // Simulated local recognition (offline fallback)
  Future<List<FoodDetection>> simulateLocalRecognition(File imageFile) async {
    // In a real implementation, this would use a TensorFlow Lite model loaded on the device
    // For now, we'll return a simulated result based on the image file size
    await Future.delayed(Duration(seconds: 2)); // Simulate processing time
    
    try {
      final fileSize = await imageFile.length();
      final randomSeed = fileSize % 100; // Use file size for pseudo-random but consistent results
      
      // Simulate 1-3 food detections based on the image
      List<FoodDetection> detections = [];
      
      // Common food items
      List<String> foods = [
        "apple", "banana", "bread", "rice", "chicken", "salad", 
        "yogurt", "eggs", "cheese", "hummus", "dates"
      ];
      
      // "Recognize" 1-2 foods
      int numDetections = 1 + (randomSeed % 2);
      for (int i = 0; i < numDetections; i++) {
        int foodIndex = (randomSeed + i * 7) % foods.length;
        double confidence = 0.7 + ((randomSeed + i * 3) % 30) / 100; // 0.7-0.99
        
        detections.add(FoodDetection(
          food: foods[foodIndex],
          confidence: confidence,
        ));
      }
      
      // Sort by confidence
      detections.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      return detections;
    } catch (e) {
      print('Error simulating local recognition: $e');
      throw Exception('Error with local recognition: $e');
    }
  }
  
  // Use the appropriate recognition method based on connectivity
  Future<List<FoodDetection>> recognizeFoodWithFallback(File imageFile) async {
    try {
      // First try online recognition
      return await recognizeFood(imageFile);
    } catch (e) {
      print('Falling back to local recognition: $e');
      // Fall back to local recognition if online fails
      return await simulateLocalRecognition(imageFile);
    }
  }
}
