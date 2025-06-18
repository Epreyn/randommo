import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find();
  final RxBool isLoading = false.obs;

  Future<void> signInAnonymously() async {
    isLoading.value = true;

    final user = await _authService.signInAnonymously();

    if (user != null) {
      Get.offAllNamed(Routes.GAME);
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible de se connecter. Veuillez réessayer.',
        snackPosition: SnackPosition.TOP,
      );
    }

    isLoading.value = false;
  }
}
