import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'sign_in_screen.dart';

class ScienceQuestion {
  const ScienceQuestion({
    required this.text,
    required this.correctAnswer,
  });

  final String text;
  final String correctAnswer;

  factory ScienceQuestion.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['difficulty'] is! String ||
        value['category'] is! String ||
        value['type'] is! String ||
        value['question'] is! String ||
        value['correct_answer'] is! String ||
        value['incorrect_answers'] is! List) {
      throw const FormatException(
        'Invalid question data.',
      );
    }

    final difficulty = Uri.decodeComponent(
      value['difficulty'] as String,
    );

    final category = Uri.decodeComponent(
      value['category'] as String,
    );

    final type = Uri.decodeComponent(
      value['type'] as String,
    );

    final text = Uri.decodeComponent(
      value['question'] as String,
    );

    final correctAnswer = Uri.decodeComponent(
      value['correct_answer'] as String,
    );

    final incorrectAnswers =
        value['incorrect_answers'] as List;

    if (category != 'Science & Nature') {
      throw const FormatException(
        'Expected Science & Nature category.',
      );
    }

    if (difficulty != 'medium') {
      throw const FormatException(
        'Expected medium difficulty.',
      );
    }

    if (type != 'boolean') {
      throw const FormatException(
        'Expected true-or-false question type.',
      );
    }

    if (text.trim().isEmpty ||
        (correctAnswer != 'True' &&
            correctAnswer != 'False') ||
        incorrectAnswers.length != 1 ||
        incorrectAnswers.first is! String) {
      throw const FormatException(
        'Invalid true-or-false question.',
      );
    }

    final incorrectAnswer = Uri.decodeComponent(
      incorrectAnswers.first as String,
    );

    if ((incorrectAnswer != 'True' &&
            incorrectAnswer != 'False') ||
        incorrectAnswer == correctAnswer) {
      throw const FormatException(
        'Invalid true-or-false answers.',
      );
    }

    return ScienceQuestion(
      text: text,
      correctAnswer: correctAnswer,
    );
  }
}

class ScienceQuizScreen extends StatefulWidget {
  const ScienceQuizScreen({super.key});

  @override
  State<ScienceQuizScreen> createState() =>
      _ScienceQuizScreenState();
}

class _ScienceQuizScreenState
    extends State<ScienceQuizScreen> {
  static final _questionUri = Uri.https(
    'opentdb.com',
    '/api.php',
    {
      'amount': '5',
      'category': '17',
      'difficulty': 'medium',
      'type': 'boolean',
      'encode': 'url3986',
    },
  );

  List<ScienceQuestion> _questions = [];

  bool _loading = true;
  String? _error;
  bool _answeredCurrentQuestion = false;
  bool? _currentAnswerCorrect;
  bool? _selectedAnswer;
  

  int _currentQuestion = 0;
  int _score = 0;
  bool _finished = false;

  final List<bool> _answers = [];
  final List<String> _review = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;

      _answeredCurrentQuestion = false;
      _currentAnswerCorrect = null;
      _selectedAnswer = null;

      _error = null;

      _questions = [];

      _currentQuestion = 0;
      _score = 0;

      _finished = false;

      _answers.clear();
      _review.clear();
    });

    try {
      final response = await http
          .get(_questionUri)
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        throw FormatException(
          'Server returned HTTP ${response.statusCode}.',
        );
      }

      final Object? data = jsonDecode(response.body);

      if (data is! Map<String, dynamic> ||
          data['response_code'] != 0) {
        throw const FormatException(
          'The trivia API did not return questions.',
        );
      }

      final results = data['results'];

      if (results is! List || results.length != 5) {
        throw const FormatException(
          'Expected five trivia questions.',
        );
      }

      final questions = results
          .map(ScienceQuestion.fromJson)
          .toList();

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _loading = false;
      });
    } on TimeoutException {
      _showError(
        'The request timed out. Please try again.',
      );
    } on http.ClientException catch (error) {
      _showError(
        'The request failed: ${error.message}',
      );
    } on FormatException catch (error) {
      _showError(
        'Could not load questions: ${error.message}',
      );
    } catch (error) {
      _showError(
        'An unexpected error occurred: $error',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _error = message;
      _loading = false;
    });
  }

  void _submitAnswer(bool answer) {
    if (_loading ||
        _finished ||
        _answeredCurrentQuestion ||
        _questions.isEmpty ||
        _currentQuestion >= _questions.length) {
      return;
    }

    final question = _questions[_currentQuestion];
    final selectedAnswer = answer ? 'True' : 'False';
    final isCorrect =
        selectedAnswer == question.correctAnswer;

    setState(() {
      _answeredCurrentQuestion = true;
      _currentAnswerCorrect = isCorrect;
      _selectedAnswer = answer;
      if (isCorrect) {
        _score++;
      }

      _answers.add(answer);

      _review.add(
        '${question.text}\n'
        'Your answer: $selectedAnswer\n'
        'Correct answer: ${question.correctAnswer}\n'
        'Result: ${isCorrect ? "Correct" : "Incorrect"}',
      );

      
    });
  }
  void _continueQuiz() {
    if (!_answeredCurrentQuestion || _question.isEmpty) {
      return;
    }
    setState(() {
      if (_currentQuestion ==
          _questions.length - 1) {
        _finished = true;
      } else {
        _currentQuestion++;
        _answeredCurrentQuestion = false;
        _currentAnswerCorrect = null;
        _selectedAnswer = null;
      }
    }
    
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              const SignInScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not sign out.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not sign out: $error',
          ),
        ),
      );
    }
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context)
              .colorScheme
              .error,
        ),
        const SizedBox(height: 16),
        Text(
          _error ?? 'An unknown error occurred.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loadQuestions,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildQuizView() {
    final question = _questions[_currentQuestion];

    final progress =
        (_currentQuestion + 1) / _questions.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Question ${_currentQuestion + 1}'
          '/${_questions.length}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              question.text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _answeredCurrentQuestion
                ? null
                : () {
                    _submitAnswer(true);
                  },
            child: const Text('True'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _answeredCurrentQuestion
                ? null
                : () {
                    _submitAnswer(false);
                  },
            child: const Text('False'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(
          Icons.science,
          size: 56,
        ),
        const SizedBox(height: 12),
        const Text(
          'Quiz Complete!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Score: $_score/${_questions.length}',
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Results Review',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _review.length,
            itemBuilder: (context, index) {
              final selectedAnswer =
                  _answers[index] ? 'True' : 'False';

              final answerWasCorrect =
                  selectedAnswer ==
                      _questions[index].correctAnswer;

              return Card(
                child: ListTile(
                  leading: Icon(
                    answerWasCorrect
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: answerWasCorrect
                        ? Colors.green
                        : Theme.of(context)
                            .colorScheme
                            .error,
                  ),
                  title: Text(
                    _review[index],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _loadQuestions,
          child: const Text('Play Again'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_loading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_error != null) {
      content = Center(
        child: _buildErrorView(),
      );
    } else if (_questions.isEmpty) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No questions are available.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadQuestions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_finished) {
      content = _buildResultsView();
    } else {
      content = Center(
        child: _buildQuizView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Science Signal',
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            tooltip: 'Sign out',
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }
}