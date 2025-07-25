import 'package:trayce/editor/models/param.dart';

// buildURLQueryString does not filter based on param.enabled, keep that in mind!
String buildURLQueryString(List<Param> params) {
  return params.map((p) => '${Uri.encodeComponent(p.name)}=${Uri.encodeComponent(p.value)}').join('&');
}

List<Param> parseUrl(String url) {
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
