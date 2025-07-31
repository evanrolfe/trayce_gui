import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/request.dart';

class AuthBearerController {
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
