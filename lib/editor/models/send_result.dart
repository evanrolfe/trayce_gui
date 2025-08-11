import 'package:http/http.dart' as http;

class SendResult {
  final http.Response response;
  final List<String> output;

  SendResult({required this.response, required this.output});
}
