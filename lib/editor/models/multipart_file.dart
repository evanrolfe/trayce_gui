class MultipartFile {
  String name;
  String value;
  String? contentType;
  bool enabled;

  MultipartFile({required this.name, required this.value, required this.enabled, this.contentType});

  bool equals(MultipartFile other) {
    return name == other.name && value == other.value && contentType == other.contentType && enabled == other.enabled;
  }

  String toBru() {
    String bru = '@file($value)';
    if (contentType != null) {
      bru += ' @contentType($contentType)';
    }
    return bru;
  }
}
