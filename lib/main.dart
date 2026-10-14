import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_config.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  await initializeDateFormatting('id_ID');
  await NotificationService.instance.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ServisKuApp());
}

class ServisKuApp extends StatelessWidget {
  const ServisKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, DataService>(
          create: (_) => DataService(),
          update: (_, auth, data) {
            data!.bindUser(auth.user?.id);
            return data;
          },
        ),
      ],
      child: MaterialApp(
        title: 'ServisKu',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.initialized) return const SplashScreen();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: auth.isLoggedIn
          ? const HomeShell(key: ValueKey('home'))
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}
