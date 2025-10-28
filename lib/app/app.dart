import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/splash_screen.dart';
import 'routes/app_routes.dart';
import '../themes/app_theme.dart';

// RouteObserver para permitir a pantallas (como HomeScreen)
// suscribirse a eventos de navegación (push/pop) y ocultar/mostrar
// overlays (por ejemplo el FAB en overlay) cuando se abren modales.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      // Registramos el RouteObserver global para que las pantallas
      // puedan reaccionar cuando se abran/pinten rutas modales.
      navigatorObservers: [routeObserver],
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
      },
    );
  }
}
