import 'param.dart';
import 'utils.dart';

abstract class Body {
  String get type;
  String toBru();
  @override
  String toString();
  void setContent(String value);
  bool equals(Body other);
  Body deepCopy();
}

class JsonBody extends Body {
  @override
  final String type = 'json';
  String content;

  JsonBody({required this.content});

  @override
  bool equals(Body other) {
    if (other is! JsonBody) return false;
    return content == other.content;
  }

  @override
  String toBru() {
    return 'body:json {\n${indentString(content)}\n}';
  }

  @override
  String toString() {
    return content;
  }

  @override
  void setContent(String value) {
    content = value;
  }

  @override
  Body deepCopy() {
    return JsonBody(content: content);
  }
}

class TextBody extends Body {
  @override
  final String type = 'text';
  String content;

  TextBody({required this.content});

  @override
  bool equals(Body other) {
    if (other is! TextBody) return false;
    return content == other.content;
  }

  @override
  String toBru() {
    return 'body:text {\n${indentString(content)}\n}';
  }

  @override
  String toString() {
    return content;
  }

  @override
  void setContent(String value) {
    content = value;
  }

  @override
  Body deepCopy() {
    return TextBody(content: content);
  }
}

class XmlBody extends Body {
  @override
  final String type = 'xml';
  String content;

  XmlBody({required this.content});

  @override
  bool equals(Body other) {
    if (other is! XmlBody) return false;
    return content == other.content;
  }

  @override
  String toBru() {
    return 'body:xml {\n${indentString(content)}\n}';
  }

  @override
  String toString() {
    return content;
  }

  @override
  void setContent(String value) {
    content = value;
  }

  @override
  Body deepCopy() {
    return XmlBody(content: content);
  }
}

class SparqlBody extends Body {
  @override
  final String type = 'sparql';
  String content;

  SparqlBody({required this.content});

  @override
  bool equals(Body other) {
    if (other is! SparqlBody) return false;
    return content == other.content;
  }

  @override
  String toBru() {
    return 'body:sparql {\n${indentString(content)}\n}';
  }

  @override
  String toString() {
    return content;
  }

  @override
  void setContent(String value) {
    content = value;
  }

  @override
  Body deepCopy() {
    return SparqlBody(content: content);
  }
}

class GraphqlBody extends Body {
  @override
  final String type = 'graphql';
  String query;
  String variables;

  GraphqlBody({required this.query, required this.variables});

  @override
  bool equals(Body other) {
    if (other is! GraphqlBody) return false;
    return query == other.query && variables == other.variables;
  }

  @override
  String toBru() {
    var bru = '';
    bru += 'body:graphql {\n${indentString(query)}\n}\n';
    bru += '\nbody:graphql:vars {\n${indentString(variables)}\n}';
    return bru;
  }

  @override
  String toString() {
    // TODO: include the variables somehow
    return query;
  }

  @override
  void setContent(String value) {
    query = value;
  }

  @override
  Body deepCopy() {
    return GraphqlBody(query: query, variables: variables);
  }
}

class FormUrlEncodedBody extends Body {
  @override
  final String type = 'form-urlencoded';
  List<Param> params;

  FormUrlEncodedBody({required this.params});

  @override
  bool equals(Body other) {
    if (other is! FormUrlEncodedBody) return false;
    if (params.length != other.params.length) return false;
    for (var i = 0; i < params.length; i++) {
      if (!params[i].equals(other.params[i])) return false;
    }
    return true;
  }

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

  @override
  String toString() {
    return params.map((p) => '${p.name}: ${getValueString(p.value)}').join('&');
  }

  @override
  void setContent(String value) {
    // params = value;
  }

  @override
  Body deepCopy() {
    return FormUrlEncodedBody(params: params);
  }
}

class MultipartFormBody extends Body {
  @override
  final String type = 'multipart-form';
  List<Param> params;

  MultipartFormBody({required this.params});

  @override
  bool equals(Body other) {
    if (other is! MultipartFormBody) return false;
    if (params.length != other.params.length) return false;
    for (var i = 0; i < params.length; i++) {
      if (!params[i].equals(other.params[i])) return false;
    }
    return true;
  }

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

  @override
  String toString() {
    return params.map((p) => '${p.name}: ${getValueString(p.value)}').join('&');
  }

  @override
  void setContent(String value) {
    // TODO
  }

  @override
  Body deepCopy() {
    return MultipartFormBody(params: params);
  }
}

class FileBodyItem {
  String filePath;
  String contentType;
  bool selected;

  FileBodyItem({required this.filePath, required this.contentType, required this.selected});

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

    return FileBodyItem(filePath: filePath, contentType: contentType, selected: selected);
  }

  @override
  String toString() {
    return filePath;
  }

  bool equals(FileBodyItem other) {
    return filePath == other.filePath && contentType == other.contentType && selected == other.selected;
  }
}

class FileBody extends Body {
  @override
  final String type = 'file';
  List<FileBodyItem> files;

  FileBody({required this.files});

  @override
  bool equals(Body other) {
    if (other is! FileBody) return false;
    if (files.length != other.files.length) return false;
    for (var i = 0; i < files.length; i++) {
      if (!files[i].equals(other.files[i])) return false;
    }
    return true;
  }

  @override
  String toBru() {
    var bru = 'body:file {\n';

    if (files.isNotEmpty) {
      bru += indentString(
        files
            .map((item) {
              final selected = item.selected ? '' : '~';
              final contentType = item.contentType.isNotEmpty ? ' @contentType(${item.contentType})' : '';
              final value = '@file(${item.filePath})';
              return '${selected}file: $value$contentType';
            })
            .join('\n'),
      );
    }

    bru += '\n}';
    return bru;
  }

  @override
  String toString() {
    return files.map((f) => f.toString()).join('\n');
  }

  @override
  void setContent(String value) {
    // TODO
  }

  @override
  Body deepCopy() {
    return FileBody(files: files);
  }
}
