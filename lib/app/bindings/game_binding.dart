// lib/app/bindings/game_binding.dart
import 'package:get/get.dart';
import '../modules/game/controllers/game_controller.dart';

class GameBinding extends Bindings {
  @override
  void dependencies() {
    // Un seul contrôleur pour tout gérer
    Get.lazyPut(() => GameController());
  }
}
