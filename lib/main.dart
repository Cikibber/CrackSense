import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/storage/hive_service.dart';
import 'services/storage/storage_providers.dart';

/// Application entry point.
///
/// Initializes critical services before rendering:
/// 1. Flutter binding initialization
/// 2. System UI chrome configuration
/// 3. Hive local storage initialization
/// 4. TFLite model is loaded lazily on first use
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI for the humanist light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock to portrait orientation for consistent layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive local storage
  final hiveService = HiveService();
  await hiveService.initialize();

  // Launch the application wrapped in Riverpod's ProviderScope
  runApp(
    ProviderScope(
      overrides: [
        // Pre-inject the initialized HiveService so providers can use it immediately
        hiveServiceProvider.overrideWithValue(hiveService),
      ],
      child: const CrackSenseApp(),
    ),
  );
}
