import 'dart:convert';

class LicenseKey {
  String key;
  bool isValid;

  LicenseKey(this.key, this.isValid);

  String toJSON() {
    return jsonEncode({'key': key, 'isValid': isValid});
  }

  static LicenseKey fromJSON(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return LicenseKey(json['key'] as String, json['isValid'] as bool);
  }
}
