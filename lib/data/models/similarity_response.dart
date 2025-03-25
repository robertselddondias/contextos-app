// data/models/similarity_response.dart
import 'dart:convert';

class SimilarityResponse {
  final double similarity;
  final String word1;
  final String word2;
  final Map<String, dynamic>? metadata;

  SimilarityResponse({
    required this.similarity,
    required this.word1,
    required this.word2,
    this.metadata,
  });

  factory SimilarityResponse.fromRawJson(String str) =>
      SimilarityResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SimilarityResponse.fromJson(Map<String, dynamic> json) =>
      SimilarityResponse(
        similarity: json["similarity"]?.toDouble() ?? 0.0,
        word1: json["word1"] ?? "",
        word2: json["word2"] ?? "",
        metadata: json["metadata"],
      );

  Map<String, dynamic> toJson() => {
    "similarity": similarity,
    "word1": word1,
    "word2": word2,
    "metadata": metadata,
  };
}
