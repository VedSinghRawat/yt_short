import 'package:myapp/models/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lang_controller.g.dart';

@Riverpod(keepAlive: true)
class LangController extends _$LangController {
  @override
  PrefLang build() {
    return PrefLang.hinglish;
  }

  void changeLanguage(PrefLang newLang) {
    state = newLang;
  }
}
