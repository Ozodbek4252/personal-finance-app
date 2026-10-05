import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes text to a file and opens the system share sheet with it.
/// Tests replace this provider with a fake.
typedef ShareTextFile =
    Future<void> Function({
      required String fileName,
      required String content,
      required String mimeType,
    });

final shareTextFileProvider = Provider<ShareTextFile>(
  (ref) => ({required fileName, required content, required mimeType}) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: fileName,
      ),
    );
  },
);

/// Lets the user pick a backup file and returns its text, or null when
/// cancelled. Tests replace this provider with a fake.
final pickBackupTextProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = files.isEmpty ? null : files.first.path;
    return path == null ? null : File(path).readAsString();
  },
);
