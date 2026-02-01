import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth_choice_screen.dart';

// ViewModels & Repositories
import 'viewmodels/settings_view_model.dart';
import 'viewmodels/auth_view_model.dart'; // Added import
import 'presentation/viewmodels/visits_view_model.dart';
import 'presentation/viewmodels/dashboard_view_model.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'data/repositories/measurement_repository_impl.dart';
import 'viewmodels/profile_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Notifications must never block app startup
  await NotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()..loadSettings()), 
        ChangeNotifierProvider(create: (_) => AuthViewModel()), // Added provider
        ChangeNotifierProvider(create: (_) => VisitsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            profileRepository: ProfileRepositoryImpl(),
            measurementRepository: MeasurementRepositoryImpl(),
          ),
        ),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Health Tracker',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
              useMaterial3: true,
            ),
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: const [
              Locale('en', ''), 
              Locale('ar', ''), 
            ],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthChoiceScreen(),
          );
        },
      ),
    );
  }
}
