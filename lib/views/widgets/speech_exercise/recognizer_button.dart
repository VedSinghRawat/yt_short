import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/controllers/speech/speech_controller.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/views/widgets/lang_text.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';

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
    final responsiveness = ResponsivenessService(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Responsive sizing for different device types and orientations
    final buttonSize =
        isLandscape
            ? responsiveness.getResponsiveValues(mobile: 80.0, tablet: 70.0, largeTablet: 80.0)
            : responsiveness.getResponsiveValues(mobile: 80.0, tablet: 90.0, largeTablet: 100.0);

    final containerMaxWidth =
        isLandscape
            ? responsiveness.getResponsiveValues(mobile: 180.0, tablet: 160.0, largeTablet: 180.0)
            : responsiveness.getResponsiveValues(mobile: 180.0, tablet: 200.0, largeTablet: 220.0);

    final fontSize =
        isLandscape
            ? responsiveness.getResponsiveValues(mobile: 18.0, tablet: 16.0, largeTablet: 18.0)
            : responsiveness.getResponsiveValues(mobile: 18.0, tablet: 20.0, largeTablet: 22.0);

    // Check if we should show reset button
    final shouldShowResetButton = speechState.errorMessage == AppConstants.kResetStateError;

    return Column(
      children: [
        if (speechNotifier.isTestCompleted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleButtonPress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: speechNotifier.isPassed ? Colors.green[400] : Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                child: LangText.body(
                  hindi: speechNotifier.isPassed ? 'आगे बढ़ें' : 'पुनः प्रयास करें',
                  hinglish: speechNotifier.isPassed ? 'Aage badhe' : 'Dobara kare',
                ),
              ),
            ),
          )
        else
          Container(
            constraints: BoxConstraints(maxWidth: containerMaxWidth),
            child: Center(
              child: InkWell(
                onTap: _handleButtonPress,
                customBorder: const CircleBorder(),
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Center(
                    child:
                        shouldShowResetButton
                            ? Icon(Icons.refresh, size: buttonSize, color: Colors.redAccent)
                            : SvgPicture.asset(
                              'assets/svgs/mic-${speechState.isListening ? 'on' : 'off'}.svg',
                              width: buttonSize,
                              height: buttonSize,
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
              fontSize: fontSize,
            ),
          ),
      ],
    );
  }
}
