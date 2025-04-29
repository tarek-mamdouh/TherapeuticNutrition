import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/food.dart';
import '../models/user.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService instance = DatabaseService._internal();
  
  // Factory constructor
  factory DatabaseService() {
    return instance;
  }
  
  // Private constructor for singleton pattern
  DatabaseService._internal();
  
  Database? _database;
  
  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDB();
    return _database!;
  }
  
  // Initialize the database
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'diabetic_nutrition.db');
    
    // Open the database
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }
  
  // Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Create foods table
    await db.execute('''
      CREATE TABLE foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        calories REAL NOT NULL,
        carbs REAL NOT NULL,
        protein REAL NOT NULL,
        sugar REAL NOT NULL,
        fat REAL NOT NULL,
        glycemic_index INTEGER NOT NULL,
        diabetic_suitability TEXT NOT NULL
      )
    ''');
    
    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        diabetes_type TEXT,
        preferences TEXT
      )
    ''');
    
    // Create qa table for chatbot
    await db.execute('''
      CREATE TABLE qa(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        question_ar TEXT NOT NULL,
        answer TEXT NOT NULL,
        answer_ar TEXT NOT NULL,
        tags TEXT
      )
    ''');
    
    // Populate with initial data
    await _populateInitialData(db);
  }
  
  // Populate database with initial data
  Future<void> _populateInitialData(Database db) async {
    try {
      // Load foods data from JSON asset
      final String foodsJson = await rootBundle.loadString('assets/foods.json');
      final List<dynamic> foodsData = json.decode(foodsJson);
      
      // Insert foods data
      for (var food in foodsData) {
        await db.insert('foods', food);
      }
      
      // Add sample QA data
      await _populateSampleQA(db);
      
    } catch (e) {
      print('Error populating initial data: $e');
    }
  }
  
  // Populate sample QA data
  Future<void> _populateSampleQA(Database db) async {
    final List<Map<String, dynamic>> qaData = [
      {
        'question': 'Can diabetics eat bananas?',
        'question_ar': 'هل يمكن لمرضى السكري تناول الموز؟',
        'answer': 'Bananas can be consumed in moderation by diabetics. They have a moderate glycemic index (51), and contain fiber which helps slow sugar absorption. Limit to small or medium-sized bananas and consider pairing with protein.',
        'answer_ar': 'يمكن لمرضى السكري تناول الموز باعتدال. لديه مؤشر جلايسيمي معتدل (51)، ويحتوي على الألياف التي تساعد على إبطاء امتصاص السكر. حدد تناولك للموز صغير أو متوسط الحجم وفكر في تناوله مع البروتين.',
        'tags': 'fruit,banana,glycemic index'
      },
      {
        'question': 'What fruits are best for diabetics?',
        'question_ar': 'ما هي أفضل الفواكه لمرضى السكري؟',
        'answer': 'Best fruits for diabetics include berries (strawberries, blueberries), apples, pears, oranges, and peaches. These have lower glycemic indexes and sugar content. Always eat in moderation and pair with protein when possible.',
        'answer_ar': 'أفضل الفواكه لمرضى السكري تشمل التوت (الفراولة، التوت الأزرق)، التفاح، الكمثرى، البرتقال، والخوخ. هذه الفواكه لها مؤشرات جلايسيمية وكمية سكر أقل. تناولها دائمًا باعتدال ومع البروتين إن أمكن.',
        'tags': 'fruit,glycemic index,sugar,apple,orange'
      },
      {
        'question': 'Is brown rice better than white rice for diabetics?',
        'question_ar': 'هل الأرز البني أفضل من الأرز الأبيض لمرضى السكري؟',
        'answer': 'Yes, brown rice is better for diabetics than white rice. Brown rice has a lower glycemic index (50 vs. 73 for white rice), more fiber, and causes a slower rise in blood sugar. Still, portion control is important.',
        'answer_ar': 'نعم، الأرز البني أفضل لمرضى السكري من الأرز الأبيض. الأرز البني له مؤشر جلايسيمي أقل (50 مقابل 73 للأرز الأبيض)، وألياف أكثر، ويسبب ارتفاعًا أبطأ في نسبة السكر في الدم. ومع ذلك، ضبط الكمية مهم.',
        'tags': 'rice,carbs,glycemic index'
      }
    ];
    
    for (var qa in qaData) {
      await db.insert('qa', qa);
    }
  }
  
  // Initialize the database with required data
  Future<void> initializeDatabase() async {
    await database;
  }
  
  // Get user by ID
  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return User.fromJson(result.first);
    }
    
    return null;
  }
  
  // Get first user (for simple app with one user)
  Future<User?> getFirstUser() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return User.fromJson(result.first);
    }
    
    return null;
  }
  
  // Insert or update user
  Future<void> saveUser(User user) async {
    final db = await database;
    
    if (user.id != null) {
      // Update existing user
      await db.update(
        'users',
        user.toJson(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } else {
      // Insert new user
      final id = await db.insert('users', user.toJson());
      user.id = id;
    }
  }
  
  // Get all foods
  Future<List<Food>> getAllFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('foods');
    
    return List.generate(
      result.length,
      (i) => Food.fromJson(result[i]),
    );
  }
  
  // Get food by name (case insensitive)
  Future<Food?> getFoodByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'foods',
      where: 'LOWER(name) = ? OR LOWER(name_ar) = ?',
      whereArgs: [name.toLowerCase(), name.toLowerCase()],
    );
    
    if (result.isNotEmpty) {
      return Food.fromJson(result.first);
    }
    
    return null;
  }
}
