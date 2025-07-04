import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/controllers/speech/speech_controller.dart';

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
        await speechNotifier.startListening(context);
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
          .read(langControllerProvider.notifier)
          .choose(
            hindi: 'कुछ गलत हो गया, कृपया फिर से कोशिश करें',
            hinglish: 'Kuchh galat ho gaya, kripya dobara kosis karein',
          ),
      type: SnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProvider);
    final speechNotifier = ref.read(speechProvider.notifier);

    return Column(
      children: [
        SizedBox(
          width: 150,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: speechNotifier.isTestCompleted ? BorderRadius.circular(40) : null,
              color: speechNotifier.isTestCompleted ? const Color.fromARGB(255, 241, 236, 236) : null,
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
                        speechNotifier.isTestCompleted
                            ? Text(
                              ref
                                  .read(langControllerProvider.notifier)
                                  .choose(
                                    hindi: speechNotifier.isPassed ? 'आगे बढ़े' : 'पुनः प्रयास करें',
                                    hinglish: speechNotifier.isPassed ? 'Aage badhe' : 'Dobara kare',
                                  ),
                              style: TextStyle(
                                color: speechNotifier.isPassed ? Colors.green.shade400 : Colors.red.shade400,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
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
        ),

        if (!speechNotifier.isTestCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              ref
                  .read(langControllerProvider.notifier)
                  .choose(
                    hindi: speechState.isListening ? 'सुन रहे है...' : 'बोलने से पहले टैप करें',
                    hinglish: speechState.isListening ? 'Listening...' : 'Bolne se pehle tap karein',
                  ),
              style: TextStyle(
                color: speechState.isListening ? Colors.green : Theme.of(context).colorScheme.secondary,
                fontSize: 18,
              ),
            ),
          ),
      ],
    );
  }
}
