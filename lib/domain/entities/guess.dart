// domain/entities/guess.dart
import 'package:equatable/equatable.dart';

class Guess extends Equatable {
  final String word;
  final double similarity;
  final DateTime timestamp;

  const Guess({
    required this.word,
    required this.similarity,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [word, similarity, timestamp];

  Guess copyWith({
    String? word,
    double? similarity,
    DateTime? timestamp,
  }) {
    return Guess(
      word: word ?? this.word,
      similarity: similarity ?? this.similarity,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Converte objeto para formato de armazenamento em JSON
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'similarity': similarity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Cria objeto a partir do formato JSON
  factory Guess.fromJson(Map<String, dynamic> json) {
    return Guess(
      word: json['word'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Cria a partir do formato de armazenamento string
  static Guess fromStorageString(String storage) {
    final parts = storage.split('|');
    return Guess(
      word: parts[0],
      similarity: double.parse(parts[1]),
      timestamp: parts.length > 2
          ? DateTime.parse(parts[2])
          : DateTime.now(),
    );
  }

  // Converte para formato de armazenamento string
  String toStorageString() =>
      '$word|$similarity|${timestamp.toIso8601String()}';
}
