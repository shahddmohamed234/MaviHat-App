import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'cache_keys.dart';
import 'local_cache_datasource.dart';

/// Initializes Hive CE for local persistence or falls back to in-memory storage
/// during unit/widget tests.
abstract final class HiveInitializer {
  static Future<LocalCacheDataSource> initialize({
    bool inMemory = false,
  }) async {
    if (inMemory) {
      final dataSource = InMemoryCacheDataSource();
      await dataSource.ensureSeeded();
      return dataSource;
    }

    try {
      await Hive.initFlutter();
      final box = await Hive.openBox<dynamic>(CacheKeys.boxName);
      final dataSource = HiveCacheDataSource(box);
      await dataSource.ensureSeeded();
      return dataSource;
    } catch (_) {
      final fallback = InMemoryCacheDataSource();
      await fallback.ensureSeeded();
      return fallback;
    }
  }
}

