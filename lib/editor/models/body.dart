import 'package:trayce/editor/models/multipart_file.dart';

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
  bool isEmpty();
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

  static JsonBody blank() {
    return JsonBody(content: '');
  }

  @override
  bool isEmpty() {
    return content.isEmpty;
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

  static TextBody blank() {
    return TextBody(content: '');
  }

  @override
  bool isEmpty() {
    return content.isEmpty;
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

  static XmlBody blank() {
    return XmlBody(content: '');
  }

  @override
  bool isEmpty() {
    return content.isEmpty;
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

  static SparqlBody blank() {
    return SparqlBody(content: '');
  }

  @override
  bool isEmpty() {
    return content.isEmpty;
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

  static GraphqlBody blank() {
    return GraphqlBody(query: '', variables: '');
  }

  @override
  bool isEmpty() {
    return query.isEmpty;
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
    return params
        .where((p) => p.enabled)
        .map((p) => '${Uri.encodeComponent(p.name)}=${Uri.encodeComponent(getValueString(p.value))}')
        .join('&');
  }

  @override
  void setContent(String value) {
    // params = value;
  }

  @override
  Body deepCopy() {
    return FormUrlEncodedBody(params: params);
  }

  static FormUrlEncodedBody blank() {
    return FormUrlEncodedBody(params: []);
  }

  @override
  bool isEmpty() {
    return params.isEmpty;
  }

  void setParams(List<Param> params) {
    this.params = params;
  }
}

class MultipartFormBody extends Body {
  @override
  final String type = 'multipart-form';
  List<MultipartFile> files;

  MultipartFormBody({required this.files});

  @override
  bool equals(Body other) {
    if (other is! MultipartFormBody) return false;
    if (files.length != other.files.length) return false;
    for (var i = 0; i < files.length; i++) {
      if (!files[i].equals(other.files[i])) return false;
    }
    return true;
  }

  @override
  String toBru() {
    var bru = 'body:multipart-form {\n';

    final enabledParams = files.where((p) => p.enabled).toList();
    if (enabledParams.isNotEmpty) {
      bru +=
          '${indentString(enabledParams.map((item) => '${item.name}: ${getValueString(item.toBru())}').join('\n'))}\n';
    }

    final disabledParams = files.where((p) => !p.enabled).toList();
    if (disabledParams.isNotEmpty) {
      bru +=
          '${indentString(disabledParams.map((item) => '~${item.name}: ${getValueString(item.toBru())}').join('\n'))}\n';
    }

    bru += '}';
    return bru;
  }

  @override
  String toString() {
    return files.map((p) => '${p.name}: ${getValueString(p.value)}').join('&');
  }

  @override
  void setContent(String value) {
    // TODO
  }

  @override
  Body deepCopy() {
    return MultipartFormBody(files: files);
  }

  static MultipartFormBody blank() {
    return MultipartFormBody(files: []);
  }

  @override
  bool isEmpty() {
    return files.isEmpty;
  }

  void setFiles(List<MultipartFile> files) {
    this.files = files;
  }
}

class FileBodyItem {
  String filePath;
  String? contentType;
  bool selected;

  FileBodyItem({required this.filePath, this.contentType, required this.selected});

  @override
  String toString() {
    return filePath;
  }

  bool equals(FileBodyItem other) {
    return filePath == other.filePath && contentType == other.contentType && selected == other.selected;
  }

  String toBru() {
    String bru = '@file($filePath)';
    if (contentType != null) {
      bru += ' @contentType($contentType)';
    }
    return bru;
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

    final selectedFiles = files.where((p) => p.selected).toList();
    if (selectedFiles.isNotEmpty) {
      bru += '${indentString(selectedFiles.map((item) => 'file: ${getValueString(item.toBru())}').join('\n'))}\n';
    }

    final unselectedFiles = files.where((p) => !p.selected).toList();
    if (unselectedFiles.isNotEmpty) {
      bru += '${indentString(unselectedFiles.map((item) => '~file: ${getValueString(item.toBru())}').join('\n'))}\n';
    }

    bru += '}';
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

  static FileBody blank() {
    return FileBody(files: []);
  }

  @override
  bool isEmpty() {
    return files.isEmpty;
  }

  void setFiles(List<FileBodyItem> files) {
    this.files = files;
  }

  FileBodyItem? selectedFile() {
    return files.where((p) => p.selected).toList().first;
  }
}
