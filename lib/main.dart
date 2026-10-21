import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'data/preferences_repository.dart';
import 'services/form_factor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final prefs = await SharedPreferences.getInstance();
  final watchShape = await detectWatchShape();
  runApp(
    HydraFlowApp(
      preferences: PreferencesRepository(prefs),
      watchShape: watchShape,
    ),
  );
}
