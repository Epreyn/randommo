// lib/app/bindings/initial_binding.dart
import 'package:get/get.dart';
import '../services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Seulement le service d'authentification au démarrage
    Get.put(AuthService());
  }
}
