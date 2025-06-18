import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/data/models/question_model.dart';
import 'quiz_screen.dart';
import 'package:quiz/core/services/socket_service.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomId;
  final int capacity;
  final bool isHost;

  const WaitingRoomScreen({
    Key? key,
    required this.roomId,
    required this.isHost,
    this.capacity=2,
  }) : super(key: key);

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  int _joinedCount = 1;
  Timer? _leaderboardTimer;
  Timer? _statusPollingTimer;
  bool _isStarting = false;
  bool _matchStarted = false;

  static const _baseUrl = 'http://10.0.2.2:3000/api/match';

  final List<String> categories = [
    'General Knowledge', 'Science', 'Mathematics', 'History', 'Geography',
    'Sports', 'Politics', 'Music', 'Art', 'Technology', 'Books',
    'Movies', 'Computer Science', 'Nature'
  ];
  final List<String> difficulties = ['easy', 'medium', 'hard'];

  String selectedCategory = 'General Knowledge';
  String selectedDifficulty = 'easy';
  int selectedAmount = 5;

  final SocketService _socketService = SocketService();

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<void> _refreshStatus() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final uri = Uri.parse('$_baseUrl/leaderboard/${widget.roomId}');
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final arr = data['leaderboard'] as List<dynamic>? ?? [];
        setState(() => _joinedCount = arr.length);
        debugPrint('👥 Updated joined count: $_joinedCount');
      } else {
        debugPrint('❌ Failed to fetch leaderboard: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error during leaderboard fetch: $e');
    }
  }

  Future<void> _startMatch() async {
    setState(() => _isStarting = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed')),
      );
      return;
    }

    try {
      final uri = Uri.parse('$_baseUrl/start');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'roomId': widget.roomId,
          'category': selectedCategory,
          'difficulty': selectedDifficulty,
          'questionCount': selectedAmount,
        }),
      );

      debugPrint('📤 Match start requested: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Start match failed: $e');
    }

    setState(() => _isStarting = false);
  }

  void _initializeSocketConnection() {
    _socketService.connect(onConnected: () {
      _socketService.joinRoom(widget.roomId);
      _socketService.listenForMatchStarted((questions, matchRoom) {
        debugPrint("⚡ Socket matchStarted received: ${questions.length} questions");

        _statusPollingTimer?.cancel();
        _leaderboardTimer?.cancel();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              questions: questions,
              matchRoom: matchRoom,
            ),
          ),
        );
      });
    });
  }

  void _startPollingMatchStatus() {
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_matchStarted) return;

      final token = await _getToken();
      if (token == null) return;

      try {
        final res = await http.get(
          Uri.parse('$_baseUrl/status/${widget.roomId}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          if (json['status'] == 'started') {
            debugPrint('⏳ Polling: Match started! Fetching questions...');
            _matchStarted = true;
            _statusPollingTimer?.cancel();
            _leaderboardTimer?.cancel();

            final qRes = await http.get(
              Uri.parse('$_baseUrl/match/${widget.roomId}/questions'),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (qRes.statusCode == 200) {
              final List<Question> questions = (jsonDecode(qRes.body) as List)
                  .map((e) => Question.fromJson(e))
                  .toList();

              final matchRoom = MatchRoom(
                id: widget.roomId,
                category: selectedCategory,
                difficulty: selectedDifficulty,
                amount: selectedAmount,
                status: 'started',
                players: [],
                questions: questions.map((q) => q.toJson()).toList(), // ✅ Fixed here
                createdAt: DateTime.now(),
                capacity: widget.capacity,
              );

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      questions: questions,
                      matchRoom: matchRoom,
                    ),
                  ),
                );
              }
            }

          }
        } else {
          debugPrint('❌ Polling failed: ${res.statusCode}');
        }
      } catch (e) {
        debugPrint('⚠️ Polling error: $e');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSocketConnection();
    _refreshStatus();
    _leaderboardTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refreshStatus());
    _startPollingMatchStatus();
  }

  @override
  void dispose() {
    _leaderboardTimer?.cancel();
    _statusPollingTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capacity = widget.capacity ?? 2;
    final canStart = widget.isHost && _joinedCount >= 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room ID: ${widget.roomId}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Players Joined: $_joinedCount / $capacity', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),

            if (widget.isHost) ...[
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedDifficulty,
                items: difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setState(() => selectedDifficulty = val!),
                decoration: const InputDecoration(labelText: 'Difficulty'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: selectedAmount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of Questions'),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed > 0) {
                    setState(() => selectedAmount = parsed);
                  }
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: canStart && !_isStarting ? _startMatch : null,
                child: _isStarting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Start Match'),
              ),
            ] else ...[
              const SizedBox(height: 24),
              const Text('Waiting for host to start...', style: TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
