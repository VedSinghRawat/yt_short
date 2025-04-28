import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/active_mic.dart';
import 'package:myapp/features/speech_exercise/providers/speech_provider.dart';

class RecognizerButton extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  const RecognizerButton({super.key, required this.onContinue});

  @override
  ConsumerState<RecognizerButton> createState() => _RecognizerButtonState();
}

class _RecognizerButtonState extends ConsumerState<RecognizerButton> {
  Future<void> _handleButtonPress() async {
    final speechNotifier = ref.read(speechProvider.notifier);
    try {
      if (speechNotifier.isPassed) {
        await speechNotifier.stopListening();
        speechNotifier.reset();
        widget.onContinue();
        return;
      }

      if (speechNotifier.isFailed) {
        speechNotifier.reset();
        return;
      }

      final speechState = ref.read(speechProvider);
      if (speechState.isListening || speechNotifier.isTestCompleted) {
        await speechNotifier.stopListening();
        return;
      }

      await speechNotifier.startListening(context);
    } catch (e) {
      if (mounted) {
        _showRecognizerError();
      }
    }
  }

  void _showRecognizerError() {
    showSnackBar(
      context,
      message: ref
          .read(langProvider.notifier)
          .prefLangText(
            const PrefLangText(
              hindi: 'कुछ गलत हो गया, कृपया फिर से कोशिश करें',
              hinglish: 'Kuchh galat ho gaya, kripya dobara kosis karein',
            ),
          ),
      type: SnackBarType.error,
    );
  }

  @override
  void dispose() {
    if (mounted) ref.read(speechProvider.notifier).cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProvider);
    final speechNotifier = ref.read(speechProvider.notifier);

    return Column(
      children: [
        Container(
          width: speechNotifier.isTestCompleted ? 160 : 80,
          height: speechNotifier.isTestCompleted ? 60 : 80,
          decoration: BoxDecoration(
            shape: speechNotifier.isTestCompleted ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: speechNotifier.isTestCompleted ? BorderRadius.circular(40) : null,
            color:
                speechNotifier.isFailed
                    ? Colors.red.shade100
                    : speechState.isListening | speechNotifier.isPassed
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(128, 128, 128, 0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: _handleButtonPress,
            customBorder: speechNotifier.isPassed ? null : const CircleBorder(),
            child: Container(
              width: speechNotifier.isPassed ? 160 : 80,
              height: 80,
              decoration: BoxDecoration(
                shape: speechNotifier.isPassed ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: speechNotifier.isPassed ? BorderRadius.circular(40) : null,
              ),
              child: Center(
                child:
                    speechNotifier.isTestCompleted
                        ? Text(
                          ref
                              .read(langProvider.notifier)
                              .prefLangText(
                                PrefLangText(
                                  hindi: speechNotifier.isPassed ? 'आगे बढ़े' : 'पुनः प्रयास करें',
                                  hinglish: speechNotifier.isPassed ? 'Aage badhe' : 'Dobara kare',
                                ),
                              ),
                          style: TextStyle(
                            color: speechNotifier.isPassed ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : speechState.isListening
                        ? const ActiveMic()
                        : const Icon(Icons.mic_none, color: Colors.blue, size: 32),
              ),
            ),
          ),
        ),
        if (!speechNotifier.isTestCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              ref
                  .read(langProvider.notifier)
                  .prefLangText(
                    speechState.isListening
                        ? const PrefLangText(hindi: 'सुन रहे है...', hinglish: 'Listening...')
                        : const PrefLangText(hindi: 'बोलने के लिए टैप करें', hinglish: 'Bolne ke liye tap karein'),
                  ),
              style: TextStyle(color: speechState.isListening ? Colors.green : Colors.blue, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
