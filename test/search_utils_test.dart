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
      MaterialModel(id: '7', name: 'Труба профильная оцинкованная: ОЦ 40х20х2,0 мм', category: 'Труба', price: 145, unit: 'пог. м', url: ''),
    ];

    test('query "проф труб 20 20" puts 20x20 pipes at the very top', () {
      final res = filterAndRankMaterials<MaterialModel>(
        items: materials,
        query: 'проф труб 20 20',
        getName: (m) => m.name,
        getCategory: (m) => m.category,
      );

      final topIds = res.take(2).map((m) => m.id).toList();
      expect(topIds, containsAll(['4', '5']));
    });

    test('query "20" places 20x20 above 200 and 120, but preserves 200 and 120 in results', () {
      final res = filterAndRankMaterials<MaterialModel>(
        items: materials,
        query: '20',
        getName: (m) => m.name,
        getCategory: (m) => m.category,
      );

      final ids = res.map((m) => m.id).toList();
      expect(ids.contains('2'), isTrue); // 120
      expect(ids.contains('3'), isTrue); // 200
      expect(ids.contains('4'), isTrue); // 20x20
      expect(ids.contains('5'), isTrue); // 20x20

      final idx20_1 = ids.indexOf('4');
      final idx20_2 = ids.indexOf('5');
      final idx200 = ids.indexOf('3');
      final idx120 = ids.indexOf('2');

      expect(idx20_1 < idx200, isTrue);
      expect(idx20_2 < idx200, isTrue);
      expect(idx20_1 < idx120, isTrue);
      expect(idx20_2 < idx120, isTrue);
      expect(idx200 < idx120, isTrue);
    });

    test('query "Труба профильная 40х20х2 мм" ranks black steel over galvanized steel', () {
      final res = filterAndRankMaterials<MaterialModel>(
        items: materials,
        query: 'Труба профильная 40х20х2 мм',
        getName: (m) => m.name,
        getCategory: (m) => m.category,
      );

      expect(res.isNotEmpty, isTrue);
      expect(res.first.id, '6'); // Standard black steel, NOT galvanized '7'!
    });

    test('query "Труба профильная оцинкованная 40х20х2" ranks galvanized steel first', () {
      final res = filterAndRankMaterials<MaterialModel>(
        items: materials,
        query: 'Труба профильная оцинкованная 40х20х2',
        getName: (m) => m.name,
        getCategory: (m) => m.category,
      );

      expect(res.isNotEmpty, isTrue);
      expect(res.first.id, '7'); // Galvanized steel
    });
  });
}
