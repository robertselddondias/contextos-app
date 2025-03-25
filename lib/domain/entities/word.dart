// domain/entities/word.dart
import 'package:equatable/equatable.dart';

class Word extends Equatable {
  final String text;
  final String? category;
  final int frequency;
  final List<String> relatedWords;

  const Word({
    required this.text,
    this.category,
    this.frequency = 0,
    this.relatedWords = const [],
  });

  @override
  List<Object?> get props => [text, category, frequency, relatedWords];

  Word copyWith({
    String? text,
    String? category,
    int? frequency,
    List<String>? relatedWords,
  }) {
    return Word(
      text: text ?? this.text,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      relatedWords: relatedWords ?? this.relatedWords,
    );
  }

  // Converte objeto para formato de armazenamento em JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'category': category,
      'frequency': frequency,
      'relatedWords': relatedWords,
    };
  }

  // Cria objeto a partir do formato JSON
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      text: json['text'] as String,
      category: json['category'] as String?,
      frequency: json['frequency'] as int? ?? 0,
      relatedWords: (json['relatedWords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? const [],
    );
  }
}
