import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/material.dart';
import 'database_helper.dart';

class ScraperService {
  static final ScraperService instance = ScraperService._init();
  ScraperService._init();

  static const List<Map<String, String>> categories = [
    {"name": "Арматура", "url": "https://100met.ru/catalog/armatura.html"},
    {"name": "Катанка", "url": "https://100met.ru/catalog/katanka.html"},
    {"name": "Труба", "url": "https://100met.ru/catalog/truba.html"},
    {"name": "Уголок", "url": "https://100met.ru/catalog/ugolok/"},
    {"name": "Швеллер", "url": "https://100met.ru/catalog/shveller.html"},
    {"name": "Полоса", "url": "https://100met.ru/catalog/polosa.html"},
    {"name": "Квадрат", "url": "https://100met.ru/catalog/kvadrat-stalnoy.html"},
    {"name": "Листовой прокат", "url": "https://100met.ru/catalog/listovoy-prokat.html"},
    {"name": "Сетка", "url": "https://100met.ru/catalog/setka.html"},
    {"name": "Балка двутавровая", "url": "https://100met.ru/catalog/balka-dvutavrovaya.html"},
    {"name": "Проволока вязальная", "url": "https://100met.ru/catalog/provoloka-vyazalnaya.html"},
    {"name": "Профнастил", "url": "https://100met.ru/catalog/profnastil.html"},
    {"name": "Винтовые сваи", "url": "https://100met.ru/catalog/vintovyie-svai.html"},
    {"name": "Отводы стальные", "url": "https://100met.ru/catalog/otvodyi-stalnyie.html"}
  ];

  static const String lastUpdateKey = "last_prices_update";

  Future<int> scrapeAndUpdatePrices() async {
    final List<MaterialModel> parsedMaterials = [];
    final Set<String> seenIds = {};

    for (final cat in categories) {
      final String catName = cat["name"]!;
      final String url = cat["url"]!;
      
      try {
        final requestUrl = kIsWeb
            ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}'
            : url;
        final response = await http.get(Uri.parse(requestUrl)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          // Decode html as UTF-8
          final html = utf8.decode(response.bodyBytes);
          
          // Regex to match data-product='...'
          final regExp = RegExp(r"data-product='([^']+)'");
          final matches = regExp.allMatches(html);
          
          for (final match in matches) {
            final jsonStr = match.group(1);
            if (jsonStr == null) continue;
            
            try {
              final Map<String, dynamic> productData = json.decode(jsonStr);
              final String id = productData['id']?.toString() ?? '';
              if (id.isEmpty || seenIds.contains(id)) continue;
              
              final String title = productData['title'] ?? '';
              if (title.isEmpty) continue;
              
              String prodUrl = productData['url'] ?? '';
              if (prodUrl.isNotEmpty && !prodUrl.startsWith('http')) {
                prodUrl = 'https://100met.ru$prodUrl';
              }
              
              final String unit = productData['unit'] ?? 'пог. м';
              
              double priceVal = 0.0;
              final discPrice = productData['discountedPrice'];
              final regPrice = productData['price'];
              
              if (discPrice != null && (discPrice is num) && discPrice > 0) {
                priceVal = discPrice.toDouble();
              } else if (regPrice != null) {
                priceVal = double.tryParse(regPrice.toString()) ?? 0.0;
              }
              
              parsedMaterials.add(MaterialModel(
                id: id,
                name: title,
                url: prodUrl,
                unit: unit,
                price: priceVal,
                category: catName,
              ));
              seenIds.add(id);
            } catch (e) {
              // Ignore single item errors
            }
          }
        }
      } catch (e) {
        print("ScraperService: Failed to parse $catName: $e");
        rethrow; // Let caller handle connection failures
      }
    }

    if (parsedMaterials.isNotEmpty) {
      await DatabaseHelper.instance.updateMaterialsBatch(parsedMaterials);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastUpdateKey, DateTime.now().toIso8601String());
    }

    return parsedMaterials.length;
  }

  Future<DateTime?> getLastUpdateDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(lastUpdateKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }
}
