import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_finance/data/receipts/receipt_store.dart';

void main() {
  late Directory dir;
  late ReceiptStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('receipts_test');
    store = ReceiptStore(() async => dir);
  });
  tearDown(() => dir.delete(recursive: true));

  test('save copies the photo and returns only its name', () async {
    final source = File(p.join(dir.path, 'picked.PNG'))
      ..writeAsBytesSync([1, 2, 3]);
    final name = await store.save(source.path);

    expect(name, isNot(contains('/')));
    expect(name, endsWith('.png'));
    final saved = await store.file(name);
    expect(saved!.readAsBytesSync(), [1, 2, 3]);
  });

  test('delete removes the file and ignores missing ones', () async {
    final source = File(p.join(dir.path, 'picked.jpg'))..writeAsBytesSync([9]);
    final name = await store.save(source.path);
    await store.delete(name);
    expect(await store.file(name), isNull);
    await store.delete('does_not_exist.jpg');
  });
}
