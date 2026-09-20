class PlayerModel {
  final String name;
  final String role;
  final bool isCaptain;
  final bool isWicketKeeper;

  const PlayerModel({
    required this.name,
    required this.role,
    this.isCaptain = false,
    this.isWicketKeeper = false,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      name: map['name'] as String? ?? 'Player',
      role: map['role'] as String? ?? 'Player',
      isCaptain: map['isCaptain'] as bool? ?? false,
      isWicketKeeper: map['isWicketKeeper'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'isCaptain': isCaptain,
      'isWicketKeeper': isWicketKeeper,
    };
  }
}
