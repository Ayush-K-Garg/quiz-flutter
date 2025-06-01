import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final List<dynamic> questions;
  final Map<int, String> selectedAnswers;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Score: $score / $total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final question = unescape.convert(q['question']);
                  final correct = unescape.convert(q['correct_answer']);
                  final selected = selectedAnswers[index] != null ? unescape.convert(selectedAnswers[index]!) : 'Skipped';

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
                      trailing: Icon(isCorrect ? Icons.check : Icons.close, color: isCorrect ? Colors.green : Colors.red),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
