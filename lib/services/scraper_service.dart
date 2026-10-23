import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
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
    // 1. If running on Web, load the latest hosted data/prices.json from same-origin.
    // This avoids CORS entirely, downloads in milliseconds, and guarantees all 576 items.
    if (kIsWeb) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final candidateUrls = [
        Uri.base.resolve('data/prices.json?t=$timestamp').toString(),
        'data/prices.json?t=$timestamp',
        '/weldprice1/data/prices.json?t=$timestamp',
      ];

      for (final candidate in candidateUrls) {
        try {
          final response = await http.get(Uri.parse(candidate)).timeout(const Duration(seconds: 8));
          if (response.statusCode == 200) {
            final decoded = json.decode(utf8.decode(response.bodyBytes));
            List<dynamic>? list;
            DateTime? scrapedDate;

            if (decoded is Map<String, dynamic>) {
              if (decoded['updatedAt'] != null) {
                scrapedDate = DateTime.tryParse(decoded['updatedAt'].toString());
              }
              if (decoded['materials'] is List) {
                list = decoded['materials'] as List<dynamic>;
              }
            } else if (decoded is List) {
              list = decoded;
            }

            if (list != null && list.isNotEmpty) {
              final List<MaterialModel> parsed = [];
              for (final item in list) {
                try {
                  parsed.add(MaterialModel.fromJson(item as Map<String, dynamic>));
                } catch (_) {}
              }

              if (parsed.isNotEmpty) {
                await DatabaseHelper.instance.updateMaterialsBatch(parsed);
                final prefs = await SharedPreferences.getInstance();
                final saveDate = scrapedDate ?? DateTime.now();
                await prefs.setString(lastUpdateKey, saveDate.toIso8601String());
                return parsed.length;
              }
            }
          }
        } catch (e) {
          // Try next candidate URL
        }
      }
    }

    // 2. Direct scraping (for non-web platforms or fallback)
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
          final html = utf8.decode(response.bodyBytes);
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

              final double weightVal = double.tryParse(productData['weight']?.toString() ?? '') ?? 0.0;
              
              parsedMaterials.add(MaterialModel(
                id: id,
                name: title,
                url: prodUrl,
                unit: unit,
                price: priceVal,
                category: catName,
                weight: weightVal,
              ));
              seenIds.add(id);
            } catch (e) {
              // Ignore single item errors
            }
          }
        }
      } catch (e) {
        // Log category error, continue to next
      }
    }

    if (parsedMaterials.isNotEmpty) {
      await DatabaseHelper.instance.updateMaterialsBatch(parsedMaterials);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastUpdateKey, DateTime.now().toIso8601String());
      return parsedMaterials.length;
    }

    // 3. Fallback to bundled materials database
    try {
      final jsonString = await rootBundle.loadString('assets/materials_db.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<MaterialModel> bundled = jsonList.map((e) => MaterialModel.fromJson(e)).toList();
      if (bundled.isNotEmpty) {
        await DatabaseHelper.instance.updateMaterialsBatch(bundled);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(lastUpdateKey, DateTime.now().toIso8601String());
        return bundled.length;
      }
    } catch (_) {}

    throw Exception("Не удалось загрузить цены. Проверьте подключение к сети.");
  }

  Future<DateTime?> getLastUpdateDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(lastUpdateKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }
}
