import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/presentation/cubit/nav_bar_cubit.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'shared/cubit/shop_sync_cubit.dart';
import 'shared/providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => NavBarCubit()),
        BlocProvider(create: (_) => ShopSyncCubit(isAuthenticated: false)),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider(initialAuth: false)),
        ],
        child: const ShopSyncApp(),
      ),
    ),
  );
}

class ShopSyncApp extends StatelessWidget {
  final Widget? home;
  const ShopSyncApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final themeMode = themeProvider?.themeMode ?? ThemeMode.dark;

    return MaterialApp(
      title: 'ShopSync - Shop & Staff Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: home ?? const SplashScreen(),
    );
  }
}

