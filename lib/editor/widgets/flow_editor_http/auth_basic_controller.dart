import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/request.dart';

class AuthBasicController {
  late final CodeLineEditingController usernameController;
  late final CodeLineEditingController passwordController;

  AuthBasicController(Request request) {
    usernameController = CodeLineEditingController();
    passwordController = CodeLineEditingController();

    if (request.authBasic != null) {
      final auth = request.authBasic as BasicAuth;
      usernameController.text = auth.username;
      passwordController.text = auth.password;
    }
  }
}
