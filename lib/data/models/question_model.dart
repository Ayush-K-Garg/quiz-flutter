class Question {
  final String question;
  final String correctAnswer;
  final List<String> allAnswers;

  Question({
    required this.question,
    required this.correctAnswer,
    required this.allAnswers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question']?.toString() ?? '',
      correctAnswer: json['correct_answer']?.toString() ?? '',
      allAnswers: (json['all_answers'] as List<dynamic>? ?? [])
          .map((e) => e?.toString() ?? '')
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'correct_answer': correctAnswer,
      'all_answers': allAnswers,
    };
  }
}
