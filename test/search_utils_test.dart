import 'package:flutter_test/flutter_test.dart';
import 'package:metall_estimate/utils/search_utils.dart';
import 'package:metall_estimate/models/material.dart';

void main() {
  group('naturalCompare', () {
    test('sorts dimensions numerically rather than lexicographically', () {
      final names = [
        'Труба профильная 120х120х3 мм',
        'Труба профильная 200х200х6 мм',
        'Труба профильная 20х20х1,5 мм',
        'Труба профильная 20х20х2 мм',
        'Труба профильная 15х15х1,5 мм',
        'Труба профильная 25х25х2 мм',
      ];

      names.sort(naturalCompare);

      expect(names, [
        'Труба профильная 15х15х1,5 мм',
        'Труба профильная 20х20х1,5 мм',
        'Труба профильная 20х20х2 мм',
        'Труба профильная 25х25х2 мм',
        'Труба профильная 120х120х3 мм',
        'Труба профильная 200х200х6 мм',
      ]);
    });
  });

  group('filterAndRankMaterials', () {
    final materials = [
      MaterialModel(id: '1', name: 'Т-образный профиль для откатных ворот 65х60х20х2 мм', category: 'Труба', price: 529, unit: 'пог. м', url: ''),
      MaterialModel(id: '2', name: 'Труба профильная квадратная 120х120х3 мм', category: 'Труба', price: 890, unit: 'пог. м', url: ''),
      MaterialModel(id: '3', name: 'Труба профильная квадратная 200х200х6 мм', category: 'Труба', price: 3300, unit: 'пог. м', url: ''),
      MaterialModel(id: '4', name: 'Труба профильная квадратная 20х20х1,5 мм', category: 'Труба', price: 69, unit: 'пог. м', url: ''),
      MaterialModel(id: '5', name: 'Труба профильная квадратная 20х20х2 мм', category: 'Труба', price: 85, unit: 'пог. м', url: ''),
      MaterialModel(id: '6', name: 'Труба профильная прямоугольная 40х20х2 мм', category: 'Труба', price: 110, unit: 'пог. м', url: ''),
    ];

    test('query "проф труб 20 20" only matches 20x20 pipes and puts them at top', () {
      final res = filterAndRankMaterials<MaterialModel>(
        items: materials,
        query: 'проф труб 20 20',
        getName: (m) => m.name,
        getCategory: (m) => m.category,
      );

      expect(res.map((m) => m.id).toList(), ['4', '5']);
    });

    test('query "проф 20 на 20" and "проф 20х20" and "проф 20x20" return 20x20 pipes', () {
      for (final q in ['проф 20 на 20', 'проф 20х20', 'проф 20x20']) {
        final res = filterAndRankMaterials<MaterialModel>(
          items: materials,
          query: q,
          getName: (m) => m.name,
          getCategory: (m) => m.category,
        );
        expect(res.map((m) => m.id).toList(), ['4', '5']);
      }
    });

    test('query "труба 20" matches pipes with 20 dimension, not 120 or 200', () {
      final res = filterAndRankMaterials<MaterialModel>(
        items: materials,
        query: 'труба 20',
        getName: (m) => m.name,
        getCategory: (m) => m.category,
      );

      final ids = res.map((m) => m.id).toList();
      expect(ids.contains('2'), isFalse); // 120x120
      expect(ids.contains('3'), isFalse); // 200x200
      expect(ids.contains('4'), isTrue);  // 20x20
      expect(ids.contains('5'), isTrue);  // 20x20
      expect(ids.contains('6'), isTrue);  // 40x20
    });
  });
}
