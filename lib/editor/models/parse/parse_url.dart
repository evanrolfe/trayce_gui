import 'package:trayce/editor/models/param.dart';

// buildURLQueryString does not filter based on param.enabled, keep that in mind!
String buildURLQueryString(List<Param> params) {
  return params.map((p) => '${Uri.encodeComponent(p.name)}=${Uri.encodeComponent(p.value)}').join('&');
}

List<Param> parseUrlQueryParams(String url) {
  final params = <Param>[];

  // Use regex to extract the query string
  final queryStart = url.indexOf('?');
  if (queryStart == -1 || queryStart == url.length - 1) {
    return params;
  }
  final queryString = url.substring(queryStart + 1);

  // Regex to match key[=value] pairs, allowing for repeated keys and keys without values
  final regExp = RegExp(r'([^&=]+)(=([^&]*))?');
  for (final match in regExp.allMatches(queryString)) {
    final key = Uri.decodeComponent(match.group(1)!);
    final value = match.group(3) != null ? Uri.decodeComponent(match.group(3)!) : '';
    params.add(Param(name: key, value: value, type: ParamType.query, enabled: true));
  }

  return params;
}

List<Param> parseUrlPathParams(String url) {
  final params = <Param>[];

  // Find the start of the query string to exclude it from path parsing
  final queryStart = url.indexOf('?');
  final pathEnd = queryStart != -1 ? queryStart : url.length;
  final path = url.substring(0, pathEnd);

  // Regex to match path parameters that start with ':'
  // This matches :paramName where paramName can contain letters, numbers, and underscores
  final regExp = RegExp(r':([a-zA-Z_][a-zA-Z0-9_]*)');
  for (final match in regExp.allMatches(path)) {
    final paramName = match.group(1)!; // Group 1 contains the param name without the ':'
    params.add(Param(name: paramName, value: '', type: ParamType.path, enabled: true));
  }

  return params;
}
