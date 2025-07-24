import 'package:flutter/material.dart';
import 'package:myapp/views/widgets/lang_text.dart';

class Loader extends StatelessWidget {
  final String? text;

  const Loader({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator.adaptive(),
          if (text != null) ...[
            const SizedBox(height: 16),
            LangText.bodyText(text: text!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
