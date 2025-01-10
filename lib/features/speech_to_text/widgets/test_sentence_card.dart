import 'package:flutter/material.dart';
import 'package:myapp/features/speech_to_text/widgets/recognizer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class TestSentenceCard extends StatefulWidget {
  final String text;
  final VoidCallback onContinue;

  const TestSentenceCard({
    super.key,
    required this.text,
    required this.onContinue,
  });

  @override
  State<TestSentenceCard> createState() => _TestSentenceCardState();
}

class _TestSentenceCardState extends State<TestSentenceCard> {
  late List<String> words;
  late List<bool?> wordMarking;
  int currIndex = -1;
  late SpeechRecognizer _recognizer;
  late List<String> recognizedWords;
  bool get allWordsCorrect => wordMarking.every((mark) => mark == true);

  @override
  void initState() {
    super.initState();
    words = widget.text.split(' ');
    wordMarking = List.generate(words.length, (index) => null);
    recognizedWords = List.filled(words.length, '');
    _recognizer = SpeechRecognizer(
      onResult: _onSpeechResult,
      onStopListenting: _onStopListening,
    );
  }

  void _onStopListening() {
    setState(() {
      currIndex = -1;
      wordMarking = List.generate(words.length, (index) => null);
      recognizedWords = List.filled(words.length, '');
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    List<String> wordsList = result.recognizedWords.split(' ').where((word) => word.isNotEmpty).toList();
    print('Processing final result: $wordsList');
    if (wordsList.isEmpty) return;

    setState(() {
      for (int i = currIndex + 1; i < wordsList.length; i++) {
        String lowerRecognizedWord = wordsList[i].toLowerCase();
        String targetWord = words[i].toLowerCase();
        print('Processing - Index: $i, Recognized: $lowerRecognizedWord, Target: $targetWord');

        wordMarking[i] = targetWord == lowerRecognizedWord;
        recognizedWords[i] = lowerRecognizedWord;
        currIndex = i;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 24.0),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        "Please speak the sentence given below to continue",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: List.generate(words.length, (index) {
                            return WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (wordMarking[index] == false)
                                    Positioned(
                                      top: -25,
                                      child: Text(
                                        recognizedWords[index],
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 18,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    '${words[index]} ',
                                    style: TextStyle(
                                      color: wordMarking[index] == null
                                          ? Colors.white70
                                          : wordMarking[index] == true
                                              ? Colors.lightBlue[200]
                                              : Colors.red,
                                      fontSize: 24,
                                      fontWeight: wordMarking[index] != null ? FontWeight.bold : FontWeight.normal,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    if (allWordsCorrect)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green[300],
                          size: 48,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Container(
              width: allWordsCorrect ? 160 : 80,
              height: 80,
              decoration: BoxDecoration(
                shape: allWordsCorrect ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: allWordsCorrect ? BorderRadius.circular(40) : null,
                color: allWordsCorrect
                    ? Colors.yellow.shade100
                    : _recognizer.isListening
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (allWordsCorrect) {
                      widget.onContinue();
                    } else {
                      setState(() {
                        if (_recognizer.isListening) {
                          _recognizer.stopListening();
                        } else {
                          _recognizer.startListening();
                        }
                      });
                    }
                  },
                  customBorder: allWordsCorrect ? null : const CircleBorder(),
                  child: Container(
                    width: allWordsCorrect ? 160 : 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: allWordsCorrect ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: allWordsCorrect ? BorderRadius.circular(40) : null,
                    ),
                    child: Center(
                      child: allWordsCorrect
                          ? Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.yellow.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Icon(
                              _recognizer.isListening ? Icons.mic : Icons.mic_none,
                              color: _recognizer.isListening ? Colors.green : Colors.blue,
                              size: 32,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
