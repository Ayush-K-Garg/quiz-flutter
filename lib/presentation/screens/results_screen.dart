import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz/data/models/question_model.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final List<Question> questions;
  final Map<int, String> selectedAnswers;
  final String? roomId;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.selectedAnswers,
    this.roomId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<dynamic> leaderboard = [];
  bool loading = true;
  final unescape = HtmlUnescape();

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    final url = 'https://quiz-backend-lnrb.onrender.com/api/match/leaderboard/${widget.roomId}';
    print('\n📡 [ResultScreen] Fetching leaderboard from: $url');

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        print('❌ No auth token available');
        throw Exception('No token provided');
      }

      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data.containsKey('leaderboard')) {
          final lb = List<Map<String, dynamic>>.from(data['leaderboard']);
          lb.sort((a, b) => b['score'].compareTo(a['score']));
          setState(() {
            leaderboard = lb;
            loading = false;
          });
        } else {
          setState(() => loading = false);
        }
      } else {
        throw Exception('❌ Failed to fetch leaderboard. Code: ${res.statusCode}');
      }
    } catch (e) {
      print('🚨 Leaderboard fetch error: $e');
      setState(() => loading = false);
    }
  }

  Widget buildLeaderboard() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leaderboard.isEmpty) {
      return Column(
        children: [
          const Text('No leaderboard data available.'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: fetchLeaderboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Refreshing'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: fetchLeaderboard,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Leaderboard'),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          itemCount: leaderboard.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final player = leaderboard[index];
            final name = player['name'] ?? 'Unknown';
            final picture = player['picture'] ?? '';
            final score = player['score'] ?? 0;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: picture.isNotEmpty
                      ? NetworkImage(picture)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                title: Text('$name'),
                trailing: Text('$score pts', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildQuestionReview() {
    return Expanded(
      child: ListView.builder(
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final q = widget.questions[index];
          final question = unescape.convert(q.question);
          final correct = unescape.convert(q.correctAnswer);
          final selected = widget.selectedAnswers[index] != null
              ? unescape.convert(widget.selectedAnswers[index]!)
              : 'Skipped';
          final isCorrect = selected == correct;

          return Card(
            elevation: 2,
            color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(question),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Your Answer: $selected'),
                  Text('Correct Answer: $correct'),
                ],
              ),
              trailing: Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E1E3F),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 Score: ${widget.score} / ${widget.total}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),

            if (widget.roomId != null) ...[
              const Text('🏆 Final Leaderboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              buildLeaderboard(),
              const Divider(thickness: 1, color: Colors.white24),
              const SizedBox(height: 16),
            ],

            const Text('📋 Question Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            buildQuestionReview(),
          ],
        ),
      ),
    );
  }
}
