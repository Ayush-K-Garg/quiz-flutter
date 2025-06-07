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
      question: json['question'],
      correctAnswer: json['correct_answer'],
      allAnswers: List<String>.from(json['all_answers']),
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
