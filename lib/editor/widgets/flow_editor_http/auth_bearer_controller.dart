import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/request.dart';

abstract interface class AuthBearerControllerI {
  CodeLineEditingController getTokenController();
  BearerAuth getAuth();
  void dispose();
}

class AuthBearerController implements AuthBearerControllerI {
  late final CodeLineEditingController tokenController;
  late final Request _formRequest;
  late final void Function() _flowModified;

  AuthBearerController(Request request, void Function() flowModified) {
    _formRequest = request;
    _flowModified = flowModified;
    tokenController = CodeLineEditingController();

    if (request.authBearer != null) {
      final auth = request.authBearer as BearerAuth;
      tokenController.text = auth.token;
    }

    tokenController.addListener(_tokenModified);
  }

  @override
  CodeLineEditingController getTokenController() => tokenController;

  @override
  BearerAuth getAuth() {
    return BearerAuth(token: tokenController.text);
  }

  void _tokenModified() {
    final token = tokenController.text;

    if (_formRequest.authBearer == null) {
      _formRequest.authBearer = BearerAuth(token: token);
    } else {
      final auth = _formRequest.authBearer as BearerAuth;
      auth.token = token;
    }

    _flowModified();
  }

  void dispose() {
    tokenController.dispose();
  }
}

class AuthBearerControllerFolder implements AuthBearerControllerI {
  late final CodeLineEditingController tokenController;
  late final Folder _folder;

  AuthBearerControllerFolder(Folder folder) {
    _folder = folder;
    tokenController = CodeLineEditingController();

    if (_folder.authBearer != null) {
      final auth = _folder.authBearer as BearerAuth;
      tokenController.text = auth.token;
    }
  }

  @override
  CodeLineEditingController getTokenController() => tokenController;

  @override
  BearerAuth getAuth() {
    return BearerAuth(token: tokenController.text);
  }

  void dispose() {
    tokenController.dispose();
  }
}

class AuthBearerControllerCollection implements AuthBearerControllerI {
  late final CodeLineEditingController tokenController;
  late final Collection _collection;

  AuthBearerControllerCollection(Collection collection) {
    _collection = collection;
    tokenController = CodeLineEditingController();

    if (_collection.authBearer != null) {
      final auth = _collection.authBearer as BearerAuth;
      tokenController.text = auth.token;
    }
  }

  @override
  CodeLineEditingController getTokenController() => tokenController;

  @override
  BearerAuth getAuth() {
    return BearerAuth(token: tokenController.text);
  }

  void dispose() {
    tokenController.dispose();
  }
}
