import 'package:get/get.dart';
import '../modules/game/controllers/player_controller.dart';
import '../modules/game/controllers/world_controller.dart';
import '../modules/game/controllers/game_controller.dart';

class GameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PlayerController());
    Get.lazyPut(() => WorldController());
    Get.lazyPut(() => GameController());
  }
}
