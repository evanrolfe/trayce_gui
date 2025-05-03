import 'param.dart';
import 'utils.dart';

abstract class Body {
  String get type;
  String toBru();
}

class JsonBody extends Body {
  @override
  final String type = 'json';
  String content;

  JsonBody({required this.content});

  @override
  String toBru() {
    return 'body:json {\n${indentString(content)}\n}';
  }
}

class TextBody extends Body {
  @override
  final String type = 'text';
  String content;

  TextBody({required this.content});

  @override
  String toBru() {
    return 'body:text {\n${indentString(content)}\n}';
  }
}

class XmlBody extends Body {
  @override
  final String type = 'xml';
  String content;

  XmlBody({required this.content});

  @override
  String toBru() {
    return 'body:xml {\n${indentString(content)}\n}';
  }
}

class SparqlBody extends Body {
  @override
  final String type = 'sparql';
  String content;

  SparqlBody({required this.content});

  @override
  String toBru() {
    return 'body:sparql {\n${indentString(content)}\n}';
  }
}

class GraphqlBody extends Body {
  @override
  final String type = 'graphql';
  String query;
  String variables;

  GraphqlBody({required this.query, required this.variables});

  @override
  String toBru() {
    var bru = '';
    bru += 'body:graphql {\n${indentString(query)}\n}\n';
    bru += '\nbody:graphql:vars {\n${indentString(variables)}\n}';
    return bru;
  }
}

class FormUrlEncodedBody extends Body {
  @override
  final String type = 'form-urlencoded';
  List<Param> params;

  FormUrlEncodedBody({required this.params});

  @override
  String toBru() {
    var bru = 'body:form-urlencoded {\n';

    final enabledParams = params.where((p) => p.enabled).toList();
    if (enabledParams.isNotEmpty) {
      bru += '${indentString(enabledParams.map((item) => '${item.name}: ${getValueString(item.value)}').join('\n'))}\n';
    }

    final disabledParams = params.where((p) => !p.enabled).toList();
    if (disabledParams.isNotEmpty) {
      bru +=
          '${indentString(disabledParams.map((item) => '~${item.name}: ${getValueString(item.value)}').join('\n'))}\n';
    }

    bru += '}';
    return bru;
  }
}

class MultipartFormBody extends Body {
  @override
  final String type = 'multipart-form';
  List<Param> params;

  MultipartFormBody({required this.params});

  @override
  String toBru() {
    var bru = 'body:multipart-form {\n';

    final enabledParams = params.where((p) => p.enabled).toList();
    if (enabledParams.isNotEmpty) {
      bru += '${indentString(enabledParams.map((item) => '${item.name}: ${getValueString(item.value)}').join('\n'))}\n';
    }

    final disabledParams = params.where((p) => !p.enabled).toList();
    if (disabledParams.isNotEmpty) {
      bru +=
          '${indentString(disabledParams.map((item) => '~${item.name}: ${getValueString(item.value)}').join('\n'))}\n';
    }

    bru += '}';
    return bru;
  }
}

class FileBodyItem {
  String filePath;
  String contentType;
  bool selected;

  FileBodyItem({
    required this.filePath,
    required this.contentType,
    required this.selected,
  });

  static FileBodyItem fromBruLine(String line, bool selected) {
    // Default values
    String filePath = '';
    String contentType = '';

    // Extract file path
    final fileMatch = RegExp(r'@file\((.*?)\)').firstMatch(line);
    if (fileMatch != null && fileMatch.groupCount >= 1) {
      filePath = fileMatch.group(1) ?? '';
    }

    // Extract content type
    final contentTypeMatch = RegExp(r'@contentType\((.*?)\)').firstMatch(line);
    if (contentTypeMatch != null && contentTypeMatch.groupCount >= 1) {
      contentType = contentTypeMatch.group(1) ?? '';
    }

    return FileBodyItem(
      filePath: filePath,
      contentType: contentType,
      selected: selected,
    );
  }
}

class FileBody extends Body {
  @override
  final String type = 'file';
  List<FileBodyItem> files;

  FileBody({required this.files});

  @override
  String toBru() {
    var bru = 'body:file {\n';

    if (files.isNotEmpty) {
      bru += indentString(files.map((item) {
        final selected = item.selected ? '' : '~';
        final contentType = item.contentType.isNotEmpty ? ' @contentType(${item.contentType})' : '';
        final value = '@file(${item.filePath})';
        return '${selected}file: $value$contentType';
      }).join('\n'));
    }

    bru += '\n}';
    return bru;
  }
}
