import 'question_model.dart';

class MatchRoom {
  final String id;
  final String? customRoomId;
  final String category;
  final String difficulty;
  final int amount;
  final String status; // waiting, started, finished
  final int capacity;
  final String? hostUid;
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
    print('🔍 Parsing MatchRoom JSON: $json');

    try {
      return MatchRoom(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? 'unknown_id',
        customRoomId: json['customRoomId']?.toString(),
        category: json['category']?.toString() ?? 'General Knowledge',
        difficulty: json['difficulty']?.toString() ?? 'easy',
        amount: json['amount'] is int
            ? json['amount']
            : int.tryParse(json['amount']?.toString() ?? '5') ?? 5,
        status: json['status']?.toString() ?? 'waiting',
        capacity: json['capacity'] is int
            ? json['capacity']
            : int.tryParse(json['capacity']?.toString() ?? '2') ?? 2,
        hostUid: json['hostUid']?.toString(),
        players: (json['players'] as List<dynamic>? ?? [])
            .map((player) => Player.fromJson(player))
            .toList(),
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((q) => Map<String, dynamic>.from(q as Map))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e, stack) {
      print('❌ MatchRoom.fromJson failed: $e');
      print('📌 Stacktrace: $stack');
      rethrow;
    }
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customRoomId': customRoomId,
      'category': category,
      'difficulty': difficulty,
      'amount': amount,
      'status': status,
      'capacity': capacity,
      'hostUid': hostUid,
      'players': players.map((p) => p.toJson()).toList(),
      'questions': questions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Player {
  final String uid;
  final String username;
  final String photoUrl;
  final int score;
  final Map<String, String> answers;

  Player({
    required this.uid,
    required this.username,
    required this.photoUrl,
    required this.score,
    required this.answers,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      uid: json['uid']?.toString() ?? 'unknown_uid',
      username: json['username']?.toString() ?? 'Player',
      photoUrl: json['photoUrl']?.toString() ?? '',
      score: json['score'] is int
          ? json['score']
          : int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      answers: json['answers'] is Map
          ? Map<String, String>.from(json['answers'])
          : {},
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
