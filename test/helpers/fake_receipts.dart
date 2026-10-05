import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:personal_finance/data/receipts/receipt_store.dart';

/// Receipt store that keeps names in memory, because real file work
/// does not finish inside widget tests.
class FakeReceiptStore extends ReceiptStore {
  FakeReceiptStore() : super(() async => Directory.systemTemp);

  final saved = <String>[];
  final deleted = <String>[];
  var _next = 0;

  @override
  Future<String> save(String sourcePath) async {
    final name = 'r_test_${_next++}.jpg';
    saved.add(name);
    return name;
  }

  @override
  Future<File?> file(String name) async => null;

  @override
  Future<void> delete(String name) async => deleted.add(name);
}

/// Overrides for the receipt store and a picker that always "picks" a
/// photo without opening the camera.
List<Override> fakeReceiptOverrides(FakeReceiptStore store) => [
  receiptStoreProvider.overrideWithValue(store),
  receiptPickerProvider.overrideWithValue((_) async => '/tmp/photo.jpg'),
];
