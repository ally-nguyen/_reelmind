import 'package:flutter/foundation.dart';

class AppPreferences {
  AppPreferences._();

  /// When true, the generator screen navigates directly to the workspace
  /// after generation completes, skipping the "Tweak in editor" button.
  static final preloadScripts = ValueNotifier<bool>(false);

  /// When true, archived ideas older than 30 days are automatically deleted.
  static final autoDeleteArchived = ValueNotifier<bool>(false);
}
