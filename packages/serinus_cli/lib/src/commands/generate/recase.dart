class ReCase {
  /// Constructs an instance of [ReCase] by analyzing the given [text] and
  /// grouping it into words.
  ReCase(String text) : _words = _groupIntoWords(text);

  static final _upperAlphaRegex = RegExp('[A-Z]');
  static final _symbolSet = {' ', '.', '/', '_', r'\', '-'};
  final List<String> _words;

  /// Groups the [text] into words considering different separators and casing.
  static List<String> _groupIntoWords(String text) {
    final sb = StringBuffer();
    final words = <String>[];
    final isAllCaps = text.toUpperCase() == text;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final nextChar = i + 1 == text.length ? null : text[i + 1];

      if (_symbolSet.contains(char)) {
        continue;
      }

      sb.write(char);

      final isEndOfWord = nextChar == null ||
          (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          _symbolSet.contains(nextChar);

      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }

    return words;
  }

  String getSentenceCase({String separator = ' '}) {
    final words = _words.map((word) => word.toLowerCase()).toList();
    if (_words.isNotEmpty) {
      words[0] = _upperCaseFirstLetter(words[0]);
    }

    return words.join(separator);
  }

  String getSnakeCase({String separator = '_'}) {
    final words = _words.map((word) => word.toLowerCase()).toList();

    return words.join(separator);
  }

  String _upperCaseFirstLetter(String word) {
    return '''${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}''';
  }

  @override
  String toString() => getSentenceCase();
}
