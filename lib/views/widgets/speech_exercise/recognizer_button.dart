import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/controllers/speech/speech_controller.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/views/widgets/lang_text.dart';

class RecognizerButton extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final List<String> targetWords;

  const RecognizerButton({super.key, required this.onContinue, required this.targetWords});

  @override
  ConsumerState<RecognizerButton> createState() => _RecognizerButtonState();
}

class _RecognizerButtonState extends ConsumerState<RecognizerButton> {
  late final speechProv = speechProvider(targetWords: widget.targetWords);

  Future<void> _handleButtonPress() async {
    final speechNotifier = ref.read(speechProv.notifier);
    final speechState = ref.read(speechProv);

    // Check if we need to show reset button
    if (speechState.errorMessage == AppConstants.kResetStateError) {
      speechNotifier.resetState();
      return;
    }

    try {
      if (speechNotifier.isPassed) {
        await speechNotifier.stopListening();
        speechNotifier.resetState();
        widget.onContinue();
        return;
      }

      if (speechNotifier.isFailed) {
        speechNotifier.resetState();
        await speechNotifier.startListening(context);
        return;
      }

      final speechState = ref.read(speechProv);
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
      message: choose(
        hindi: 'कुछ गलत हो गया, कृपया फिर से कोशिश करें',
        hinglish: 'Kuchh galat ho gaya, kripya dobara kosis karein',
        lang: ref.read(langControllerProvider),
      ),
      type: SnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProv);
    final speechNotifier = ref.read(speechProv.notifier);

    // Check if we should show reset button
    final shouldShowResetButton = speechState.errorMessage == AppConstants.kResetStateError;

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: speechNotifier.isTestCompleted ? BorderRadius.circular(40) : null,
            color:
                speechNotifier.isTestCompleted
                    ? speechNotifier.isPassed
                        ? Colors.green.shade400
                        : Colors.red.shade400
                    : null,
            boxShadow: [
              if (speechNotifier.isTestCompleted)
                const BoxShadow(
                  color: Color.fromRGBO(128, 128, 128, 0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: InkWell(
              onTap: _handleButtonPress,
              customBorder: speechNotifier.isPassed ? null : const CircleBorder(),
              child: Container(
                decoration: BoxDecoration(
                  shape: speechNotifier.isPassed ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: speechNotifier.isPassed ? BorderRadius.circular(40) : null,
                ),
                child: Center(
                  child:
                      shouldShowResetButton
                          ? const Icon(Icons.refresh, size: 80, color: Colors.redAccent)
                          : speechNotifier.isTestCompleted
                          ? LangText.body(
                            hindi: speechNotifier.isPassed ? 'आगे बढ़े' : 'पुनः प्रयास करें',
                            hinglish: speechNotifier.isPassed ? 'Aage badhe' : 'Dobara kare',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          )
                          : SvgPicture.asset(
                            'assets/svgs/mic-${speechState.isListening ? 'on' : 'off'}.svg',
                            width: 80,
                            height: 80,
                          ),
                ),
              ),
            ),
          ),
        ),

        if (!speechNotifier.isTestCompleted)
          LangText.body(
            hindi:
                shouldShowResetButton
                    ? 'कुछ एरर आ गया है, रीसेट करें'
                    : speechState.isListening
                    ? 'सुन रहे है...'
                    : 'बोलने से पहले टैप करें',
            hinglish:
                shouldShowResetButton
                    ? 'Kuch error agya hai, reset karien'
                    : speechState.isListening
                    ? 'Listening...'
                    : 'Bolne se pehle tap karein',
            style: TextStyle(
              color:
                  shouldShowResetButton
                      ? Colors.orange
                      : speechState.isListening
                      ? Colors.green
                      : Theme.of(context).colorScheme.secondary,
              fontSize: 18,
            ),
          ),
      ],
    );
  }
}
