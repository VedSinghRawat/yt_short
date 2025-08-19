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
        // Completed state → full-width button like ArrangeExercise
        if (speechNotifier.isTestCompleted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleButtonPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: speechNotifier.isPassed ? Colors.green.shade400 : Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              child: LangText.body(
                hindi: speechNotifier.isPassed ? 'आगे बढ़ें' : 'पुनः प्रयास करें',
                hinglish: speechNotifier.isPassed ? 'Aage badhe' : 'Dobara kare',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
        else
          // In-progress state → mic/reset circle as before
          Container(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Center(
              child: InkWell(
                onTap: _handleButtonPress,
                customBorder: const CircleBorder(),
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Center(
                    child:
                        shouldShowResetButton
                            ? const Icon(Icons.refresh, size: 80, color: Colors.redAccent)
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
