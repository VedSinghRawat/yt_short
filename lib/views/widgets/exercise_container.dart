import 'package:flutter/material.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';

class ExerciseContainer extends StatelessWidget {
  final Widget child;
  final bool addTopPadding;

  const ExerciseContainer({super.key, required this.child, this.addTopPadding = true});

  @override
  Widget build(BuildContext context) {
    final responsiveness = ResponsivenessService(context);
    final padding = responsiveness.getResponsiveValues(mobile: 16, tablet: 24, largeTablet: 32);
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            padding,
            (orientation == Orientation.portrait && addTopPadding) ? kToolbarHeight + padding : 0,
            padding,
            padding,
          ),
          child: Center(
            child:
                orientation == Orientation.landscape
                    ? child
                    : ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: child),
          ),
        ),
      ),
    );
  }
}
