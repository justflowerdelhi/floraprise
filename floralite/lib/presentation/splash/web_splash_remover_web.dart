// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// Web implementation of web splash remover invoking JavaScript removeSplashFromWeb.
void removeWebSplash() {
  try {
    js.context.callMethod('removeSplashFromWeb');
  } catch (_) {
    // Best-effort: ignore if DOM element was already removed or function unavailable
  }
}
