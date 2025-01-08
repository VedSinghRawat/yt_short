import 'dart:io';

import 'package:flutter/material.dart';
import 'package:speech_reco/utils.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognition extends StatefulWidget {
  final Function(SpeechRecognitionResult result) onChange;

  const SpeechRecognition({super.key, required this.onChange});

  @override
  State<SpeechRecognition> createState() => _SpeechRecognitionState();
}

class _SpeechRecognitionState extends State<SpeechRecognition> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: _onStatus,
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        pauseFor: const Duration(minutes: 1),
        listenFor: const Duration(seconds: 30),
        onResult: (result) {
          widget.onChange(result);

          setState(() {
            List<String> recognizedWords = result.recognizedWords.split(' ');
            _text = recognizedWords.last.toLowerCase();
          });
        },
      );
      stt.SpeechListenOptions(
        partialResults: true,
      );
    } else {
      setState(() {
        _isListening = false;
        showSnackBar(context, 'Speech recognition is not available!');
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onStatus(String status) {
    if (status == stt.SpeechToText.doneStatus && _isListening) {
      _speech.listen(
        onResult: (result) {
          widget.onChange(result);
          setState(() {
            List<String> recognizedWords = result.recognizedWords.split(' ');
            _text = recognizedWords.last.toLowerCase();
          });
        },
      );
      stt.SpeechListenOptions(
        partialResults: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(_text),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isListening ? _stopListening : _startListening,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening ? Colors.green : Colors.blue,
            ),
            child: Text(
              _isListening ? 'Stop' : 'Start',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
