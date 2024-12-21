import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';
part 'question.g.dart';

@freezed
class Question with _$Question {
  const factory Question({
    @JsonKey(name: "type") Type? type,
    @JsonKey(name: "difficulty") Difficulty? difficulty,
    @JsonKey(name: "category") String? category,
    @JsonKey(name: "question") String? question,
    @JsonKey(name: "correct_answer") String? correctAnswer,
    @JsonKey(name: "incorrect_answers") List<String>? incorrectAnswers,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}

enum Difficulty {
  @JsonValue("easy")
  EASY,
  @JsonValue("hard")
  HARD,
  @JsonValue("medium")
  MEDIUM
}

enum Type {
  @JsonValue("boolean")
  BOOLEAN,
  @JsonValue("multiple")
  MULTIPLE
}