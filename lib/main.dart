import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/main_shell.dart';
import 'screens/theme_provide.dart';
import 'screens/welcome_screen.dart';
import 'services/player_service.dart';
import 'services/profile_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..load()),
        ChangeNotifierProvider(create: (_) => PlayerService()),
        ChangeNotifierProvider(create: (_) => ShellController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.accent,
        primary: kInk,
        onPrimary: Colors.white,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: theme.ground,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audio Player',
      theme: base.copyWith(
        textTheme: base.textTheme.apply(bodyColor: kInk, displayColor: kInk),
        sliderTheme: SliderThemeData(
          activeTrackColor: kInk,
          inactiveTrackColor: Colors.black12,
          thumbColor: kInk,
          overlayColor: kInk.withValues(alpha: 0.12),
          trackHeight: 4,
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kInk,
          contentTextStyle: bodyStyle(14, color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: bodyStyle(18, weight: FontWeight.w800),
          contentTextStyle: bodyStyle(14, weight: FontWeight.w500, height: 1.4),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kInk,
            textStyle: bodyStyle(14, weight: FontWeight.w700),
          ),
        ),
      ),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: child!,
      ),
      home: const WelcomeScreen(),
    );
  }
}
