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

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'photoUrl': photoUrl,
      'score': score,
      'answers': answers,
    };
  }
}

class MatchRoom {
  final String id;
  final String? customRoomId;  // nullable, optional
  final String category;
  final String difficulty;
  final int amount;
  final String status;
  final int capacity;
  final String? hostUid;       // nullable, optional
  final List<Player> players;
  final List<Map<String, dynamic>> questions;
  final DateTime createdAt;

  MatchRoom({
    required this.id,
    this.customRoomId,
    required this.category,
    required this.difficulty,
    required this.amount,
    required this.status,
    required this.capacity,
    this.hostUid,
    required this.players,
    required this.questions,
    required this.createdAt,
  });

  factory MatchRoom.fromJson(Map<String, dynamic> json) {
    return MatchRoom(
      id: json['_id'] ?? '',
      customRoomId: json['customRoomId'],
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? 'waiting',
      capacity: json['capacity'] ?? 2,
      hostUid: json['hostUid'],
      players: (json['players'] as List<dynamic>? ?? [])
          .map((e) => Player.fromJson(e))
          .toList(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => Map<String, dynamic>.from(q))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      if (customRoomId != null) 'customRoomId': customRoomId,
      'category': category,
      'difficulty': difficulty,
      'amount': amount,
      'status': status,
      'capacity': capacity,
      if (hostUid != null) 'hostUid': hostUid,
      'players': players.map((e) => e.toJson()).toList(),
      'questions': questions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
