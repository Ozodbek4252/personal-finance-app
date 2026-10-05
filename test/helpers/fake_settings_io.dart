import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:personal_finance/data/backup/file_io.dart';
import 'package:personal_finance/features/app_lock/app_lock.dart';

/// Records shared files instead of opening the share sheet.
class FakeShare {
  final files = <({String fileName, String content, String mimeType})>[];

  Future<void> call({
    required String fileName,
    required String content,
    required String mimeType,
  }) async =>
      files.add((fileName: fileName, content: content, mimeType: mimeType));
}

/// Answers the lock prompt without a real Face ID.
class FakeAuthenticator implements Authenticator {
  bool available = true;
  bool succeed = true;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return succeed;
  }
}

List<Override> fakeSettingsOverrides({
  FakeShare? share,
  String? pickedBackup,
  FakeAuthenticator? auth,
}) => [
  if (share != null) shareTextFileProvider.overrideWithValue(share.call),
  pickBackupTextProvider.overrideWithValue(() async => pickedBackup),
  if (auth != null) authenticatorProvider.overrideWithValue(auth),
];
