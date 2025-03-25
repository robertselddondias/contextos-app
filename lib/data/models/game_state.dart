// data/models/game_state.dart
import 'dart:convert';

import 'package:contextual/domain/entities/guess.dart';

class GameStateModel {
  final String targetWord;
  final List<Guess> guesses;
  final bool isCompleted;
  final int bestScore;
  final String dailyWordId;
  final bool wasShared;

  GameStateModel({
    required this.targetWord,
    required this.guesses,
    required this.isCompleted,
    required this.bestScore,
    required this.dailyWordId,
    this.wasShared = false,
  });

  GameStateModel copyWith({
    String? targetWord,
    List<Guess>? guesses,
    bool? isCompleted,
    int? bestScore,
    String? dailyWordId,
    bool? wasShared,
  }) {
    return GameStateModel(
      targetWord: targetWord ?? this.targetWord,
      guesses: guesses ?? this.guesses,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      dailyWordId: dailyWordId ?? this.dailyWordId,
      wasShared: wasShared ?? this.wasShared,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetWord': targetWord,
      'guesses': guesses.map((g) => g.toJson()).toList(),
      'isCompleted': isCompleted,
      'bestScore': bestScore,
      'dailyWordId': dailyWordId,
      'wasShared': wasShared,
    };
  }

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    return GameStateModel(
      targetWord: json['targetWord'] as String,
      guesses: (json['guesses'] as List<dynamic>)
          .map((e) => Guess.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool,
      bestScore: json['bestScore'] as int,
      dailyWordId: json['dailyWordId'] as String,
      wasShared: json['wasShared'] as bool? ?? false,
    );
  }

  String toRawJson() => json.encode(toJson());

  factory GameStateModel.fromRawJson(String source) =>
      GameStateModel.fromJson(json.decode(source) as Map<String, dynamic>);
}
