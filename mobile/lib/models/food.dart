class Food {
  final int? id;
  final String name;
  final String nameAr;
  final double calories;
  final double carbs;
  final double protein;
  final double sugar;
  final double fat;
  final int glycemicIndex;
  final String diabeticSuitability;
  final double? confidence; // For AI recognition results
  
  Food({
    this.id,
    required this.name,
    required this.nameAr,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.sugar,
    required this.fat,
    required this.glycemicIndex,
    required this.diabeticSuitability,
    this.confidence,
  });
  
  // Create Food from JSON data
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      nameAr: json['name_ar'],
      calories: json['calories'].toDouble(),
      carbs: json['carbs'].toDouble(),
      protein: json['protein'].toDouble(),
      sugar: json['sugar'].toDouble(),
      fat: json['fat'].toDouble(),
      glycemicIndex: json['glycemic_index'],
      diabeticSuitability: json['diabetic_suitability'],
      confidence: json['confidence']?.toDouble(),
    );
  }
  
  // Convert Food to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'sugar': sugar,
      'fat': fat,
      'glycemic_index': glycemicIndex,
      'diabetic_suitability': diabeticSuitability,
      if (confidence != null) 'confidence': confidence,
    };
  }
  
  // Convert to string for display
  String getLocalizedName(String locale) {
    return locale == 'ar' ? nameAr : name;
  }
  
  // Get suitability color (for UI)
  getSuitabilityColor() {
    switch (diabeticSuitability.toLowerCase()) {
      case 'safe':
        return 0xFF4CAF50; // green
      case 'moderate':
        return 0xFFFFA000; // amber
      case 'avoid':
        return 0xFFF44336; // red
      default:
        return 0xFF9E9E9E; // grey
    }
  }
  
  // Get suitability icon (for UI)
  String getSuitabilityIcon() {
    switch (diabeticSuitability.toLowerCase()) {
      case 'safe':
        return 'check_circle';
      case 'moderate':
        return 'warning';
      case 'avoid':
        return 'cancel';
      default:
        return 'help';
    }
  }
  
  // Create Food object from scanner result and database data
  static Food fromDetectionAndData(
    Map<String, dynamic> detection, 
    Map<String, dynamic> nutritionData
  ) {
    return Food(
      id: nutritionData['id'],
      name: nutritionData['name'],
      nameAr: nutritionData['name_ar'],
      calories: nutritionData['calories'].toDouble(),
      carbs: nutritionData['carbs'].toDouble(),
      protein: nutritionData['protein'].toDouble(),
      sugar: nutritionData['sugar'].toDouble(),
      fat: nutritionData['fat'].toDouble(),
      glycemicIndex: nutritionData['glycemic_index'],
      diabeticSuitability: nutritionData['diabetic_suitability'],
      confidence: detection['confidence'],
    );
  }
}

// For recognized foods from the AI model
class FoodDetection {
  final String food;
  final double confidence;
  
  FoodDetection({
    required this.food,
    required this.confidence,
  });
  
  factory FoodDetection.fromJson(Map<String, dynamic> json) {
    return FoodDetection(
      food: json['food'],
      confidence: json['confidence'].toDouble(),
    );
  }
}

// For food nutrition responses
class NutritionResponse {
  final Food foodInfo;
  final String suitabilityExplanation;
  
  NutritionResponse({
    required this.foodInfo,
    required this.suitabilityExplanation,
  });
  
  factory NutritionResponse.fromJson(Map<String, dynamic> json) {
    return NutritionResponse(
      foodInfo: Food.fromJson(json['food_info']),
      suitabilityExplanation: json['suitability_explanation'],
    );
  }
}
