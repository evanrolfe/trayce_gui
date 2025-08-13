import 'package:http/http.dart' as http;

class SendResult {
  final http.Response response;
  List<String> output;
  final int? responseTime;

  SendResult({required this.response, required this.output, this.responseTime});
}
