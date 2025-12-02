import '../tree/utils.dart';
import 'definition.dart';

/// Regex to identify parametric segments in a route.
final parametricRegex = RegExp(r'<[^>]+>');

/// This regex has 3 Groups
///
/// - ([^<]*) -> this captures prefix
///
/// - (\w+) -> this captures the parameter name
///
/// - ([^<]*) -> this captures suffix
final parametricDefnsRegex = RegExp(r'([^<]*)<(\w+)>([^<]*)');

/// Regex to detect close door neighbors in parametric definitions.
final closeDoorParametricRegex = RegExp(r'><');

/// String extension methods for route parameter handling.
extension StringExtension on String {
  /// Checks if the string is a static route segment.
  bool get isStatic => !isWildCard && !isTailWildCard && !isParametric;

  /// Checks if the string is a parametric route segment.
  bool get isParametric => parametricRegex.hasMatch(this);

  /// Checks if the string is a single-segment wildcard (*).
  bool get isWildCard => this == '*';

  /// Checks if the string is a tail wildcard (**) that matches remaining path.
  bool get isTailWildCard => this == '**';

  /// Checks if the string is a regex route segment.
  bool get isRegex => isRegexeric(this);

  /// Returns null if the string is empty.
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// converts `(^\\w+)` string value to Regex('\w+)
RegExp descriptorToRegex(String descriptor) {
  // Remove leading and trailing parentheses
  String regexStr = descriptor.substring(1, descriptor.length - 1);
  return RegExp(regexStr);
}

/// Builds a template string for a route parameter.
String buildTemplateString({
  required String name,
  String? prefix,
  String? suffix,
}) {
  var template = '<$name>';
  if (prefix != null) {
    template = '$prefix$template';
  }
  if (suffix != null) {
    template = '$template$suffix';
  }
  return template;
}

/// Builds a regex from a template string.
RegExp buildRegexFromTemplate(String template) {
  final escapedTemplate = RegExp.escape(template);

  // Replace <...> placeholders with named capturing groups
  final regexPattern = escapedTemplate.replaceAllMapped(
    RegExp(r'<([^>]+)>'),
    (Match match) {
      String paramName = match.group(1)!;
      return '(?<$paramName>[^/]+)';
    },
  );

  return RegExp(regexPattern, caseSensitive: false);
}

/// Resolves parameters from a given path using the provided template regex.
Map<String, dynamic>? resolveParamsFromPath(
  RegExp templateRegex,
  String path,
) {
  final match = templateRegex.firstMatch(path);
  if (match == null) {
    return null;
  }

  return {
    for (final param in match.groupNames) param: match.namedGroup(param),
  };
}

/// Extension methods for sorting parameter definitions.
extension ParametricDefinitionsExtension on List<ParameterDefinition> {
  /// Sorts parameter definitions by their properties.
  void sortByProps() => sort((a, b) {
        // First, prioritize CompositeParameterDefinition
        if (a is CompositeParameterDefinition &&
            b is! CompositeParameterDefinition) {
          return -1;
        }
        if (b is CompositeParameterDefinition &&
            a is! CompositeParameterDefinition) {
          return 1;
        }

        // If both are CompositeParameterDefinition, compare their lengths
        if (a is CompositeParameterDefinition &&
            b is CompositeParameterDefinition) {
          return b.parts.length.compareTo(a.parts.length);
        }

        // Now handle SingleParameterDefn cases
        if (a is SingleParameterDefn && b is SingleParameterDefn) {
          bool aHasPrefix = a.prefix != null;
          bool aHasSuffix = a.suffix != null;
          bool bHasPrefix = b.prefix != null;
          bool bHasSuffix = b.suffix != null;

          int aScore = (aHasPrefix ? 1 : 0) + (aHasSuffix ? 1 : 0);
          int bScore = (bHasPrefix ? 1 : 0) + (bHasSuffix ? 1 : 0);

          return bScore.compareTo(aScore);
        }

        // This case shouldn't occur if all elements are either Composite or Single,
        // but including it for completeness
        return 0;
      });
}

const _lowerA = 97; // 'a'
const _upperA = 65; //  'A'
const _lowerZ = 122; // 'z'
const _upperZ = 90; // 'Z'

int _stringToBitmask(String s) {
  int mask = 0;

  for (int i = 0; i < s.length; i++) {
    int charCode = s.codeUnitAt(i);
    if (charCode >= _upperA && charCode <= _upperZ) {
      charCode += 32; // Convert to lowercase
    }
    if (charCode >= _lowerA && charCode <= _lowerZ) {
      mask |= (1 << (charCode - _lowerA));
    }
  }
  return mask;
}

/// Matches the input string against the given prefix and suffix.
String? matchPattern(String input, String prefix, String suffix) {
  if (prefix.isEmpty && suffix.isEmpty) {
    return input;
  }

  final prefixMask = _stringToBitmask(prefix);
  final suffixMask = _stringToBitmask(suffix);

  int matchStart = 0;
  int matchEnd = input.length;

  final compareInput = input.toLowerCase();
  final comparePrefix = prefix.toLowerCase();
  final compareSuffix = suffix.toLowerCase();

  if (prefix.isNotEmpty) {
    bool prefixFound = false;
    for (int i = 0; i <= input.length - prefix.length; i++) {
      if (_stringToBitmask(compareInput.substring(i, i + prefix.length)) ==
          prefixMask) {
        if (compareInput.substring(i, i + prefix.length) == comparePrefix) {
          matchStart = i + prefix.length;
          prefixFound = true;
          break;
        }
      }
    }
    if (!prefixFound) {
      return null;
    }
  }

  if (suffix.isNotEmpty) {
    bool suffixFound = false;
    for (int i = input.length - suffix.length; i >= matchStart; i--) {
      if (_stringToBitmask(compareInput.substring(i, i + suffix.length)) ==
          suffixMask) {
        if (compareInput.substring(i, i + suffix.length) == compareSuffix) {
          matchEnd = i;
          suffixFound = true;
          break;
        }
      }
    }
    if (!suffixFound) {
      return null;
    }
  }

  return input.substring(matchStart, matchEnd);
}
