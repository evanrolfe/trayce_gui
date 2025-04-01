import 'dart:io';

import 'package:flutter/foundation.dart';

class GrpcParserLib {
  // Get the frameworks path for macOS
  static String getFrameworksPath() {
    String appPath = Platform.resolvedExecutable; // Path to YourApp.app/Contents/MacOS/YourApp
    String frameworksPath = '${File(appPath).parent.parent.path}/Frameworks';
    return frameworksPath;
  }

  // Get the executable path
  static String getPath() {
    if (Platform.isLinux && !kDebugMode) {
      return '/usr/local/lib/trayce/grpc_parser';
    }
    return '${getFrameworksPath()}/grpc_parser';
  }

  // Ensure the executable exists and is ready to use
  static Future<bool> ensureExists() async {
    final executablePath = getPath();
    final executableFile = File(executablePath);
    print("checking for grpc_parser at $executablePath");

    final exists = await executableFile.exists();
    if (!exists) {
      throw Exception('grpc_parser executable not found at $executablePath');
    }
    return exists;
  }
}
