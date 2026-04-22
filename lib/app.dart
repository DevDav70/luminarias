import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/luminarias/pages/home_page.dart';

class LuminariasApp extends StatelessWidget {
  const LuminariasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Luminarias',
      theme: AppTheme.lightTheme,
      locale: const Locale('es', 'ES'), // 👈 IMPORTANTE
      home: const HomePage(),
    );
  }
}
