import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trivia/core/utils/timestamp_converter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'trivia_user.freezed.dart';
part 'trivia_user.g.dart';

String? fileToJson(File? file) {
  return file?.path;
}

File? fileFromJson(String? path) {
  return path != null ? File(path) : null;
}

@freezed
class TriviaUser with _$TriviaUser {
  @Assert('uid != null', 'uid cannot be null when used as a map key')
  const factory TriviaUser({
    required String uid,
    String? name,
    String? email,
    @JsonKey(name: "userImage") String? imageUrl,
    @TimestampConverter() DateTime? lastLogin,
    required List<int> recentTriviaCategories,
    required double userXp,
    Map<String, dynamic>? fluttermojiOptions,
    @Default(0) int coins,
  }) = _TriviaUser;

  const TriviaUser._();

  factory TriviaUser.fromJson(Map<String, dynamic> json) =>
      _$TriviaUserFromJson(json);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TriviaUser && uid != "" && other.uid == uid);
  }

  @override
  int get hashCode => uid.hashCode;
}
