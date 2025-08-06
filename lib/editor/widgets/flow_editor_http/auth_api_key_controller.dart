import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/request.dart';

abstract interface class AuthApiKeyControllerI {
  CodeLineEditingController getKeyController();
  CodeLineEditingController getValueController();
  ApiKeyPlacement getPlacement();
  void setPlacement(ApiKeyPlacement placement);
  ApiKeyAuth getAuth();
  void dispose();
}

class AuthApiKeyController implements AuthApiKeyControllerI {
  late final CodeLineEditingController keyController;
  late final CodeLineEditingController valueController;
  late final Request _formRequest;
  late final void Function() _flowModified;
  late ApiKeyPlacement _placement;

  AuthApiKeyController(Request request, void Function() flowModified) {
    _formRequest = request;
    _flowModified = flowModified;
    keyController = CodeLineEditingController();
    valueController = CodeLineEditingController();
    _placement = ApiKeyPlacement.header;

    if (request.authApiKey != null) {
      final auth = request.authApiKey as ApiKeyAuth;
      keyController.text = auth.key;
      valueController.text = auth.value;
      _placement = auth.placement;
    }

    keyController.addListener(_keyModified);
    valueController.addListener(_valueModified);
  }

  @override
  CodeLineEditingController getKeyController() => keyController;
  @override
  CodeLineEditingController getValueController() => valueController;

  @override
  ApiKeyPlacement getPlacement() => _placement;

  @override
  void setPlacement(ApiKeyPlacement placement) {
    _placement = placement;
    final auth = _formRequest.authApiKey as ApiKeyAuth;
    auth.placement = _placement;

    _flowModified(); // Trigger UI update
  }

  @override
  ApiKeyAuth getAuth() {
    return ApiKeyAuth(key: keyController.text, value: valueController.text, placement: _placement);
  }

  void _keyModified() {
    final key = keyController.text;

    if (_formRequest.authApiKey == null) {
      _formRequest.authApiKey = ApiKeyAuth(key: key, value: '', placement: _placement);
    } else {
      final auth = _formRequest.authApiKey as ApiKeyAuth;
      auth.key = key;
    }

    _flowModified();
  }

  void _valueModified() {
    final value = valueController.text;

    if (_formRequest.authApiKey == null) {
      _formRequest.authApiKey = ApiKeyAuth(key: '', value: value, placement: _placement);
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
  late final void Function() _flowModified;
  late ApiKeyPlacement _placement;

  AuthApiKeyControllerFolder(Folder folder, void Function() flowModified) {
    _folder = folder;
    _flowModified = flowModified;
    keyController = CodeLineEditingController();
    valueController = CodeLineEditingController();
    _placement = ApiKeyPlacement.header; // Initialize with default value

    if (_folder.authApiKey != null) {
      final auth = _folder.authApiKey as ApiKeyAuth;
      keyController.text = auth.key;
      valueController.text = auth.value;
      _placement = auth.placement; // Set from existing auth data
    }
  }

  @override
  CodeLineEditingController getKeyController() => keyController;
  @override
  CodeLineEditingController getValueController() => valueController;

  @override
  ApiKeyPlacement getPlacement() => _placement;

  @override
  void setPlacement(ApiKeyPlacement placement) {
    _placement = placement;
    _flowModified(); // Trigger UI update
  }

  @override
  ApiKeyAuth getAuth() {
    return ApiKeyAuth(key: keyController.text, value: valueController.text, placement: _placement);
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
  late final void Function() _flowModified;
  late ApiKeyPlacement _placement;

  AuthApiKeyControllerCollection(Collection collection, void Function() flowModified) {
    _collection = collection;
    _flowModified = flowModified;
    keyController = CodeLineEditingController();
    valueController = CodeLineEditingController();
    _placement = ApiKeyPlacement.header; // Initialize with default value

    if (_collection.authApiKey != null) {
      final auth = _collection.authApiKey as ApiKeyAuth;
      keyController.text = auth.key;
      valueController.text = auth.value;
      _placement = auth.placement; // Set from existing auth data
    }
  }

  @override
  CodeLineEditingController getKeyController() => keyController;
  @override
  CodeLineEditingController getValueController() => valueController;

  @override
  ApiKeyPlacement getPlacement() => _placement;

  @override
  void setPlacement(ApiKeyPlacement placement) {
    _placement = placement;
    _flowModified(); // Trigger UI update
  }

  @override
  ApiKeyAuth getAuth() {
    return ApiKeyAuth(key: keyController.text, value: valueController.text, placement: _placement);
  }

  @override
  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
