import 'dart:io';

Future<String> getMachineIp() async {
  if (Platform.isMacOS) {
    return 'host.docker.internal';
  }

  try {
    final interfaces = await NetworkInterface.list();
    for (var interface in interfaces) {
      // Skip loopback and docker interfaces
      if (interface.name.contains('docker') || interface.name == 'lo') {
        continue;
      }

      // Look for IPv4 address
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
  } catch (e) {
    print('Error getting machine IP: $e');
  }
  return '127.0.0.1'; // Fallback to localhost
}

// list the min alphabetical order
String formatSortedHeaders(Map<String, List<String>> headers) {
  final sortedHeaders = headers.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

  return sortedHeaders.map((entry) => '${entry.key}: ${entry.value.join(',')}').join('\n');
}
