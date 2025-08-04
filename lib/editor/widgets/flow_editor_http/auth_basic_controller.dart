import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/request.dart';

abstract interface class AuthBasicControllerI {
  CodeLineEditingController getUsernameController();
  CodeLineEditingController getPasswordController();
  BasicAuth getAuth();
  void dispose();
}

class AuthBasicController implements AuthBasicControllerI {
  late final CodeLineEditingController usernameController;
  late final CodeLineEditingController passwordController;
  late final Request _formRequest;
  late final void Function() _flowModified;

  AuthBasicController(Request request, void Function() flowModified) {
    _formRequest = request;
    _flowModified = flowModified;
    usernameController = CodeLineEditingController();
    passwordController = CodeLineEditingController();

    if (request.authBasic != null) {
      final auth = request.authBasic as BasicAuth;
      usernameController.text = auth.username;
      passwordController.text = auth.password;
    }

    usernameController.addListener(_usernameModified);
    passwordController.addListener(_passwordModified);
  }

  @override
  CodeLineEditingController getUsernameController() => usernameController;
  @override
  CodeLineEditingController getPasswordController() => passwordController;

  @override
  BasicAuth getAuth() {
    return BasicAuth(username: usernameController.text, password: passwordController.text);
  }

  void _usernameModified() {
    final username = usernameController.text;

    if (_formRequest.authBasic == null) {
      _formRequest.authBasic = BasicAuth(username: username, password: '');
    } else {
      final auth = _formRequest.authBasic as BasicAuth;
      auth.username = username;
    }

    _flowModified();
  }

  void _passwordModified() {
    final password = passwordController.text;

    if (_formRequest.authBasic == null) {
      _formRequest.authBasic = BasicAuth(username: '', password: password);
    } else {
      final auth = _formRequest.authBasic as BasicAuth;
      auth.password = password;
    }

    _flowModified();
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }
}

class AuthBasicControllerFolder implements AuthBasicControllerI {
  late final CodeLineEditingController usernameController;
  late final CodeLineEditingController passwordController;
  late final Folder _folder;

  AuthBasicControllerFolder(Folder folder) {
    _folder = folder;
    usernameController = CodeLineEditingController();
    passwordController = CodeLineEditingController();

    if (_folder.authBasic != null) {
      final auth = _folder.authBasic as BasicAuth;
      usernameController.text = auth.username;
      passwordController.text = auth.password;
    }
  }

  @override
  CodeLineEditingController getUsernameController() => usernameController;
  @override
  CodeLineEditingController getPasswordController() => passwordController;

  BasicAuth getAuth() {
    return BasicAuth(username: usernameController.text, password: passwordController.text);
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }
}

class AuthBasicControllerCollection implements AuthBasicControllerI {
  late final CodeLineEditingController usernameController;
  late final CodeLineEditingController passwordController;
  late final Collection _collection;

  AuthBasicControllerCollection(Collection collection) {
    _collection = collection;
    usernameController = CodeLineEditingController();
    passwordController = CodeLineEditingController();

    if (_collection.authBasic != null) {
      final auth = _collection.authBasic as BasicAuth;
      usernameController.text = auth.username;
      passwordController.text = auth.password;
    }
  }

  @override
  CodeLineEditingController getUsernameController() => usernameController;
  @override
  CodeLineEditingController getPasswordController() => passwordController;

  BasicAuth getAuth() {
    return BasicAuth(username: usernameController.text, password: passwordController.text);
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }
}
