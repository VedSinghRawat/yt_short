import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/views/widgets/home_app_bar.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';

class HomeAppBarAnimated extends ConsumerStatefulWidget {
  const HomeAppBarAnimated({super.key});

  @override
  ConsumerState<HomeAppBarAnimated> createState() => _HomeAppBarAnimatedState();
}

class _HomeAppBarAnimatedState extends ConsumerState<HomeAppBarAnimated> {
  @override
  Widget build(BuildContext context) {
    final isAppBarVisible = ref.watch(uIControllerProvider.select((state) => state.isAppBarVisible));

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: isAppBarVisible ? 0 : -kToolbarHeight,
      left: 0,
      right: 0,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isAppBarVisible ? 1.0 : 0.0,
        curve: Curves.easeInOutCubic,
        child: const HomeAppBar(),
      ),
    );
  }
}
