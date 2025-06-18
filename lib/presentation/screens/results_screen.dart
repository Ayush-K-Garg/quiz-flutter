import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quiz/data/models/question_model.dart'; // Make sure this path is correct

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
    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/leaderboard/${widget.roomId}'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          leaderboard = List<Map<String, dynamic>>.from(data);
          leaderboard.sort((a, b) => b['score'].compareTo(a['score']));
          loading = false;
        });
      } else {
        throw Exception('Failed to fetch leaderboard');
      }
    } catch (e) {
      debugPrint('Leaderboard error: $e');
      setState(() => loading = false);
    }
  }

  Widget buildLeaderboard() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leaderboard.isEmpty) {
      return const Text('No leaderboard data available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: leaderboard.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final player = entry.value;
        final username = player['username'] ?? 'Unknown';
        final photoUrl = player['photoUrl'] ?? '';
        final score = player['score'] ?? 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          title: Text('$i. $username'),
          trailing: Text('$score pts'),
        );
      }).toList(),
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
            color: isCorrect ? Colors.green[50] : Colors.red[50],
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(question),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
      appBar: AppBar(title: const Text('Quiz Results')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 Score: ${widget.score} / ${widget.total}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (widget.roomId != null) ...[
              const Text('🏆 Final Leaderboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              buildLeaderboard(),
              const Divider(thickness: 1),
            ],

            const SizedBox(height: 10),
            const Text('📋 Question Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildQuestionReview(),
          ],
        ),
      ),
    );
  }
}
