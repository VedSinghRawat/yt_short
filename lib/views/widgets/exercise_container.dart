import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';
import 'package:myapp/views/widgets/lang_text.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

class ExerciseContainer extends ConsumerStatefulWidget {
  final Widget child;
  final bool addTopPadding;
  final String titleHindi;
  final String titleHinglish;
  final String descriptionHindi;
  final String descriptionHinglish;
  final SubLevelType exerciseType;

  const ExerciseContainer({
    super.key,
    required this.child,
    required this.titleHindi,
    required this.titleHinglish,
    required this.descriptionHindi,
    required this.descriptionHinglish,
    required this.exerciseType,
    this.addTopPadding = true,
  });

  @override
  ConsumerState<ExerciseContainer> createState() => _ExerciseContainerState();
}

class _ExerciseContainerState extends ConsumerState<ExerciseContainer> {
  bool _showDescription = true;
  bool _canReopenDescription = false;

  @override
  void initState() {
    super.initState();
    final userEmail = ref.read(userControllerProvider.notifier).getUser()?.email;
    final hasSeen = ref.read(uIControllerProvider.notifier).getExerciseSeen(widget.exerciseType, userEmail: userEmail);
    _showDescription = !hasSeen;
    _canReopenDescription = hasSeen;
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LangText.heading(
                  hindi: widget.titleHindi,
                  hinglish: widget.titleHinglish,
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                  textAlign: TextAlign.center,
                ),
                if (_showDescription) const SizedBox(height: 8),
                if (_showDescription)
                  LangText.body(
                    hindi: widget.descriptionHindi,
                    hinglish: widget.descriptionHinglish,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          Positioned(
            top: -7,
            right: 0,
            child:
                !_canReopenDescription
                    ? const SizedBox.shrink()
                    : (_showDescription
                        ? IconButton(
                          style: IconButton.styleFrom(backgroundColor: Colors.black12),
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () {
                            setState(() {
                              _showDescription = false;
                            });
                          },
                        )
                        : IconButton(
                          style: IconButton.styleFrom(backgroundColor: Colors.black12),
                          icon: const Icon(Icons.info_outline, color: Colors.white54),
                          onPressed: () {
                            setState(() {
                              _showDescription = true;
                            });
                          },
                        )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsiveness = ResponsivenessService(context);
    final padding = responsiveness.getResponsiveValues(mobile: 16, tablet: 24, largeTablet: 32);
    final orientation = MediaQuery.of(context).orientation;
    final theme = Theme.of(context);

    final header = _buildHeader(theme);

    Widget content =
        orientation == Orientation.landscape
            ? Column(
              mainAxisSize: MainAxisSize.max,
              children: [header, const SizedBox(height: 20), Expanded(child: widget.child)],
            )
            : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [header, const SizedBox(height: 20), Expanded(child: widget.child)],
              ),
            );

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            padding,
            (orientation == Orientation.portrait && widget.addTopPadding) ? kToolbarHeight + padding : 0,
            padding,
            padding,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
