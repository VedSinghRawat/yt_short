import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/active_mic.dart';
import 'package:myapp/features/speech_exercise/widgets/recognizer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:developer' as developer;

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

  @override
  void initState() {
    super.initState();
    _recognizer = SpeechRecognizer(
      onResult: widget.onResult,
      onStopListenting: widget.onStopListening,
    );
  }

  Future<void> _handleButtonPress() async {
    if (widget.passed) {
      widget.onContinue();
      _recognizer.stopListening();
    } else {
      if (_recognizer.isListening) {
        developer.log('stopping listening');
        _recognizer.stopListening();
      } else {
        developer.log('starting listening');
        await _recognizer.startListening();
      }
    }

    setState(() {
      _recognizer = _recognizer;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('building button ${_recognizer.isListening}');

    return Container(
      width: widget.testCompleted ? 160 : 80,
      height: widget.testCompleted ? 60 : 80,
      decoration: BoxDecoration(
        shape: widget.testCompleted ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: widget.testCompleted ? BorderRadius.circular(40) : null,
        color: widget.failed
            ? Colors.red.shade100
            : _recognizer.isListening | widget.passed
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
      child: Material(
        color: Colors.transparent,
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
              child: widget.testCompleted
                  ? Text(
                      widget.passed ? 'Continue' : 'Retry',
                      style: TextStyle(
                        color: widget.passed ? Colors.green.shade700 : Colors.red.shade700,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : _recognizer.isListening
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
    );
  }
}
