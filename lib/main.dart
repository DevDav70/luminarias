import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // 👈 AGREGAR

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es'); // 👈 AGREGAR

  await Supabase.initialize(
    url: 'https://xukyabadidkjdlzoedur.supabase.co',
    anonKey: 'sb_publishable_pfIAcbifHXYo4t2ZVFL4lQ_3LZaRbTg',
  );

  runApp(const LuminariasApp());
}