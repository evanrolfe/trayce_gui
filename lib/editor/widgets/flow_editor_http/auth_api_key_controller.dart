import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/request.dart';

abstract interface class AuthApiKeyControllerI {
  CodeLineEditingController getKeyController();
  CodeLineEditingController getValueController();
  ApiKeyAuth getAuth();
  void dispose();
}

class AuthApiKeyController implements AuthApiKeyControllerI {
  late final CodeLineEditingController keyController;
  late final CodeLineEditingController valueController;
  late final Request _formRequest;
  late final void Function() _flowModified;

  AuthApiKeyController(Request request, void Function() flowModified) {
    _formRequest = request;
    _flowModified = flowModified;
    keyController = CodeLineEditingController();
    valueController = CodeLineEditingController();

    if (request.authApiKey != null) {
      final auth = request.authApiKey as ApiKeyAuth;
      keyController.text = auth.key;
      valueController.text = auth.value;
    }

    keyController.addListener(_keyModified);
    valueController.addListener(_valueModified);
  }

  @override
  CodeLineEditingController getKeyController() => keyController;
  @override
  CodeLineEditingController getValueController() => valueController;

  @override
  ApiKeyAuth getAuth() {
    return ApiKeyAuth(key: keyController.text, value: valueController.text);
  }

  void _keyModified() {
    final key = keyController.text;

    if (_formRequest.authApiKey == null) {
      _formRequest.authApiKey = ApiKeyAuth(key: key, value: '');
    } else {
      final auth = _formRequest.authApiKey as ApiKeyAuth;
      auth.key = key;
    }

    _flowModified();
  }

  void _valueModified() {
    final value = valueController.text;

    if (_formRequest.authApiKey == null) {
      _formRequest.authApiKey = ApiKeyAuth(key: '', value: value);
    } else {
      final auth = _formRequest.authApiKey as ApiKeyAuth;
      auth.value = value;
    }

    _flowModified();
  }

  @override
  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class AuthApiKeyControllerFolder implements AuthApiKeyControllerI {
  late final CodeLineEditingController keyController;
  late final CodeLineEditingController valueController;
  late final Folder _folder;

  AuthApiKeyControllerFolder(Folder folder) {
    _folder = folder;
    keyController = CodeLineEditingController();
    valueController = CodeLineEditingController();

    if (_folder.authApiKey != null) {
      final auth = _folder.authApiKey as ApiKeyAuth;
      keyController.text = auth.key;
      valueController.text = auth.value;
    }
  }

  @override
  CodeLineEditingController getKeyController() => keyController;
  @override
  CodeLineEditingController getValueController() => valueController;

  @override
  ApiKeyAuth getAuth() {
    return ApiKeyAuth(key: keyController.text, value: valueController.text);
  }

  @override
  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class AuthApiKeyControllerCollection implements AuthApiKeyControllerI {
  late final CodeLineEditingController keyController;
  late final CodeLineEditingController valueController;
  late final Collection _collection;

  AuthApiKeyControllerCollection(Collection collection) {
    _collection = collection;
    keyController = CodeLineEditingController();
    valueController = CodeLineEditingController();

    if (_collection.authApiKey != null) {
      final auth = _collection.authApiKey as ApiKeyAuth;
      keyController.text = auth.key;
      valueController.text = auth.value;
    }
  }

  @override
  CodeLineEditingController getKeyController() => keyController;
  @override
  CodeLineEditingController getValueController() => valueController;

  @override
  ApiKeyAuth getAuth() {
    return ApiKeyAuth(key: keyController.text, value: valueController.text);
  }

  @override
  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
