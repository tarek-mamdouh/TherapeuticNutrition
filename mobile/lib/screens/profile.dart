import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user.dart';
import '../services/database_service.dart';
import '../widgets/accessibility_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final Function(Locale) setLocale;
  final Function(ThemeMode) setThemeMode;
  final Function(bool) setHighContrast;
  final Function(double) setTextScaleFactor;
  final Locale currentLocale;
  final ThemeMode currentThemeMode;
  final bool highContrast;
  final double textScaleFactor;
  final Function(User) onUserUpdated;
  
  ProfileScreen({
    required this.user,
    required this.setLocale,
    required this.setThemeMode,
    required this.setHighContrast,
    required this.setTextScaleFactor,
    required this.currentLocale,
    required this.currentThemeMode,
    required this.highContrast,
    required this.textScaleFactor,
    required this.onUserUpdated,
  });
  
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String? _selectedDiabetesType;
  List<String> _selectedPreferences = [];
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _ageController = TextEditingController(text: widget.user.age?.toString() ?? '');
    _selectedDiabetesType = widget.user.diabetesType;
    _selectedPreferences = widget.user.getPreferencesList();
  }
  
  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Update user object
      final updatedUser = widget.user.copyWith(
        name: _nameController.text,
        age: int.tryParse(_ageController.text),
        diabetesType: _selectedDiabetesType,
      );
      
      // Set preferences
      updatedUser.setPreferencesList(_selectedPreferences);
      
      // Save to database
      await _databaseService.saveUser(updatedUser);
      
      // Notify parent
      widget.onUserUpdated(updatedUser);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileSaved),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.errorSavingProfile}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              SemanticsWrapper(
                label: l10n.profileInformation,
                child: Text(
                  l10n.profileInformation,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              SizedBox(height: 24),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              
              // Age
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: l10n.age,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              
              // Diabetes Type
              DropdownButtonFormField<String>(
                value: _selectedDiabetesType,
                decoration: InputDecoration(
                  labelText: l10n.diabetesType,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                items: DiabetesTypes.types.map((type) {
                  String displayText = type;
                  
                  if (locale == 'ar' && DiabetesTypes.typesAr.containsKey(type)) {
                    displayText = DiabetesTypes.typesAr[type]!;
                  } else {
                    // Format for English display
                    switch (type) {
                      case 'type1':
                        displayText = 'Type 1';
                        break;
                      case 'type2':
                        displayText = 'Type 2';
                        break;
                      case 'gestational':
                        displayText = 'Gestational';
                        break;
                      case 'prediabetes':
                        displayText = 'Prediabetes';
                        break;
                    }
                  }
                  
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDiabetesType = value;
                  });
                },
              ),
              SizedBox(height: 16),
              
              // Dietary Preferences
              SemanticsWrapper(
                label: l10n.dietaryPreferences,
                child: Text(
                  l10n.dietaryPreferences,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: DietaryPreferences.options.map((preference) {
                  final isSelected = _selectedPreferences.contains(preference);
                  final displayText = locale == 'ar' && DietaryPreferences.optionsAr.containsKey(preference)
                      ? DietaryPreferences.optionsAr[preference]!
                      : preference;
                  
                  return FilterChip(
                    label: Text(displayText),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPreferences.add(preference);
                        } else {
                          _selectedPreferences.remove(preference);
                        }
                      });
                    },
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
              SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(l10n.saving),
                          ],
                        )
                      : Text(l10n.saveProfile),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              Divider(),
              SizedBox(height: 16),
              
              // Accessibility Settings
              SemanticsWrapper(
                label: l10n.accessibilitySettings,
                child: Text(
                  l10n.accessibilitySettings,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              SizedBox(height: 16),
              
              // Language
              Card(
                child: ListTile(
                  title: Text(l10n.language),
                  subtitle: Text(locale == 'ar' ? 'العربية' : 'English'),
                  leading: Icon(Icons.language),
                  trailing: DropdownButton<String>(
                    value: locale,
                    onChanged: (value) {
                      if (value != null) {
                        widget.setLocale(Locale(value));
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text('العربية'),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              
              // Theme Mode
              Card(
                child: ListTile(
                  title: Text(l10n.theme),
                  subtitle: Text(
                    widget.currentThemeMode == ThemeMode.light
                        ? l10n.lightTheme
                        : l10n.darkTheme,
                  ),
                  leading: Icon(
                    widget.currentThemeMode == ThemeMode.light
                        ? Icons.wb_sunny
                        : Icons.nightlight_round,
                  ),
                  trailing: Switch(
                    value: widget.currentThemeMode == ThemeMode.dark,
                    onChanged: (value) {
                      widget.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ),
              ),
              SizedBox(height: 8),
              
              // High Contrast
              Card(
                child: ListTile(
                  title: Text(l10n.highContrast),
                  subtitle: Text(l10n.highContrastDescription),
                  leading: Icon(Icons.contrast),
                  trailing: Switch(
                    value: widget.highContrast,
                    onChanged: (value) {
                      widget.setHighContrast(value);
                    },
                  ),
                ),
              ),
              SizedBox(height: 8),
              
              // Text Size
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(l10n.textSize),
                      subtitle: Text(_getTextSizeLabel(widget.textScaleFactor, l10n)),
                      leading: Icon(Icons.text_fields),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('A', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Slider(
                              value: widget.textScaleFactor,
                              min: 0.8,
                              max: 1.5,
                              divisions: 7,
                              onChanged: (value) {
                                widget.setTextScaleFactor(value);
                              },
                            ),
                          ),
                          Text('A', style: TextStyle(fontSize: 28)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Text preview
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.textPreview,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        l10n.sampleText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getTextSizeLabel(double scaleFactor, AppLocalizations l10n) {
    if (scaleFactor <= 0.9) {
      return l10n.textSizeSmall;
    } else if (scaleFactor <= 1.1) {
      return l10n.textSizeNormal;
    } else if (scaleFactor <= 1.3) {
      return l10n.textSizeLarge;
    } else {
      return l10n.textSizeExtraLarge;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
