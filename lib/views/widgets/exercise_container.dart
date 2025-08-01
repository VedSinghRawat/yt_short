import 'package:flutter/material.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';

class ExerciseContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool addTopPadding;

  const ExerciseContainer({super.key, required this.child, this.maxWidth = 600, this.addTopPadding = true});

  @override
  Widget build(BuildContext context) {
    final responsiveness = ResponsivenessService(context);
    final padding = responsiveness.getResponsiveValues(mobile: 16, tablet: 24, largeTablet: 32);

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                padding,
                (orientation == Orientation.portrait && addTopPadding) ? kToolbarHeight + padding : 0,
                padding,
                padding,
              ),
              child:
                  maxWidth != null
                      ? Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: child))
                      : child,
            );
          },
        ),
      ),
    );
  }
}
