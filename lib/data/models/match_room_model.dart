class Player {
  final String uid;
  final String username;
  final String photoUrl;
  final int score;
  final List<String> answers;

  Player({
    required this.uid,
    required this.username,
    required this.photoUrl,
    required this.score,
    required this.answers,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      score: json['score'] ?? 0,
      answers: List<String>.from(json['answers'] ?? []),
    );
  }
}

class MatchRoom {
  final String id;
  final String category;
  final String difficulty;
  final int amount;
  final String status; // waiting, started, finished
  final List<Player> players;
  final List<dynamic> questions; // you can create a separate Question model if needed
  final DateTime createdAt;

  MatchRoom({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.amount,
    required this.status,
    required this.players,
    required this.questions,
    required this.createdAt,
  });

  factory MatchRoom.fromJson(Map<String, dynamic> json) {
    return MatchRoom(
      id: json['_id'] ?? '', // MongoDB uses _id
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? 'waiting',
      players: (json['players'] as List<dynamic>? ?? [])
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
      questions: json['questions'] ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
