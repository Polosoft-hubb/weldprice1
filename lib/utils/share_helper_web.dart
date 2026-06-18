import 'dart:html' as html;
import 'dart:js_util' as js_util;

void nativeWebShare(String text, String subject) {
  final navigator = html.window.navigator;
  if (js_util.hasProperty(navigator, 'share')) {
    navigator.share({
      'title': subject,
      'text': text,
    });
  } else {
    throw Exception('Web Share API is not supported in this browser.');
  }
}
