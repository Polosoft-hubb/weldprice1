import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as ul;
import 'url_launcher_stub.dart'
    if (dart.library.html) 'url_launcher_web.dart';

Future<void> launchAppUrl(String url, {bool newTab = true}) async {
  if (kIsWeb) {
    openUrlWeb(url, newTab: newTab);
    return;
  }

  final uri = Uri.parse(url);
  await ul.launchUrl(uri, mode: ul.LaunchMode.externalApplication);
}

Future<void> launchCall(String phone) async {
  final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (clean.isEmpty) return;
  await launchAppUrl('tel:$clean', newTab: false);
}

Future<void> launchYandexMaps(String address) async {
  final trimmed = address.trim();
  if (trimmed.isEmpty) return;
  final encoded = Uri.encodeComponent(trimmed);
  await launchAppUrl('https://yandex.ru/maps/?text=$encoded', newTab: true);
}
