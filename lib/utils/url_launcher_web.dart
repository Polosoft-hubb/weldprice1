import 'dart:html' as html;

void openUrlWeb(String url, {bool newTab = true}) {
  if (url.startsWith('tel:')) {
    final anchor = html.AnchorElement(href: url);
    anchor.click();
    return;
  }

  if (newTab) {
    final anchor = html.AnchorElement(href: url)
      ..target = '_blank'
      ..rel = 'noopener noreferrer';
    anchor.click();
  } else {
    html.window.location.href = url;
  }
}
