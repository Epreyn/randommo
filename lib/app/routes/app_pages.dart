import 'package:get/get.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/game/views/game_view.dart';
import '../bindings/game_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
    ),
    GetPage(
      name: Routes.AUTH,
      page: () => const AuthView(),
    ),
    GetPage(
      name: Routes.GAME,
      page: () => const GameView(),
      binding: GameBinding(),
    ),
  ];
}
