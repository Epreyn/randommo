import 'package:get/get.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/position_model.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/game_service.dart';

class PlayerController extends GetxController {
  final PlayerRepository _playerRepo = Get.find();
  final AuthService _authService = Get.find();

  final Rxn<Player> currentPlayer = Rxn<Player>();
  final RxList<Player> nearbyPlayers = <Player>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    isLoading.value = true;

    final userId = _authService.currentUserId;
    if (userId == null) return;

    Player? player = await _playerRepo.getPlayer(userId);

    if (player == null) {
      player = Player(
        id: userId,
        name: 'Player_${userId.substring(0, 6)}',
        position: const Position(x: 0, y: 0),
        revealedTiles: ['0_0'],
        lastActive: DateTime.now(),
      );

      await _playerRepo.createPlayer(player);
    }

    _playerRepo.playerStream(userId).listen((player) {
      currentPlayer.value = player;
      if (player != null) {
        _watchNearbyPlayers(player.position);
      }
    });

    isLoading.value = false;
  }

  void _watchNearbyPlayers(Position center) {
    _playerRepo.playersInAreaStream(center, 10).listen((players) {
      nearbyPlayers.value = players.where((p) => p.id != currentPlayer.value?.id).toList();
    });
  }

  Future<bool> moveToPosition(Position newPosition) async {
    final player = currentPlayer.value;
    if (player == null) return false;

    final gameService = Get.find<GameService>();
    return await gameService.movePlayer(player.id, player.position, newPosition);
  }
}
