import 'package:flutter/material.dart';
import 'package:myapp/models/models.dart';

class LanguagePreferenceDialog extends StatefulWidget {
  const LanguagePreferenceDialog({super.key});

  @override
  State<LanguagePreferenceDialog> createState() => _LanguagePreferenceDialogState();
}

class _LanguagePreferenceDialogState extends State<LanguagePreferenceDialog> {
  PrefLang _selectedLang = PrefLang.hinglish; // Default selection

  String get _titleText {
    return _selectedLang == PrefLang.hindi ? 'आपकी पसंदीदा भाषा क्या है?' : 'Aapki pasandida bhasha kya hai?';
  }

  String get _contentText {
    return _selectedLang == PrefLang.hindi
        ? 'वह भाषा चुनें जिसमें आप सबसे अधिक सहज हैं।'
        : 'Vo bhasha chunen jis mein aap sabse adhik sahaj hain.';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 2.0),
      ),
      title: SizedBox(height: 60, child: Text(_titleText)),
      content: SizedBox(
        height: 140,
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50, child: Text(_contentText)),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), width: 2),
                ),
                child: Stack(
                  children: [
                    // Animated sliding background (behind text)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: _selectedLang == PrefLang.hindi ? 2 : 98,
                      top: 4,
                      child: Container(
                        width: 92,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23),
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Fixed text labels (on top of background)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLang = PrefLang.hindi;
                              });
                            },
                            child: Container(
                              height: 50,
                              child: Center(
                                child: Text(
                                  'हिन्दी',
                                  style: TextStyle(
                                    color:
                                        _selectedLang == PrefLang.hindi
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLang = PrefLang.hinglish;
                              });
                            },
                            child: Container(
                              height: 50,
                              child: Center(
                                child: Text(
                                  'Hinglish',
                                  style: TextStyle(
                                    color:
                                        _selectedLang == PrefLang.hinglish
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_selectedLang);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            ),
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }
}
