class Config {
  final bool isTest;

  Config({required this.isTest});

  static Config fromArgs(List<String> args) {
    final isTest = (args.contains('--test'));

    return Config(isTest: isTest);
  }
}
