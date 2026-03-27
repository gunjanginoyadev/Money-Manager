import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_IN', null);
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // App still runs in local-only mode when .env is missing.
  }
  runApp(const MoneyManagerApp());
}
