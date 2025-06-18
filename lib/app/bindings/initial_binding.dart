import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../data/repositories/player_repository.dart';
import '../data/repositories/world_repository.dart';
import '../services/game_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService());

    Get.lazyPut(() => PlayerRepository());
    Get.lazyPut(() => WorldRepository());

    Get.lazyPut(() => GameService());
  }
}
