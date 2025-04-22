import 'package:myapp/models/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lang_notifier.g.dart';

class PrefLangText {
  final String hindi;
  final String hinglish;

  const PrefLangText({required this.hindi, required this.hinglish});

  String getText(PrefLang lang) {
    switch (lang) {
      case PrefLang.hindi:
        return hindi;
      case PrefLang.hinglish:
        return hinglish;
    }
  }
}

@Riverpod(keepAlive: true)
class Lang extends _$Lang {
  @override
  PrefLang build() {
    return PrefLang.hinglish;
  }

  void changeLanguage(PrefLang newLang) {
    state = newLang;
  }

  String prefLangText(PrefLangText text) {
    return text.getText(state);
  }
}
