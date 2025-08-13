import 'package:flutter/material.dart';
import 'package:myapp/models/video/video.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';
import 'package:myapp/views/widgets/lang_text.dart';
import 'dialogue_list.dart';

class DialoguePopup extends StatelessWidget {
  final bool visible;
  final List<VideoDialogue> dialogues;
  final VoidCallback onClose;

  const DialoguePopup({super.key, required this.visible, required this.dialogues, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final responsiveness = ResponsivenessService(context);
    final orientation = MediaQuery.of(context).orientation;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedScale(
          scale: visible ? 1.0 : 0.75,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            padding: orientation == Orientation.portrait ? const EdgeInsets.only(top: kToolbarHeight) : EdgeInsets.zero,
            decoration: const BoxDecoration(
              color: Colors.black,
              boxShadow: [BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.2), blurRadius: 12.0, spreadRadius: 4.0)],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                      child: LangText.headingText(
                        text: 'Dialogues',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: responsiveness.getResponsiveValues(mobile: 22, tablet: 26, largeTablet: 30),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(child: DialogueList(dialogues: dialogues)),
                  ],
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: .2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: Colors.red.shade700, width: 1.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Material(
                        color: Colors.red.shade400,
                        child: InkWell(
                          onTap: onClose,
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close_rounded, size: 20, color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
