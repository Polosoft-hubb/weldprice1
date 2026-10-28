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
///
/// Keeps partial matches (e.g. "200" and "120" when searching "20"),
/// but ranks exact dimension matches (e.g. "20x20") at the very top.
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

    // Verify all query tokens match somewhere in the text (exact or substring)
    bool allMatched = true;
    for (final token in rawTokens) {
      final tokenClean = token.replaceAll(',', '.');
      if (!fullText.contains(token) &&
          !normFullText.contains(token) &&
          !normFullText.contains(tokenClean) &&
          !fullText.contains(tokenClean)) {
        allMatched = false;
        break;
      }
    }
    if (!allMatched) continue;

    final textNumbers = RegExp(r'\b\d+(?:[.,]\d+)?\b')
        .allMatches(normFullText)
        .map((m) => m.group(0)!.replaceAll(',', '.'))
        .toList();
    final availExactNums = List<String>.from(textNumbers);

    int score = 0;

    // Bonus for whole raw query string being a substring in the name
    if (nameLower.contains(trimmed.toLowerCase())) {
      score += 2000;
    }

    // Token-by-token relevance scoring
    for (final token in rawTokens) {
      final tokenClean = token.replaceAll(',', '.');
      final isNumeric = RegExp(r'^\d+(?:\.\d+)?$').hasMatch(tokenClean);

      if (isNumeric) {
        final tokenVal = double.tryParse(tokenClean);
        if (tokenVal != null) {
          final exactIdx = availExactNums.indexWhere((n) {
            final nVal = double.tryParse(n);
            return nVal != null && (nVal - tokenVal).abs() < 0.001;
          });

          if (exactIdx != -1) {
            availExactNums.removeAt(exactIdx);
            score += 1000; // Exact dimension match gets highest score
          } else if (textNumbers.any((n) => n.startsWith(tokenClean))) {
            score += 200; // Prefix match in dimension (e.g. "20" in "200")
          } else {
            score += 50;  // Substring match in dimension (e.g. "20" in "120")
          }
        } else {
          score += 50;
        }
      } else {
        if (nameLower.contains(token)) {
          if (RegExp(r'\b' + RegExp.escape(token)).hasMatch(nameLower)) {
            score += 400; // Exact word boundary match
          } else {
            score += 200; // Substring word match
          }
        } else if (catLower.contains(token)) {
          score += 100;
        }
      }
    }

    // Bonus for every dimension in the item that equals any numeric query token
    final numTokens = rawTokens
        .map((t) => t.replaceAll(',', '.'))
        .where((t) => RegExp(r'^\d+(?:\.\d+)?$').hasMatch(t))
        .toList();

    for (final qn in numTokens) {
      final qnVal = double.tryParse(qn);
      if (qnVal != null) {
        for (final tn in textNumbers) {
          final tnVal = double.tryParse(tn);
          if (tnVal != null && (tnVal - qnVal).abs() < 0.001) {
            score += 500;
          }
        }
      }
    }

    // Bonus if name starts with any word token
    for (final t in rawTokens) {
      if (!RegExp(r'^\d').hasMatch(t) && nameLower.startsWith(t)) {
        score += 150;
        break;
      }
    }

    // Proximity to requested dimension count
    if (numTokens.isNotEmpty) {
      final extraDims = textNumbers.length - numTokens.length;
      if (extraDims > 0) {
        score -= extraDims * 10;
      }
    }

    // Specialized coating adjustment: galvanized vs black steel
    // Standard black metal should always rank above galvanized unless the query explicitly asks for galvanized!
    final isGalvanizedItem = nameLower.contains('оцинк') ||
        catLower.contains('оцинк') ||
        RegExp(r'\bоц\b', caseSensitive: false).hasMatch(nameLower);
    final queryWantsGalvanized = RegExp(r'\bоц\b|\bоцинк', caseSensitive: false).hasMatch(trimmed);
    if (isGalvanizedItem && !queryWantsGalvanized) {
      score -= 1000; // Strong penalty so standard black steel ranks above galvanized steel
    } else if (isGalvanizedItem && queryWantsGalvanized) {
      score += 1000;
    }

    scored.add(MapEntry(score, item));
  }

  scored.sort((a, b) {
    final scoreCmp = b.key.compareTo(a.key);
    if (scoreCmp != 0) return scoreCmp;
    return naturalCompare(getName(a.value), getName(b.value));
  });

  return scored.map((e) => e.value).toList();
}
