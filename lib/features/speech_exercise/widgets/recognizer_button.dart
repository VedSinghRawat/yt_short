import 'package:flutter/material.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/active_mic.dart';
import 'package:myapp/features/speech_exercise/widgets/recognizer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecognizerButton extends StatefulWidget {
  final bool testCompleted;
  final bool passed;
  final bool failed;
  final VoidCallback onContinue;
  final Function(SpeechRecognitionResult) onResult;
  final VoidCallback onStopListening;

  const RecognizerButton({
    super.key,
    required this.testCompleted,
    required this.passed,
    required this.failed,
    required this.onContinue,
    required this.onResult,
    required this.onStopListening,
  });

  @override
  State<RecognizerButton> createState() => _RecognizerButtonState();
}

class _RecognizerButtonState extends State<RecognizerButton> {
  late SpeechRecognizer _recognizer;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _recognizer = SpeechRecognizer(
      onResult: widget.onResult,
      onStopListening: widget.onStopListening,
      onStatusChange: (status) {
        if (status == stt.SpeechToText.doneStatus && isListening) {
          setState(() {
            isListening = false;
          });
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _recognizer.stopListening();

    setState(() {
      isListening = false;
    });
  }

  Future<void> _handleButtonPress() async {
    try {
      if (widget.passed) {
        await stopListening();
        widget.onContinue();
      } else {
        if (isListening || widget.testCompleted) {
          await stopListening();
        } else {
          await startListening();
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          'An error occurred while starting the recognizer',
        );
      }
    }
  }

  Future<void> startListening() async {
    try {
      await _recognizer.startListening(context);
      setState(() {
        isListening = true;
      });
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          'An error occurred while starting the recognizer',
        );
      }
    }
  }

  @override
  void dispose() {
    _recognizer.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: widget.testCompleted ? 160 : 80,
          height: widget.testCompleted ? 60 : 80,
          decoration: BoxDecoration(
            shape: widget.testCompleted ? BoxShape.rectangle : BoxShape.circle,
            borderRadius:
                widget.testCompleted ? BorderRadius.circular(40) : null,
            color:
                widget.failed
                    ? Colors.red.shade100
                    : isListening | widget.passed
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
            customBorder: widget.passed ? null : const CircleBorder(),
            child: Container(
              width: widget.passed ? 160 : 80,
              height: 80,
              decoration: BoxDecoration(
                shape: widget.passed ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: widget.passed ? BorderRadius.circular(40) : null,
              ),
              child: Center(
                child:
                    widget.testCompleted
                        ? Text(
                          widget.passed ? 'Continue' : 'Retry',
                          style: TextStyle(
                            color:
                                widget.passed
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : isListening
                        ? const ActiveMic()
                        : const Icon(
                          Icons.mic_none,
                          color: Colors.blue,
                          size: 32,
                        ),
              ),
            ),
          ),
        ),
        if (!widget.testCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              isListening ? 'Listening...' : 'Tap to listen',
              style: const TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
