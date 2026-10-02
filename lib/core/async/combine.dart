import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Joins two async values: an error if either failed, loading until
/// both have data, then both values as a record.
AsyncValue<(A, B)> combine2<A, B>(AsyncValue<A> a, AsyncValue<B> b) {
  for (final v in [a, b]) {
    if (v case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
  }
  if (a.hasValue && b.hasValue) {
    return AsyncData((a.requireValue, b.requireValue));
  }
  return const AsyncLoading();
}

/// Like [combine2], for three values.
AsyncValue<(A, B, C)> combine3<A, B, C>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  AsyncValue<C> c,
) => combine2(combine2(a, b), c).whenData((v) => (v.$1.$1, v.$1.$2, v.$2));
