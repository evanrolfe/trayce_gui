class Config {
  final bool isTest;
  final String trayceApiUrl;

  static const defaultTrayceApiUrl = 'https://get.trayce.dev'; // no trailing slash

  Config({required this.isTest, required this.trayceApiUrl});

  static Config fromArgs(List<String> args) {
    final isTest = (args.contains('--test'));
    final trayceApiUrl =
        (args.contains('--trayce-api-url')) ? args[args.indexOf('--trayce-api-url') + 1] : defaultTrayceApiUrl;

    return Config(isTest: isTest, trayceApiUrl: trayceApiUrl);
  }
}
