import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

String formatJson(String jsonString) {
  try {
    // First parse the string to ensure it's valid JSON
    final jsonObject = json.decode(jsonString);
    // Then encode it back with indentation
    return const JsonEncoder.withIndent('  ').convert(jsonObject);
  } catch (e) {
    // If parsing fails, return the original string
    return jsonString;
  }
}

String formatHTML(String htmlString) {
  try {
    // Parse the HTML string (forgiving, not strict)
    dom.Document document = html_parser.parse(htmlString);

    // The outerHtml property gives you the full HTML as a string
    // Unfortunately, the html package does not provide pretty-printing out of the box,
    // so we add newlines after tags for basic readability.
    String pretty = _prettyPrintHtml(document.documentElement!, 0);
    return pretty.trim();
  } catch (e) {
    // If parsing fails, return the original string
    return htmlString;
  }
}

/// Recursively pretty-prints HTML nodes with indentation.
String _prettyPrintHtml(dom.Node node, int indentLevel) {
  final indent = '  ' * indentLevel;
  if (node is dom.Text) {
    // Collapse whitespace in text nodes
    final text = node.text.trim();
    return text.isEmpty ? '' : '$indent$text\n';
  }
  if (node is dom.Element) {
    final buffer = StringBuffer();
    buffer.write('$indent<${node.localName}');
    // Add attributes
    node.attributes.forEach((key, value) {
      buffer.write(' $key="${value.replaceAll('"', '&quot;')}"');
    });
    buffer.write('>');
    if (node.nodes.isNotEmpty) {
      buffer.write('\n');
      for (final child in node.nodes) {
        buffer.write(_prettyPrintHtml(child, indentLevel + 1));
      }
      buffer.write('$indent</${node.localName}>\n');
    } else {
      buffer.write('</${node.localName}>\n');
    }
    return buffer.toString();
  }
  // For comments or other node types
  return '';
}
