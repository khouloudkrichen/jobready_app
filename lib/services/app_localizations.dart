import 'package:flutter/widgets.dart';

class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  factory AppLocalizations.of(BuildContext context) {
    return AppLocalizations(Localizations.localeOf(context).languageCode);
  }

  bool get isEnglish => languageCode == 'en';

  String t(String fr, String en) => isEnglish ? en : fr;
}
