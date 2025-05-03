String outdentString(String? str) {
  if (str == null || str.isEmpty) {
    return str ?? '';
  }

  return str.split('\n').map((line) => line.replaceFirst(RegExp(r'^  '), '')).join('\n');
}

String indentString(String? str) {
  if (str == null || str.isEmpty) {
    return str ?? '';
  }

  return str.split('\n').map((line) => '  $line').join('\n');
}

List<T> enabled<T>(List<T> items, [String key = "enabled"]) {
  return items.where((item) => (item as dynamic)[key] as bool).toList();
}

List<T> disabled<T>(List<T> items, [String key = "enabled"]) {
  return items.where((item) => !((item as dynamic)[key] as bool)).toList();
}

String stripLastLine(String? text) {
  if (text == null || text.isEmpty) return text ?? '';

  return text.replaceAll(RegExp(r'(\r?\n)$'), '');
}

String getValueString(String? value) {
  final hasNewLines = value?.contains('\n') ?? false;

  if (!hasNewLines) {
    return value ?? '';
  }

  // Add one level of indentation to the contents of the multistring
  final indentedLines = value!.split('\n').map((line) => '  $line').join('\n');

  // Join the lines back together with newline characters and enclose them in triple single quotes
  return "'''\n$indentedLines\n'''";
}

bool parseBool(String input) {
  return input.toLowerCase() == 'true';
}
