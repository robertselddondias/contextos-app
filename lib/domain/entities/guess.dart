import 'package:equatable/equatable.dart';

class Guess extends Equatable {
  final String word;
  final double similarity;
  final DateTime timestamp;
  final bool isHint;

  const Guess({
    required this.word,
    required this.similarity,
    required this.timestamp,
    this.isHint = false, // Valor padrão
  });

  @override
  List<Object?> get props => [word, similarity, timestamp, isHint];

  Guess copyWith({
    String? word,
    double? similarity,
    DateTime? timestamp,
    bool? isHint,
  }) {
    return Guess(
      word: word ?? this.word,
      similarity: similarity ?? this.similarity,
      timestamp: timestamp ?? this.timestamp,
      isHint: isHint ?? this.isHint,
    );
  }

  // Atualiza métodos de serialização
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'similarity': similarity,
      'timestamp': timestamp.toIso8601String(),
      'isHint': isHint,
    };
  }

  factory Guess.fromJson(Map<String, dynamic> json) {
    return Guess(
      word: json['word'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isHint: json['isHint'] as bool? ?? false,
    );
  }
}
