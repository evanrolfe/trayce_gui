import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi_allocator;
import 'package:ffi/ffi.dart' show Utf8;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:trayce/grpc_parser.dart';
import 'package:trayce/utils/grpc_parser_lib.dart';

class ProtoDef {
  final int? id;
  final String name;
  final String filePath;
  final String protoFile;
  final DateTime createdAt;

  const ProtoDef({
    this.id,
    required this.name,
    required this.filePath,
    required this.protoFile,
    required this.createdAt,
  });

  /// Creates a ProtoDef from a map
  factory ProtoDef.fromMap(Map<String, dynamic> map) {
    return ProtoDef(
      id: map['id'] as int?,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      protoFile: map['proto_file'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this ProtoDef to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'proto_file': protoFile,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this ProtoDef with the given fields replaced with the new values
  ProtoDef copyWith({
    int? id,
    String? name,
    String? filePath,
    String? protoFile,
    DateTime? createdAt,
  }) {
    return ProtoDef(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      protoFile: protoFile ?? this.protoFile,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String parseGRPCMessage(Uint8List msg, String grpcMsgPath, bool isResponse) {
    // Create a temporary file with the proto content
    final tempFile = File('${Directory.systemTemp.path}/trayce_protodef_${id ?? 'new'}.proto');
    tempFile.writeAsStringSync(protoFile);

    try {
      final dyLibPath = GrpcParserLib.getPath();
      final dylib = ffi.DynamicLibrary.open(dyLibPath);

      int isResponseInt = 0;
      if (isResponse) {
        isResponseInt = 1;
      }
      final grpcParser = NativeLibrary(dylib);
      final res = grpcParser.ParseProtoMessage(
        _toCString(tempFile.path),
        _toCString(grpcMsgPath),
        convertUint8ListToPointer(msg),
        msg.length,
        isResponseInt,
      );

      return pointerToDartString(res);
    } finally {
      // Clean up the temporary file
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    }
  }
}

String replaceLastSegment(String pathInput, String replacement) {
  return path.join(path.dirname(pathInput), replacement);
}

ffi.Pointer<ffi.Char> _toCString(String dartString) {
  // Allocate memory and copy the Dart string into the C memory
  final ffi.Pointer<ffi.Char> cString = ffi_allocator.malloc.allocate<ffi.Char>(dartString.length + 1);
  final cStringList = cString.cast<ffi.Uint8>().asTypedList(dartString.length + 1);

  for (int i = 0; i < dartString.length; i++) {
    cStringList[i] = dartString.codeUnitAt(i);
  }
  cStringList[dartString.length] = 0; // Null-terminate the string

  return cString;
}

String pointerToDartString(ffi.Pointer<ffi.Char> pointer) {
  // Cast the pointer to a Pointer<Utf8> and convert it to a Dart string
  return pointer.cast<Utf8>().toDartString();
}

ffi.Pointer<ffi.Uint8> convertUint8ListToPointer(Uint8List list) {
  // Allocate memory for the byte array in native memory
  ffi.Pointer<ffi.Uint8> pointer = ffi_allocator.malloc.allocate<ffi.Uint8>(list.length);

  // Copy the contents of the Uint8List into the allocated memory
  for (int i = 0; i < list.length; i++) {
    pointer[i] = list[i];
  }

  // Return the pointer to the memory containing the Uint8List data
  return pointer;
}
