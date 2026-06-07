import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

typedef StringDynamicMap = Map<String, dynamic>;

bool isPcPlatform() {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

final isPc = isPcPlatform();
