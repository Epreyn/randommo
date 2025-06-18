class Position {
  final int x;
  final int y;

  const Position({required this.x, required this.y});

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      x: map['x'] ?? 0,
      y: map['y'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  String get id => '${x}_$y';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
