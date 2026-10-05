import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps receipt photos in the app's own folder.
///
/// The database stores only the file name (like "r_1727700000000.jpg"),
/// because on iOS the full path of the app folder can change after an
/// update.
class ReceiptStore {
  ReceiptStore(this._folder);

  /// Returns the folder for receipts. Created if missing.
  final Future<Directory> Function() _folder;

  /// Copies a picked photo into the receipts folder and returns its name.
  Future<String> save(String sourcePath) async {
    final dir = await _folder();
    final ext = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath).toLowerCase();
    final name = 'r_${DateTime.now().microsecondsSinceEpoch}$ext';
    await File(sourcePath).copy(p.join(dir.path, name));
    return name;
  }

  /// The photo file for a stored name, or null if it is missing.
  Future<File?> file(String name) async {
    final f = File(p.join((await _folder()).path, name));
    return await f.exists() ? f : null;
  }

  /// Removes a photo. Missing files are ignored.
  Future<void> delete(String name) async {
    final f = await file(name);
    if (f != null) await f.delete();
  }
}

final receiptStoreProvider = Provider<ReceiptStore>(
  (ref) => ReceiptStore(() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'receipts')).create(recursive: true);
  }),
);

/// Where a new receipt photo comes from.
enum ReceiptSource { camera, gallery }

/// Opens the camera or photo library. Returns the picked file path, or
/// null if the user cancels. Tests replace this provider with a fake.
final receiptPickerProvider = Provider<Future<String?> Function(ReceiptSource)>(
  (ref) {
    final picker = ImagePicker();
    return (source) async {
      final file = await picker.pickImage(
        source: source == ReceiptSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        // Receipts do not need full camera quality.
        maxWidth: 1600,
        imageQuality: 80,
      );
      return file?.path;
    };
  },
);

/// Loads the receipt file for a stored name.
final receiptFileProvider = FutureProvider.family<File?, String>(
  (ref, name) => ref.watch(receiptStoreProvider).file(name),
);
