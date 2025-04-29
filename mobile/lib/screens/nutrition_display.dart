import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/food.dart';
import '../services/nutrition_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility_widgets.dart';

class NutritionDisplayScreen extends StatefulWidget {
  final List<Food> initialFoods;

  NutritionDisplayScreen({required this.initialFoods});

  @override
  _NutritionDisplayScreenState createState() => _NutritionDisplayScreenState();
}

class _NutritionDisplayScreenState extends State<NutritionDisplayScreen> {
  final NutritionService _nutritionService = NutritionService();
  final TTSService _ttsService = TTSService();
  final TextEditingController _searchController = TextEditingController();

  List<Food> _currentFoods = [];
  List<Food> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _currentFoods = List.from(widget.initialFoods);
    });

    if (_currentFoods.isEmpty) {
      // If no initial foods, show search interface
      setState(() {
        _isSearching = true;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _searchFoods(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final results = await _nutritionService.searchFoods(query, locale);

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${AppLocalizations.of(context)!.searchError}: $e';
      });
    }
  }

  void _addFoodToCurrentList(Food food) {
    setState(() {
      // Check if food is already in the list
      if (!_currentFoods.any((f) => f.id == food.id)) {
        _currentFoods.add(food);
      }
      
      // Clear search
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removeFood(int index) {
    setState(() {
      _currentFoods.removeAt(index);
    });
  }

  void _speakFoodDetails(Food food) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    
    String suitabilityText = '';
    switch (food.diabeticSuitability.toLowerCase()) {
      case 'safe':
        suitabilityText = l10n.safe;
        break;
      case 'moderate':
        suitabilityText = l10n.moderate;
        break;
      case 'avoid':
        suitabilityText = l10n.avoid;
        break;
      default:
        suitabilityText = food.diabeticSuitability;
    }
    
    _ttsService.speakFoodInfo(
      food.getLocalizedName(locale),
      food.calories.toString(),
      food.carbs.toString(),
      suitabilityText,
      locale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search section
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SemanticsWrapper(
                              label: l10n.searchOrAddFood,
                              child: Text(
                                l10n.searchOrAddFood,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: l10n.searchFoodHint,
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: _searchFoods,
                            ),
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            if (_searchResults.isNotEmpty)
                              Container(
                                height: 200,
                                margin: EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final food = _searchResults[index];
                                    return ListTile(
                                      title: Text(food.getLocalizedName(locale)),
                                      subtitle: Text(
                                        '${l10n.calories}: ${food.calories} | ${l10n.carbs}: ${food.carbs}g',
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.add_circle),
                                        color: Theme.of(context).colorScheme.primary,
                                        onPressed: () => _addFoodToCurrentList(food),
                                      ),
                                      onTap: () => _speakFoodDetails(food),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Current foods section
                    if (_currentFoods.isNotEmpty) ...[
                      SemanticsWrapper(
                        label: l10n.selectedFoods,
                        child: Text(
                          l10n.selectedFoods,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _currentFoods.length,
                        itemBuilder: (context, index) {
                          final food = _currentFoods[index];
                          
                          Color suitabilityColor;
                          String suitabilityText;
                          IconData suitabilityIcon;
                          
                          switch (food.diabeticSuitability.toLowerCase()) {
                            case 'safe':
                              suitabilityColor = Color(0xFF4CAF50);
                              suitabilityText = l10n.safe;
                              suitabilityIcon = Icons.check_circle;
                              break;
                            case 'moderate':
                              suitabilityColor = Color(0xFFFFA000);
                              suitabilityText = l10n.moderate;
                              suitabilityIcon = Icons.warning;
                              break;
                            case 'avoid':
                              suitabilityColor = Color(0xFFF44336);
                              suitabilityText = l10n.avoid;
                              suitabilityIcon = Icons.cancel;
                              break;
                            default:
                              suitabilityColor = Color(0xFF9E9E9E);
                              suitabilityText = food.diabeticSuitability;
                              suitabilityIcon = Icons.help;
                          }
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ExpansionTile(
                              title: Text(
                                food.getLocalizedName(locale),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    suitabilityIcon,
                                    color: suitabilityColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    suitabilityText,
                                    style: TextStyle(color: suitabilityColor),
                                  ),
                                ],
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  food.getLocalizedName(locale).substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.volume_up),
                                    onPressed: () => _speakFoodDetails(food),
                                    tooltip: l10n.speakFoodDetails,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => _removeFood(index),
                                    tooltip: l10n.removeFood,
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildNutritionRow(l10n.calories, '${food.calories}', Icons.local_fire_department),
                                      _buildNutritionRow(l10n.carbs, '${food.carbs}g', Icons.grain),
                                      _buildNutritionRow(l10n.protein, '${food.protein}g', Icons.fitness_center),
                                      _buildNutritionRow(l10n.sugar, '${food.sugar}g', Icons.icecream),
                                      _buildNutritionRow(l10n.fat, '${food.fat}g', Icons.opacity),
                                      _buildNutritionRow(l10n.glycemicIndex, '${food.glycemicIndex}', Icons.speed),
                                      SizedBox(height: 8),
                                      
                                      Divider(),
                                      SizedBox(height: 8),
                                      
                                      // Suitability explanation (with placeholder for now)
                                      Text(
                                        l10n.diabeticSuitability,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            suitabilityIcon,
                                            color: suitabilityColor,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              suitabilityText,
                                              style: TextStyle(
                                                color: suitabilityColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _generateExplanation(food, locale, l10n),
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onExpansionChanged: (expanded) {
                                if (expanded) {
                                  _speakFoodDetails(food);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ] else if (!_isSearching) ...[
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.no_food,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              l10n.noFoodsSelected,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isSearching = true;
                                });
                              },
                              icon: Icon(Icons.search),
                              label: Text(l10n.searchFoods),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 32),
                    
                    // Nutritional summary if multiple foods
                    if (_currentFoods.length > 1)
                      _buildNutritionSummary(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNutritionRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    final l10n = AppLocalizations.of(context)!;
    
    // Calculate totals
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalSugar = 0;
    double totalFat = 0;
    
    for (var food in _currentFoods) {
      totalCalories += food.calories;
      totalCarbs += food.carbs;
      totalProtein += food.protein;
      totalSugar += food.sugar;
      totalFat += food.fat;
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SemanticsWrapper(
              label: l10n.mealSummary,
              child: Text(
                l10n.mealSummary,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 16),
            _buildNutritionRow(l10n.totalCalories, '${totalCalories.toStringAsFixed(1)}', Icons.local_fire_department),
            _buildNutritionRow(l10n.totalCarbs, '${totalCarbs.toStringAsFixed(1)}g', Icons.grain),
            _buildNutritionRow(l10n.totalProtein, '${totalProtein.toStringAsFixed(1)}g', Icons.fitness_center),
            _buildNutritionRow(l10n.totalSugar, '${totalSugar.toStringAsFixed(1)}g', Icons.icecream),
            _buildNutritionRow(l10n.totalFat, '${totalFat.toStringAsFixed(1)}g', Icons.opacity),
            
            SizedBox(height: 16),
            
            // Overall suitability assessment
            Text(
              l10n.overallSuitability,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _getOverallSuitabilityText(totalCarbs, totalSugar),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Speak the summary
                final locale = Localizations.localeOf(context).languageCode;
                
                String text = '';
                if (locale == 'ar') {
                  text = 'ملخص الوجبة: '
                      'السعرات الحرارية: ${totalCalories.toStringAsFixed(1)}. '
                      'الكربوهيدرات: ${totalCarbs.toStringAsFixed(1)} جرام. '
                      'البروتين: ${totalProtein.toStringAsFixed(1)} جرام. '
                      'السكر: ${totalSugar.toStringAsFixed(1)} جرام. ';
                } else {
                  text = 'Meal summary: '
                      'Calories: ${totalCalories.toStringAsFixed(1)}. '
                      'Carbohydrates: ${totalCarbs.toStringAsFixed(1)} grams. '
                      'Protein: ${totalProtein.toStringAsFixed(1)} grams. '
                      'Sugar: ${totalSugar.toStringAsFixed(1)} grams. ';
                }
                
                _ttsService.speak(text, languageCode: locale);
              },
              icon: Icon(Icons.volume_up),
              label: Text(l10n.speakSummary),
            ),
          ],
        ),
      ),
    );
  }

  String _generateExplanation(Food food, String locale, AppLocalizations l10n) {
    String explanation = '';
    
    // Based on glycemic index
    if (food.glycemicIndex > 0) {
      if (food.glycemicIndex < 55) {
        explanation += locale == 'ar'
            ? 'له مؤشر جلايسيمي منخفض (${food.glycemicIndex})، مما يعني أنه سيسبب ارتفاعًا أبطأ في سكر الدم. '
            : 'It has a low glycemic index (${food.glycemicIndex}), which means it will cause a slower rise in blood sugar. ';
      } else if (food.glycemicIndex < 70) {
        explanation += locale == 'ar'
            ? 'له مؤشر جلايسيمي متوسط (${food.glycemicIndex})، لذا راقب أحجام الحصص. '
            : 'It has a medium glycemic index (${food.glycemicIndex}), so monitor your portion sizes. ';
      } else {
        explanation += locale == 'ar'
            ? 'له مؤشر جلايسيمي مرتفع (${food.glycemicIndex})، مما قد يسبب ارتفاعات سريعة في سكر الدم. '
            : 'It has a high glycemic index (${food.glycemicIndex}), which can cause rapid blood sugar spikes. ';
      }
    }
    
    // Based on sugar content
    if (food.sugar > 10) {
      explanation += locale == 'ar'
            ? 'يحتوي على ${food.sugar} جرام من السكر لكل حصة، وهو مرتفع نسبيًا. '
            : 'It contains ${food.sugar}g of sugar per serving, which is relatively high. ';
    } else if (food.sugar > 5) {
      explanation += locale == 'ar'
            ? 'يحتوي على كمية معتدلة من السكر (${food.sugar} جرام لكل حصة). '
            : 'It contains a moderate amount of sugar (${food.sugar}g per serving). ';
    } else {
      explanation += locale == 'ar'
            ? 'منخفض السكر (${food.sugar} جرام لكل حصة). '
            : 'It\'s low in sugar (${food.sugar}g per serving). ';
    }
    
    // Based on carbs
    if (food.carbs > 30) {
      explanation += locale == 'ar'
            ? 'مع ${food.carbs} جرام من الكربوهيدرات، هذا طعام عالي الكربوهيدرات يجب تقسيمه بعناية. '
            : 'With ${food.carbs}g of carbs, this is a high-carb food that should be carefully portioned. ';
    } else if (food.carbs > 15) {
      explanation += locale == 'ar'
            ? 'يحتوي على كمية معتدلة من الكربوهيدرات (${food.carbs} جرام). '
            : 'It contains a moderate amount of carbs (${food.carbs}g). ';
    } else {
      explanation += locale == 'ar'
            ? 'منخفض نسبيًا في الكربوهيدرات (${food.carbs} جرام). '
            : 'It\'s relatively low in carbs (${food.carbs}g). ';
    }
    
    return explanation;
  }

  String _getOverallSuitabilityText(double totalCarbs, double totalSugar) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    
    // Simplified assessment based on carbs and sugar
    if (totalCarbs > 60 || totalSugar > 30) {
      return locale == 'ar'
          ? 'هذه الوجبة عالية الكربوهيدرات أو السكر. يرجى مراعاة تقليل الحصص أو استبدال بعض العناصر بخيارات أقل في الكربوهيدرات.'
          : 'This meal is high in carbohydrates or sugar. Please consider reducing portions or replacing some items with lower-carb options.';
    } else if (totalCarbs > 30 || totalSugar > 15) {
      return locale == 'ar'
          ? 'هذه الوجبة معتدلة في محتواها من الكربوهيدرات والسكر. يوصى بمراقبة مستويات سكر الدم بعد تناولها.'
          : 'This meal is moderate in carbohydrate and sugar content. Monitoring blood sugar levels after consumption is recommended.';
    } else {
      return locale == 'ar'
          ? 'هذه الوجبة منخفضة نسبيًا في الكربوهيدرات والسكر، وقد تكون مناسبة لمعظم مرضى السكري كجزء من خطة وجبات متوازنة.'
          : 'This meal is relatively low in carbohydrates and sugar, and may be suitable for most diabetics as part of a balanced meal plan.';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
