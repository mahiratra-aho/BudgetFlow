import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_initialisation.dart';
import 'core/theme/app_theme.dart';
import 'navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await ServiceInitialisationApp.instance.demarrerCritique();
  runApp(const ProviderScope(child: AppBudgetFlow()));
  Future<void>(() async {
    await ServiceInitialisationApp.instance.demarrerSecondaire();
  });
}

class AppBudgetFlow extends ConsumerWidget {
  const AppBudgetFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BF',
      debugShowCheckedModeBanner: false,
      theme: creerTheme(),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppNavigation(),
    );
  }
}
