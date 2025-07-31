import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/request.dart';

class AuthBasicController {
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
