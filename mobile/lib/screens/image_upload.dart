import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/image_recognition.dart';
import '../services/nutrition_service.dart';
import '../services/tts_service.dart';
import '../models/food.dart';
import '../widgets/accessibility_widgets.dart';
import 'nutrition_display.dart';

class ImageUploadScreen extends StatefulWidget {
  final TTSService ttsService;
  
  ImageUploadScreen({required this.ttsService});
  
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final ImageRecognitionService _recognitionService = ImageRecognitionService();
  final NutritionService _nutritionService = NutritionService();
  
  File? _image;
  bool _isProcessing = false;
  String _errorMessage = '';
  List<FoodDetection> _detectedFoods = [];
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              SemanticsWrapper(
                label: l10n.scanFoodInstructions,
                child: Text(
                  l10n.scanFoodInstructions,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Image preview or placeholder
              GestureDetector(
                onTap: _showImageSourceOptions,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _image != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 12),
                          Text(
                            l10n.tapToSelectImage,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Camera and gallery buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _getImage(ImageSource.camera),
                      icon: Icon(Icons.camera),
                      label: Text(l10n.takePhoto),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _getImage(ImageSource.gallery),
                      icon: Icon(Icons.photo_library),
                      label: Text(l10n.chooseFromGallery),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Manual food selection button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _navigateToManualSelection,
                icon: Icon(Icons.edit),
                label: Text(l10n.enterFoodManually),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Loading indicator or detection results
              if (_isProcessing)
                Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(l10n.analyzingImage),
                  ],
                )
              else if (_errorMessage.isNotEmpty)
                Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _clearError,
                      child: Text(l10n.tryAgain),
                    ),
                  ],
                )
              else if (_detectedFoods.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemanticsWrapper(
                      label: l10n.detectedFoods,
                      child: Text(
                        l10n.detectedFoods,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...List.generate(
                      _detectedFoods.length,
                      (index) => _buildDetectedFoodItem(_detectedFoods[index], locale),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _getDetailsForDetectedFoods(),
                      child: Text(l10n.getNutritionalDetails),
                    ),
                    SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _clearDetections,
                      child: Text(l10n.clearAndScanAgain),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetectedFoodItem(FoodDetection detection, String locale) {
    double confidencePercentage = detection.confidence * 100;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          detection.food,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${confidencePercentage.toStringAsFixed(0)}% ${AppLocalizations.of(context)!.confidence}',
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            detection.food.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        onTap: () => _speakFoodDetection(detection, locale),
      ),
    );
  }
  
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera),
                title: Text(AppLocalizations.of(context)!.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)!.chooseFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _getImage(ImageSource source) async {
    // Check and request permission
    PermissionStatus status;
    
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.photos.request();
    }
    
    if (status.isDenied) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.permissionDenied;
      });
      return;
    }
    
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        // User cancelled the picker
        return;
      }
      
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = true;
        _errorMessage = '';
        _detectedFoods = [];
      });
      
      // Process the image
      await _recognizeFood();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = '${AppLocalizations.of(context)!.imagePickerError}: $e';
      });
    }
  }
  
  Future<void> _recognizeFood() async {
    if (_image == null) return;
    
    try {
      final detections = await _recognitionService.recognizeFoodWithFallback(_image!);
      
      setState(() {
        _detectedFoods = detections;
        _isProcessing = false;
      });
      
      // Speak detection results
      if (detections.isNotEmpty) {
        final locale = Localizations.localeOf(context).languageCode;
        
        String text = '';
        if (locale == 'ar') {
          text = 'تم التعرف على الطعام التالي: ';
          for (var i = 0; i < detections.length; i++) {
            text += '${detections[i].food}';
            if (i < detections.length - 1) text += '، ';
          }
        } else {
          text = 'Detected the following food: ';
          for (var i = 0; i < detections.length; i++) {
            text += '${detections[i].food}';
            if (i < detections.length - 1) text += ', ';
          }
        }
        
        widget.ttsService.speak(text, languageCode: locale);
      }
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = '${AppLocalizations.of(context)!.recognitionError}: $e';
      });
    }
  }
  
  void _speakFoodDetection(FoodDetection detection, String locale) {
    double confidencePercentage = detection.confidence * 100;
    
    String text = '';
    if (locale == 'ar') {
      text = 'الطعام: ${detection.food}، نسبة الثقة: ${confidencePercentage.toStringAsFixed(0)}%';
    } else {
      text = 'Food: ${detection.food}, Confidence: ${confidencePercentage.toStringAsFixed(0)}%';
    }
    
    widget.ttsService.speak(text, languageCode: locale);
  }
  
  Future<void> _getDetailsForDetectedFoods() async {
    if (_detectedFoods.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      List<Food> foods = [];
      
      for (var detection in _detectedFoods) {
        try {
          // Get nutrition for each detected food
          final nutritionResponse = await _nutritionService.getNutritionWithFallback(detection.food);
          
          // Add confidence from detection to nutrition data
          Food food = nutritionResponse.foodInfo;
          food = Food(
            id: food.id,
            name: food.name,
            nameAr: food.nameAr,
            calories: food.calories,
            carbs: food.carbs,
            protein: food.protein,
            sugar: food.sugar,
            fat: food.fat,
            glycemicIndex: food.glycemicIndex,
            diabeticSuitability: food.diabeticSuitability,
            confidence: detection.confidence,
          );
          
          foods.add(food);
        } catch (e) {
          print('Error getting nutrition for ${detection.food}: $e');
          // Continue with other foods even if one fails
        }
      }
      
      setState(() {
        _isProcessing = false;
      });
      
      if (foods.isNotEmpty) {
        // Navigate to nutrition display
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionDisplayScreen(initialFoods: foods),
          ),
        );
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.noNutritionDataFound;
        });
      }
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = '${AppLocalizations.of(context)!.nutritionError}: $e';
      });
    }
  }
  
  void _clearDetections() {
    setState(() {
      _image = null;
      _detectedFoods = [];
      _errorMessage = '';
    });
  }
  
  void _clearError() {
    setState(() {
      _errorMessage = '';
    });
  }
  
  void _navigateToManualSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutritionDisplayScreen(initialFoods: []),
      ),
    );
  }
}
