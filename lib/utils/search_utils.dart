/// Natural string comparator that compares numbers numerically.
/// E.g. "20х20" < "120х120" and "20х20х1,5" < "20х20х2".
int naturalCompare(String a, String b) {
  final chunkRegex = RegExp(r'(\d+(?:[.,]\d+)?)|(\D+)');
  final aMatches = chunkRegex.allMatches(a.toLowerCase());
  final bMatches = chunkRegex.allMatches(b.toLowerCase());

  final aIter = aMatches.iterator;
  final bIter = bMatches.iterator;

  while (true) {
    final aHasNext = aIter.moveNext();
    final bHasNext = bIter.moveNext();

    if (!aHasNext && !bHasNext) return 0;
    if (!aHasNext) return -1;
    if (!bHasNext) return 1;

    final aChunk = aIter.current.group(0)!;
    final bChunk = bIter.current.group(0)!;

    final aNum = double.tryParse(aChunk.replaceAll(',', '.'));
    final bNum = double.tryParse(bChunk.replaceAll(',', '.'));

    if (aNum != null && bNum != null) {
      final cmp = aNum.compareTo(bNum);
      if (cmp != 0) return cmp;
    } else {
      final cmp = aChunk.compareTo(bChunk);
      if (cmp != 0) return cmp;
    }
  }
}

/// Normalizes dimension separators (x, х, *, ×, and "на" between digits)
/// while preserving words containing 'х' such as "холоднокатаный" or "в бухтах".
String normalizeDimensionSeparators(String text) {
  return text
      .replaceAll(RegExp(r'(?<=\d)\s*(?:[\u0445\u0425xX*×]|на)\s*(?=\d)', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'(?<=\d)\s*[\u0445\u0425xX*×](?![a-zA-Zа-яА-ЯёЁ])'), ' ')
      .replaceAll(RegExp(r'(?<![a-zA-Zа-яА-ЯёЁ])[\u0445\u0425xX*×]\s*(?=\d)'), ' ')
      .replaceAll(RegExp(r'(?<=\s)[\u0445\u0425xX*×](?=\s)'), ' ');
}

/// Filters and ranks items based on intelligent query parsing,
/// dimension recognition, and relevance scoring.
List<T> filterAndRankMaterials<T>({
  required List<T> items,
  required String query,
  required String Function(T) getName,
  required String Function(T) getCategory,
  String category = 'Все',
}) {
  List<T> list = items;
  if (category != 'Все') {
    list = list.where((m) => getCategory(m) == category).toList();
  }

  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    final copy = List<T>.from(list);
    copy.sort((a, b) {
      final catCmp = getCategory(a).compareTo(getCategory(b));
      if (catCmp != 0) return catCmp;
      return naturalCompare(getName(a), getName(b));
    });
    return copy;
  }

  final normQuery = normalizeDimensionSeparators(trimmed.toLowerCase());
  final rawTokens = normQuery
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  final scored = <MapEntry<int, T>>[];

  for (final item in list) {
    final nameLower = getName(item).toLowerCase();
    final catLower = getCategory(item).toLowerCase();
    final fullText = '$catLower $nameLower';

    final normFullText = normalizeDimensionSeparators(fullText);
    final textNumbers = RegExp(r'\b\d+(?:[.,]\d+)?\b')
        .allMatches(normFullText)
        .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.')))
        .whereType<double>()
        .toList();

    bool isMatch = true;
    int numExactMatches = 0;
    int wordNameMatches = 0;
    int wordCatMatches = 0;

    final availNumbers = List<double>.from(textNumbers);

    for (final token in rawTokens) {
      final tokenNum = double.tryParse(token.replaceAll(',', '.'));

      if (tokenNum != null) {
        final matchIdx = availNumbers.indexWhere((n) => (n - tokenNum).abs() < 0.001);
        if (matchIdx != -1) {
          availNumbers.removeAt(matchIdx);
          numExactMatches++;
        } else {
          isMatch = false;
          break;
        }
      } else {
        if (nameLower.contains(token)) {
          wordNameMatches++;
        } else if (catLower.contains(token)) {
          wordCatMatches++;
        } else {
          isMatch = false;
          break;
        }
      }
    }

    if (isMatch) {
      int score = 0;
      score += numExactMatches * 150;
      score += wordNameMatches * 50;
      score += wordCatMatches * 20;

      // Bonus if whole raw query is substring in name
      if (nameLower.contains(trimmed.toLowerCase())) {
        score += 100;
      }

      // Bonus if name starts with any non-numeric word token
      final wordTokens = rawTokens.where((t) => double.tryParse(t.replaceAll(',', '.')) == null).toList();
      if (wordTokens.isNotEmpty && wordTokens.any((w) => nameLower.startsWith(w))) {
        score += 40;
      }

      // Bonus if number of dimensions requested matches closely
      final queryNumCount = rawTokens.where((t) => double.tryParse(t.replaceAll(',', '.')) != null).length;
      if (queryNumCount > 0 && textNumbers.length >= queryNumCount) {
        score -= (textNumbers.length - queryNumCount) * 5;
      }

      scored.add(MapEntry(score, item));
    }
  }

  scored.sort((a, b) {
    final scoreCmp = b.key.compareTo(a.key);
    if (scoreCmp != 0) return scoreCmp;
    return naturalCompare(getName(a.value), getName(b.value));
  });

  return scored.map((e) => e.value).toList();
}
