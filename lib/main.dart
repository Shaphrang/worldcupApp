//lib\main.dart
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (error, stackTrace) {
    developer.log(
      'Failed to load assets/.env',
      error: error,
      stackTrace: stackTrace,
    );

    runApp(
      const WorldCupPredictionsApp(
        startupError:
            'Could not load assets/.env. Please check pubspec.yaml and assets/.env file.',
      ),
    );
    return;
  }

  if (!SupabaseConfig.isConfigured) {
    runApp(
      const WorldCupPredictionsApp(
        startupError:
            'Supabase URL or publishable key is missing. Please check assets/.env.',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Supabase initialization failed',
      error: error,
      stackTrace: stackTrace,
    );

    runApp(
      WorldCupPredictionsApp(
        startupError: 'Supabase initialization failed: $error',
      ),
    );
    return;
  }

  runApp(const WorldCupPredictionsApp());
}