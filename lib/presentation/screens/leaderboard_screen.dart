import 'package:flutter/material.dart';
import 'package:quiz/core/services/quiz_api.dart';

class LeaderboardScreen extends StatefulWidget {
  final String roomId;

  const LeaderboardScreen({super.key, required this.roomId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final QuizApi quizApi = QuizApi();
  List<dynamic> leaderboard = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      final data = await quizApi.getLeaderboard(widget.roomId);
      setState(() {
        leaderboard = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to load leaderboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : leaderboard.isEmpty
          ? const Center(child: Text('No players yet.'))
          : ListView.builder(
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final player = leaderboard[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(player['photoUrl'] ?? ''),
              child: player['photoUrl'] == null
                  ? Text(player['username'][0])
                  : null,
            ),
            title: Text(player['username']),
            trailing: Text(
              '${player['score']} pts',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
