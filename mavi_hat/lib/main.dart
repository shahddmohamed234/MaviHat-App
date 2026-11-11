import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/di/providers.dart';
import 'core/storage/firebase_bootstrap.dart';
import 'core/storage/hive_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.tryInitialize();
  final cacheDataSource = await HiveInitializer.initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        localCacheDataSourceProvider.overrideWithValue(cacheDataSource),
      ],
      child: const MaviHatApp(),
    ),
  );
}
