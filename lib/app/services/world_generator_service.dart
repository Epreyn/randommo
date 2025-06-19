// lib/app/services/world_generator_service.dart
import 'dart:math';
import '../data/models/position_model.dart';
import '../data/models/tile_model.dart';

class WorldGeneratorService {
  static final Random _random = Random();

  // Cache pour la cohérence des biomes
  static final Map<String, TileType> _generatedTiles = {};

  // Configuration de la génération
  static const double _waterClusterChance =
      0.7; // Chance qu'une tuile d'eau génère de l'eau à côté
  static const double _mountainClusterChance =
      0.6; // Chance qu'une montagne génère une montagne à côté
  static const double _baseWaterChance = 0.15; // 15% de base pour l'eau
  static const double _baseMountainChance =
      0.10; // 10% de base pour les montagnes

  // Enregistre une tuile existante dans le cache (utile pour les tuiles chargées depuis BDD)
  static void registerExistingTile(Position position, TileType type) {
    final tileId = '${position.x}_${position.y}';
    _generatedTiles[tileId] = type;
  }

  // Génère une tuile avec cohérence spatiale
  static Tile generateTile(Position position, String createdBy) {
    final tileId = '${position.x}_${position.y}';

    // Si déjà générée, retourner le type existant
    if (_generatedTiles.containsKey(tileId)) {
      return Tile(
        id: tileId,
        position: position,
        type: _generatedTiles[tileId]!,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );
    }

    // Analyser les tuiles voisines pour la cohérence
    final neighborTypes = _getNeighborTypes(position);

    // Générer le type selon les voisins et les règles
    TileType type = _generateTileType(position, neighborTypes);

    // Vérifier que le joueur n'est pas bloqué
    if (_wouldBlockPlayer(position, type)) {
      type = TileType.grass; // Forcer de l'herbe pour garantir un passage
    }

    // Mettre en cache
    _generatedTiles[tileId] = type;

    return Tile(
      id: tileId,
      position: position,
      type: type,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  // Récupère les types des tuiles voisines (4 directions seulement)
  static Map<TileType, int> _getNeighborTypes(Position center) {
    final counts = {
      TileType.grass: 0,
      TileType.water: 0,
      TileType.mountain: 0,
    };

    // Vérifier les 4 voisins directs
    const directions = [
      [0, -1], // Nord
      [1, 0], // Est
      [0, 1], // Sud
      [-1, 0], // Ouest
    ];

    for (final dir in directions) {
      final neighborId = '${center.x + dir[0]}_${center.y + dir[1]}';
      if (_generatedTiles.containsKey(neighborId)) {
        counts[_generatedTiles[neighborId]!] =
            counts[_generatedTiles[neighborId]!]! + 1;
      }
    }

    return counts;
  }

  // Génère un type de tuile selon les voisins
  static TileType _generateTileType(
      Position position, Map<TileType, int> neighbors) {
    final totalNeighbors =
        neighbors.values.fold(0, (sum, count) => sum + count);

    // Si pas de voisins, génération normale
    if (totalNeighbors == 0) {
      return _generateRandomType();
    }

    // Calculer les probabilités selon les voisins
    double waterChance = _baseWaterChance;
    double mountainChance = _baseMountainChance;

    // Augmenter les chances selon les voisins du même type
    if (neighbors[TileType.water]! > 0) {
      waterChance += _waterClusterChance * (neighbors[TileType.water]! / 4.0);
    }
    if (neighbors[TileType.mountain]! > 0) {
      mountainChance +=
          _mountainClusterChance * (neighbors[TileType.mountain]! / 4.0);
    }

    // Normaliser si nécessaire
    waterChance = waterChance.clamp(0.0, 0.8); // Max 80% de chance pour l'eau
    mountainChance =
        mountainChance.clamp(0.0, 0.7); // Max 70% de chance pour les montagnes

    // Générer selon les probabilités
    final roll = _random.nextDouble();

    if (roll < waterChance) {
      return TileType.water;
    } else if (roll < waterChance + mountainChance) {
      return TileType.mountain;
    } else {
      return TileType.grass;
    }
  }

  // Génération de base sans voisins
  static TileType _generateRandomType() {
    final roll = _random.nextDouble();

    if (roll < _baseWaterChance) {
      return TileType.water;
    } else if (roll < _baseWaterChance + _baseMountainChance) {
      return TileType.mountain;
    } else {
      return TileType.grass;
    }
  }

  // Vérifie si placer cette tuile bloquerait le joueur
  static bool _wouldBlockPlayer(Position position, TileType type) {
    // Si c'est de l'herbe, pas de blocage
    if (type == TileType.grass) return false;

    // Vérifier dans un rayon de 2 cases (distance Manhattan) s'il reste au moins un chemin d'herbe
    int grassCount = 0;
    int totalChecked = 0;

    for (int dx = -2; dx <= 2; dx++) {
      for (int dy = -2; dy <= 2; dy++) {
        if (dx.abs() + dy.abs() > 2) continue; // Distance Manhattan max 2

        final checkPos = Position(x: position.x + dx, y: position.y + dy);
        final tileId = checkPos.id;

        if (_generatedTiles.containsKey(tileId)) {
          totalChecked++;
          if (_generatedTiles[tileId] == TileType.grass) {
            grassCount++;
          }
        }
      }
    }

    // S'il y a peu de tuiles générées, on ne bloque pas
    if (totalChecked < 5) return false;

    // S'assurer qu'il reste au moins 40% d'herbe dans la zone (plus permissif car moins de directions)
    final grassRatio = grassCount / totalChecked;
    return grassRatio < 0.4;
  }

  // Trouve un chemin praticable depuis une position
  static bool hasWalkablePath(
      Position from, Position to, Set<String> checkedTiles) {
    // Pathfinding simple pour vérifier l'accessibilité
    if (from == to) return true;

    // Limite de recherche pour éviter l'infini
    if (checkedTiles.length > 100) return false;

    checkedTiles.add(from.id);

    // Vérifier les 4 directions
    const directions = [
      [0, -1], // Nord
      [1, 0], // Est
      [0, 1], // Sud
      [-1, 0], // Ouest
    ];

    for (final dir in directions) {
      final nextPos = Position(x: from.x + dir[0], y: from.y + dir[1]);
      final nextId = nextPos.id;

      // Si déjà vérifié, passer
      if (checkedTiles.contains(nextId)) continue;

      // Si c'est de l'herbe ou pas encore généré, c'est praticable
      if (!_generatedTiles.containsKey(nextId) ||
          _generatedTiles[nextId] == TileType.grass) {
        // Récursion pour continuer le chemin
        if (hasWalkablePath(nextPos, to, checkedTiles)) {
          return true;
        }
      }
    }

    return false;
  }

  // Génère les positions de la case actuelle et des 4 cases adjacentes
  static List<Position> getSurroundingPositions(Position center) {
    return [
      center, // Position centrale
      Position(x: center.x, y: center.y - 1), // Nord
      Position(x: center.x + 1, y: center.y), // Est
      Position(x: center.x, y: center.y + 1), // Sud
      Position(x: center.x - 1, y: center.y), // Ouest
    ];
  }

  // Calcule la distance entre deux positions
  static double getDistance(Position a, Position b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  // Vérifie si un déplacement est valide (4 directions seulement)
  static bool isValidMove(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;

    // Vérifier que c'est un mouvement d'une case dans une des 4 directions
    return (dx == 0 && dy.abs() == 1) || (dy == 0 && dx.abs() == 1);
  }

  // Nettoie le cache (utile pour les tests)
  static void clearCache() {
    _generatedTiles.clear();
  }

  // Précharge une zone pour améliorer la cohérence
  static void preloadArea(Position center, int radius) {
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        final pos = Position(x: center.x + dx, y: center.y + dy);
        if (!_generatedTiles.containsKey(pos.id)) {
          // Simuler la génération sans créer de Tile
          final neighbors = _getNeighborTypes(pos);
          final type = _generateTileType(pos, neighbors);

          if (!_wouldBlockPlayer(pos, type)) {
            _generatedTiles[pos.id] = type;
          } else {
            _generatedTiles[pos.id] = TileType.grass;
          }
        }
      }
    }
  }
}
