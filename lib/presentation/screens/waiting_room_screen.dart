import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/data/models/question_model.dart';
import 'quiz_screen.dart';
import 'package:quiz/core/services/socket_service.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';


class WaitingRoomScreen extends StatefulWidget {
  final String roomId;
  final int capacity;
  final bool isHost;

  const WaitingRoomScreen({
    Key? key,
    required this.roomId,
    required this.isHost,
    this.capacity = 3,
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

  static const _baseUrl = 'https://quiz-backend-lnrb.onrender.com/api/match';

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
        print('👥 Updated joined count: $_joinedCount');
      } else {
        print('❌ Failed to fetch leaderboard: ${res.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error during leaderboard fetch: $e');
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

      print('📤 Match start requested: ${response.statusCode}');
    } catch (e) {
      print('❌ Start match failed: $e');
    }

    setState(() => _isStarting = false);
  }

  void _initializeSocketConnection() {
    _socketService.connect(onConnected: () {
      _socketService.joinRoom(widget.roomId);
      _socketService.listenForMatchStarted((questions, matchRoom) {
        print("⚡ Socket matchStarted received: ${questions.length} questions");

        _statusPollingTimer?.cancel();
        _leaderboardTimer?.cancel();

        if (!mounted) return;

        context.goNamed(
          'quiz',
          extra: {
            'questions': questions,
            'matchRoom': matchRoom,
          },
        );

      });
    });
  }

  void _startPollingMatchStatus() {
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_matchStarted) return;

      final token = await _getToken();
      if (token == null) {
        print('⚠️ No auth token found for polling.');
        return;
      }

      try {
        final statusRes = await http.get(
          Uri.parse('$_baseUrl/status/${widget.roomId}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (statusRes.statusCode == 200) {
          final json = jsonDecode(statusRes.body);
          final status = json['status'];
          print('🟡 Polling: Status = $status');

          if (status == 'started') {
            print('⏳ Polling: Match started! Fetching full room data...');
            _matchStarted = true;
            _statusPollingTimer?.cancel();
            _leaderboardTimer?.cancel();

            final roomRes = await http.get(
              Uri.parse('$_baseUrl/debug-room/${widget.roomId}'),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (roomRes.statusCode == 200) {
              final Map<String, dynamic> roomJson = jsonDecode(roomRes.body);
              print('📦 Room JSON fetched: ${roomJson.toString()}');

              // Try parsing MatchRoom
              late MatchRoom matchRoom;
              try {
                matchRoom = MatchRoom.fromJson(roomJson);
                print('✅ MatchRoom parsed successfully.');
              } catch (e) {
                print('❌ Failed to parse MatchRoom: $e');
                return;
              }

              // Parse raw questions
              final rawQuestions = roomJson['questions'] as List? ?? [];
              print('📋 Total raw questions: ${rawQuestions.length}');

              // Log every question
              for (int i = 0; i < rawQuestions.length; i++) {
                final q = rawQuestions[i];
                print('🔍 Q[$i] Raw: $q');
              }

              // Safely parse each question
              final List<Question> questions = [];
              for (int i = 0; i < rawQuestions.length; i++) {
                final q = rawQuestions[i];
                try {
                  final hasAllFields = q is Map &&
                      q['question'] != null &&
                      q['correct_answer'] != null &&
                      q['all_answers'] != null &&
                      q['question'] is String &&
                      q['correct_answer'] is String &&
                      q['all_answers'] is List;

                  if (!hasAllFields) {
                    print('⚠️ Q[$i] Skipped - Missing or invalid fields.');
                    continue;
                  }

                  final question = Question.fromJson(
                      Map<String, dynamic>.from(q));
                  questions.add(question);
                  print('✅ Q[$i] Parsed successfully: ${question.question}');
                } catch (e) {
                  print('❌ Q[$i] Failed to parse: $e');
                }
              }

              print('✅ Total questions parsed: ${questions.length}');
              print('👥 Players in room: ${matchRoom.players.length}');

              // Navigate to QuizScreen if safe
              if (mounted) {
                context.goNamed(
                  'quiz',
                  extra: {
                    'questions': questions,
                    'matchRoom': matchRoom,
                  },
                );

              }
            } else {
              print('❌ Failed to fetch room data: ${roomRes.statusCode}');
            }
          }
        } else {
          print('❌ Polling failed: ${statusRes.statusCode}');
        }
      } catch (e) {
        print('⚠️ Polling exception: $e');
      }
    });
  }


  @override
  void initState() {
    super.initState();
    _initializeSocketConnection();
    _refreshStatus();
    _leaderboardTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _refreshStatus());
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
    final capacity = widget.capacity;
    final canStart = widget.isHost && _joinedCount >= 2;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E3F),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Waiting Room'),
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 📋 ROOM CODE BOX
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.roomId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied Room Code: ${widget.roomId}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                // FIX: The Row now expands to fill the width
                child: Row(
                  // REMOVED: mainAxisSize: MainAxisSize.min
                  children: [
                    const Icon(Icons.copy, size: 20, color: Colors.white70),
                    const SizedBox(width: 8),
                    // FIX: Expanded allows the text area to grow and fill the remaining space
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft, // Aligns text to the left
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Room Code: ${widget.roomId}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '👥 Players Joined: $_joinedCount / $capacity',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 24),

            /// 🎮 HOST OPTIONS
            if (widget.isHost) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: const Color(0xFF2C2C54),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Category'),
                      items: categories
                          .map((c) =>
                          DropdownMenuItem(
                            value: c,
                            child: Text(
                                c, style: const TextStyle(color: Colors.white)),
                          ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDifficulty,
                      dropdownColor: const Color(0xFF2C2C54),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Difficulty'),
                      items: difficulties
                          .map((d) =>
                          DropdownMenuItem(
                            value: d,
                            child: Text(
                                d, style: const TextStyle(color: Colors.white)),
                          ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedDifficulty = val!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: selectedAmount.toString(),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Number of Questions'),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setState(() => selectedAmount = parsed);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A00E0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 28),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: canStart && !_isStarting ? _startMatch : null,
                      label: _isStarting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Start Match'),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      onPressed: () {
                        Share.share(
                          '''🎮 Join my TriviQ match!

Room Code: ${widget.roomId}

📲 Install the app from:
https://drive.google.com/drive/folders/15ohVxoWS5C-sy11jBrxi8qS57MatzC8k?usp=sharing

🔔 Copy the room code and enter it in the app to join the quiz!''',
                        );
                      },
                      label: const Text('Invite Players'),
                    ),
                  ],
                ),
              ),
            ] else
              ...[
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    '⌛ Waiting for host to start...',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white12,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
