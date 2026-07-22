import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/services/local_notification_service.dart';
import 'package:s_gizi/features/auth/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.instance.init();

  runApp(const GiziApp());
}

class GiziApp extends StatelessWidget {
  const GiziApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF4B8E96);

    return MaterialApp(
      title: 'S-Gizi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          primary: seedColor,
          secondary: SgColors.secondary,
          surface: SgColors.surface,
        ),
        scaffoldBackgroundColor: SgColors.background,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: SgColors.surface,
          foregroundColor: SgColors.textPrimary,
          titleTextStyle: AppTypography.h2,
        ),
        textTheme: const TextTheme(
          headlineLarge: AppTypography.h1,
          titleLarge: AppTypography.h2,
          titleMedium: AppTypography.h3,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.caption,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE0ECE9)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD3E4E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD3E4E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
