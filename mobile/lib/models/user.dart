class User {
  int? id;
  String name;
  int? age;
  String? diabetesType;
  String? preferences;
  
  User({
    this.id,
    required this.name,
    this.age,
    this.diabetesType,
    this.preferences,
  });
  
  // Create User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      diabetesType: json['diabetes_type'],
      preferences: json['preferences'],
    );
  }
  
  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'diabetes_type': diabetesType,
      'preferences': preferences,
    };
  }
  
  // Create a copy of User with given fields replaced
  User copyWith({
    int? id,
    String? name,
    int? age,
    String? diabetesType,
    String? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      diabetesType: diabetesType ?? this.diabetesType,
      preferences: preferences ?? this.preferences,
    );
  }
  
  // Get diabetes type display text
  String getDiabetesTypeText() {
    switch (diabetesType) {
      case 'type1':
        return 'Type 1';
      case 'type2':
        return 'Type 2';
      case 'gestational':
        return 'Gestational';
      case 'prediabetes':
        return 'Prediabetes';
      default:
        return diabetesType ?? 'Not specified';
    }
  }
  
  // Convert preferences string to a list
  List<String> getPreferencesList() {
    if (preferences == null || preferences!.isEmpty) {
      return [];
    }
    return preferences!.split(',').map((p) => p.trim()).toList();
  }
  
  // Set preferences from a list
  void setPreferencesList(List<String> prefs) {
    preferences = prefs.join(',');
  }
  
  // Check if user profile is complete
  bool isProfileComplete() {
    return name.isNotEmpty && 
           age != null && 
           diabetesType != null && 
           diabetesType!.isNotEmpty;
  }
}

// Dietary preferences options
class DietaryPreferences {
  static const List<String> options = [
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'Dairy-free',
    'Low-carb',
    'Low-sugar',
    'Low-sodium',
    'Mediterranean',
    'Halal',
    'Kosher',
  ];
  
  static const Map<String, String> optionsAr = {
    'Vegetarian': 'نباتي',
    'Vegan': 'نباتي صرف',
    'Gluten-free': 'خالي من الغلوتين',
    'Dairy-free': 'خالي من منتجات الألبان',
    'Low-carb': 'قليل الكربوهيدرات',
    'Low-sugar': 'قليل السكر',
    'Low-sodium': 'قليل الصوديوم',
    'Mediterranean': 'متوسطي',
    'Halal': 'حلال',
    'Kosher': 'كوشير',
  };
}

// Diabetes types
class DiabetesTypes {
  static const List<String> types = [
    'type1',
    'type2',
    'gestational',
    'prediabetes',
  ];
  
  static const Map<String, String> typesAr = {
    'type1': 'النوع 1',
    'type2': 'النوع 2',
    'gestational': 'سكري الحمل',
    'prediabetes': 'ما قبل السكري',
  };
}
