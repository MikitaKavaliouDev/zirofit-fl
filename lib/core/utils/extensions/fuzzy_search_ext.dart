extension FuzzySearch on String {
  /// Calculates the Levenshtein distance between this string and [other].
  /// The minimum number of single-character edits (insertions, deletions,
  /// substitutions) required to change one string into the other.
  int levenshteinDistance(String other) {
    final sLen = length;
    final oLen = other.length;

    if (sLen == 0) return oLen;
    if (oLen == 0) return sLen;

    var v0 = List.generate(oLen + 1, (i) => i);
    var v1 = List.filled(oLen + 1, 0);

    final sChars = codeUnits;
    final oChars = other.codeUnits;

    for (var i = 0; i < sLen; i++) {
      v1[0] = i + 1;

      for (var j = 0; j < oLen; j++) {
        final cost = (sChars[i] == oChars[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1, // insertion
          v0[j + 1] + 1, // deletion
          v0[j] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }

      for (var j = 0; j <= oLen; j++) {
        v0[j] = v1[j];
      }
    }

    return v0[oLen];
  }

  /// Returns a score between 0.0 and 1.0 indicating similarity.
  double similarity(String other) {
    final distance = levenshteinDistance(other);
    final maxLen = length > other.length ? length : other.length;
    if (maxLen == 0) return 1.0;
    return 1.0 - (distance / maxLen);
  }

  /// Normalizes the string for search: lowercased, punctuation stripped,
  /// whitespace stripped.
  String get searchNormalized {
    return toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '');
  }
}
