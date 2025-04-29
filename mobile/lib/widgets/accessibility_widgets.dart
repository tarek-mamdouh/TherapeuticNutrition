import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A widget that wraps its child with a Semantics widget for better accessibility
class SemanticsWrapper extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool excludeSemantics;
  
  const SemanticsWrapper({
    Key? key,
    required this.child,
    required this.label,
    this.hint,
    this.excludeSemantics = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }
}

/// A button that provides quick access to accessibility settings
class AccessibilityButton extends StatelessWidget {
  final Locale currentLocale;
  final ThemeMode currentThemeMode;
  final bool highContrast;
  final double textScaleFactor;
  final Function(Locale) setLocale;
  final Function(ThemeMode) setThemeMode;
  final Function(bool) setHighContrast;
  final Function(double) setTextScaleFactor;
  
  const AccessibilityButton({
    Key? key,
    required this.currentLocale,
    required this.currentThemeMode,
    required this.highContrast,
    required this.textScaleFactor,
    required this.setLocale,
    required this.setThemeMode,
    required this.setHighContrast,
    required this.setTextScaleFactor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return IconButton(
      icon: Icon(Icons.accessibility_new),
      onPressed: () => _showAccessibilityMenu(context, l10n),
      tooltip: 'Accessibility',
    );
  }
  
  void _showAccessibilityMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                l10n.accessibilitySettings,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              // Language toggle
              ListTile(
                title: Text(l10n.language),
                trailing: ToggleButtons(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('EN'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('عربي'),
                    ),
                  ],
                  isSelected: [
                    currentLocale.languageCode == 'en',
                    currentLocale.languageCode == 'ar',
                  ],
                  onPressed: (index) {
                    setLocale(Locale(index == 0 ? 'en' : 'ar'));
                    Navigator.pop(context);
                  },
                ),
              ),
              
              // Theme toggle
              SwitchListTile(
                title: Text(l10n.darkTheme),
                value: currentThemeMode == ThemeMode.dark,
                onChanged: (value) {
                  setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              
              // High contrast toggle
              SwitchListTile(
                title: Text(l10n.highContrast),
                value: highContrast,
                onChanged: (value) {
                  setHighContrast(value);
                },
              ),
              
              // Text size slider
              ListTile(
                title: Text(l10n.textSize),
                subtitle: Slider(
                  value: textScaleFactor,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: textScaleFactor.toStringAsFixed(1) + 'x',
                  onChanged: (value) {
                    setTextScaleFactor(value);
                  },
                ),
              ),
              
              SizedBox(height: 8),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(l10n.loading.contains('...') ? 'Close' : 'إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A button that provides text-to-speech functionality
class SpeakButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;
  
  const SpeakButton({
    Key? key,
    required this.onPressed,
    required this.tooltip,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.volume_up),
      onPressed: onPressed,
      tooltip: tooltip,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }
}

/// A high-contrast container for better visibility
class HighContrastContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  
  const HighContrastContainer({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        border: Border.all(
          color: isDarkMode ? Colors.white : Colors.black,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// A card with high contrast border for better visibility
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const AccessibleCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? 
                 (isDarkMode ? Colors.grey[850] : Colors.white),
          border: Border.all(
            color: isDarkMode ? Colors.grey[400]! : Colors.grey[800]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (onTap != null)
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}
