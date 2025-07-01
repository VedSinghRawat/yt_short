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
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), width: 2.0),
      ),
      title: SizedBox(child: Text(_titleText)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(child: Text(_contentText)),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLang = _selectedLang == PrefLang.hindi ? PrefLang.hinglish : PrefLang.hindi;
                  });
                },
                child: Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3), width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Fixed text labels
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'हिन्दी',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Hinglish',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Sliding orange pill that covers the unselected option
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        left: _selectedLang == PrefLang.hindi ? 98 : 2, // Opposite of selection
                        top: 2,
                        child: Container(
                          width: 96,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(23),
                            color: Theme.of(context).colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
