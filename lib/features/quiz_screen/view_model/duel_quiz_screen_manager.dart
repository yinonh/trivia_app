import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:trivia/core/utils/enums/game_stage.dart';
import 'package:trivia/data/data_source/trivia_room_data_source.dart';
import 'package:trivia/data/data_source/user_data_source.dart';
import 'package:trivia/data/models/question.dart';
import 'package:trivia/data/models/shuffled_data.dart';
import 'package:trivia/data/models/trivia_achievements.dart';
import 'package:trivia/data/models/trivia_user.dart';
import 'package:trivia/data/providers/current_trivia_achievements_provider.dart';
import 'package:trivia/data/providers/duel_trivia_provider.dart';
import 'package:trivia/data/providers/user_provider.dart';

part 'duel_quiz_screen_manager.freezed.dart';
part 'duel_quiz_screen_manager.g.dart';

@freezed
class DuelQuizState with _$DuelQuizState {
  const factory DuelQuizState({
    required List<Question> questions,
    required double timeLeft,
    required int questionIndex,
    required List<String> shuffledOptions,
    required int correctAnswerIndex,
    required String categoryName,
    @GameStageConverter() required GameStage gameStage,
    required List<int> userScores,
    required List<String> users,
    required TriviaUser? opponent,
    required TriviaUser? currentUser,
    int? selectedAnswerIndex,
    String? roomId,
    @Default({}) Map<String, Map<int, int>> userAnswers,
    @Default(false) bool isHost,
  }) = _DuelQuizState;
}

@riverpod
class DuelQuizScreenManager extends _$DuelQuizScreenManager {
  Timer? _timer;
  Timer? _lastSeenTimer;
  Timer? _checkPresenceTimer;
  StreamSubscription? _roomSubscription;
  String? _currentUserId;
  bool _isUpdatingTimestamp = false;

  String? getCurrentUserId() => _currentUserId;

  @override
  Future<DuelQuizState> build() async {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final triviaNotifier = ref.read(duelTriviaProvider.notifier);
    final response = await triviaNotifier.getTriviaQuestions();
    final room = ref.read(duelTriviaProvider).triviaRoom;
    final opponentID =
        room?.users[0] == _currentUserId ? room?.users[1] : room?.users[0];
    final opponent = await UserDataSource.getUserById(opponentID);
    final currentUser = ref.read(authProvider).currentUser;

    if (room == null || room.roomId == null) {
      throw Exception("Room not initialized correctly");
    }

    // Set up room subscription
    _setupRoomSubscription(room.roomId!);

    // Start updating lastSeen
    _startLastSeenUpdates(room.roomId!, room.currentStage);

    // Start checking for user presence if host
    if (_currentUserId == room.hostUserId) {
      _startPresenceChecking(room.roomId!, room.users);
    }

    final initialShuffledData = _getShuffledOptions(response![0]);

    ref.onDispose(() {
      _timer?.cancel();
      _lastSeenTimer?.cancel();
      _checkPresenceTimer?.cancel();
      _roomSubscription?.cancel();
    });

    return DuelQuizState(
      questions: response,
      timeLeft: room.questionDuration.toDouble(),
      questionIndex: room.currentQuestionIndex,
      shuffledOptions: initialShuffledData.options,
      correctAnswerIndex: initialShuffledData.correctIndex,
      selectedAnswerIndex: null,
      categoryName: room.categoryId.toString(),
      gameStage: room.currentStage,
      userScores: room.userScores ?? [],
      users: room.users,
      opponent: opponent,
      currentUser: currentUser,
      roomId: room.roomId,
      isHost: _currentUserId == room.hostUserId,
    );
  }

  void _startLastSeenUpdates(String roomId, GameStage stage) {
    // Update lastSeen immediately regardless of stage
    if (_currentUserId != null) {
      TriviaRoomDataSource.updateLastSeen(roomId, _currentUserId!);
    }

    // Set up timer to update lastSeen every 3 seconds ONLY if not in created stage
    if (stage != GameStage.created) {
      _lastSeenTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) {
          if (_currentUserId != null) {
            TriviaRoomDataSource.updateLastSeen(roomId, _currentUserId!);
          }
        },
      );
    }
  }

  void _startPresenceChecking(String roomId, List<String> users) {
    // Only the host checks for user presence
    if (_currentUserId == null || users.isEmpty) return;

    _checkPresenceTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        state.whenData(
          (quizState) async {
            // Only check during created stage or active stage
            if (quizState.gameStage == GameStage.created ||
                quizState.gameStage == GameStage.active) {
              if (quizState.gameStage == GameStage.active) {
                // During active game, check if any user is absent
                final hasAbsentUser =
                    await TriviaRoomDataSource.checkForAbsentUser(
                        roomId, quizState.users);

                if (hasAbsentUser) {
                  // If a user is absent, end the game
                  TriviaRoomDataSource.endGame(quizState.roomId ?? "");
                }
              } else if (quizState.gameStage == GameStage.created) {
                // During created stage, check if both users are present
                final allPresent = await TriviaRoomDataSource.checkUserPresence(
                    roomId, quizState.users);

                if (allPresent && quizState.isHost) {
                  // Both users are present, start a 5 second countdown, then start the game
                  startGame();

                  // Cancel this timer so we don't keep checking
                  _checkPresenceTimer?.cancel();
                }
              }
            }
          },
        );
      },
    );
  }

  Future<void> startGame() async {
    state.whenData((quizState) async {
      if (quizState.isHost &&
          quizState.roomId != null &&
          quizState.gameStage == GameStage.created) {
        await TriviaRoomDataSource.startGame(quizState.roomId!);
      }
    });
  }

  void _setupRoomSubscription(String roomId) {
    _roomSubscription =
        TriviaRoomDataSource.getRoomStream(roomId).listen((updatedRoom) {
      if (updatedRoom == null) return;

      state.whenData((quizState) {
        // If game stage changed from created to something else, start the lastSeen updates
        if (quizState.gameStage == GameStage.created &&
            updatedRoom.currentStage != GameStage.created) {
          // Cancel any existing timer first
          _lastSeenTimer?.cancel();

          // Start regular lastSeen updates
          _lastSeenTimer = Timer.periodic(
            const Duration(seconds: 3),
            (_) {
              if (_currentUserId != null) {
                TriviaRoomDataSource.updateLastSeen(roomId, _currentUserId!);
              }
            },
          );
        }

        // Calculate time left based on server timestamp
        double calculatedTimeLeft = updatedRoom.questionDuration.toDouble();

        if (updatedRoom.currentStage == GameStage.active) {
          if (updatedRoom.currentQuestionStartTime != null) {
            final now = DateTime.now();
            final elapsedSeconds =
                now.difference(updatedRoom.currentQuestionStartTime!).inSeconds;
            calculatedTimeLeft =
                (updatedRoom.questionDuration - elapsedSeconds).toDouble();
            if (calculatedTimeLeft < 0) calculatedTimeLeft = 0;
          } else {
            // If somehow the timestamp wasn't set, update it now
            if (quizState.isHost &&
                !_isUpdatingTimestamp &&
                updatedRoom.currentStage == GameStage.active) {
              _isUpdatingTimestamp = true;
              TriviaRoomDataSource.updateQuestionStartTime(roomId).then((_) {
                _isUpdatingTimestamp = false;
              }).catchError((error) {
                _isUpdatingTimestamp = false;
              });
            }
          }
        }

        // Get the room snapshot from Firestore (assuming we have it from stream)
        final roomDoc = updatedRoom.toJson();
        final userAnswers = TriviaRoomDataSource.parseUserAnswers(roomDoc);

        // If question index changed, get new shuffled options
        ShuffledData? shuffledData;
        if (updatedRoom.currentQuestionIndex != quizState.questionIndex) {
          if (updatedRoom.currentQuestionIndex < quizState.questions.length) {
            shuffledData = _getShuffledOptions(
                quizState.questions[updatedRoom.currentQuestionIndex]);
          }
        }

        // Determine selected answer index from user answers
        int? selectedAnswerIndex = quizState.selectedAnswerIndex;
        if (_currentUserId != null &&
            userAnswers.containsKey(_currentUserId) &&
            userAnswers[_currentUserId]!
                .containsKey(updatedRoom.currentQuestionIndex)) {
          selectedAnswerIndex =
              userAnswers[_currentUserId]![updatedRoom.currentQuestionIndex];
        } else if (updatedRoom.currentQuestionIndex !=
            quizState.questionIndex) {
          // Reset selected answer when moving to new question
          selectedAnswerIndex = null;
        }

        // Update state with new room data
        state = AsyncValue.data(
          quizState.copyWith(
            questionIndex: updatedRoom.currentQuestionIndex,
            gameStage: updatedRoom.currentStage,
            userScores: updatedRoom.userScores ?? quizState.userScores,
            users: updatedRoom.users,
            timeLeft: calculatedTimeLeft,
            shuffledOptions: shuffledData?.options ?? quizState.shuffledOptions,
            correctAnswerIndex:
                shuffledData?.correctIndex ?? quizState.correctAnswerIndex,
            selectedAnswerIndex: selectedAnswerIndex,
            userAnswers: userAnswers,
          ),
        );

        // Manage timer based on game stage
        _manageTimerBasedOnGameStage(updatedRoom.currentStage);
      });
    });
  }

  void _manageTimerBasedOnGameStage(GameStage stage) {
    // Cancel existing timer
    _timer?.cancel();

    if (stage == GameStage.active) {
      // Start question timer
      _timer = Timer.periodic(
        const Duration(milliseconds: 40),
        (timer) {
          state.whenData(
            (quizState) {
              if (quizState.timeLeft > 0) {
                state = AsyncValue.data(
                    quizState.copyWith(timeLeft: quizState.timeLeft - 0.04));
              } else {
                if (quizState.selectedAnswerIndex == null) {
                  selectAnswer(-1);
                }
              }
            },
          );
        },
      );
    }
  }

  // Update user's answer in Firestore
  void selectAnswer(int index) {
    state.whenData(
      (quizState) async {
        if (quizState.selectedAnswerIndex == null &&
            quizState.roomId != null &&
            _currentUserId != null &&
            quizState.gameStage == GameStage.active) {
          // Only allow during active stage
          // First update local state
          state =
              AsyncValue.data(quizState.copyWith(selectedAnswerIndex: index));

          // Record achievements locally
          if (quizState.correctAnswerIndex == index) {
            ref
                .read(currentTriviaAchievementsProvider.notifier)
                .updateAchievements(
                    field: AchievementField.correctAnswers,
                    sumResponseTime: quizState.timeLeft);

            // Update user score in Firestore
            await TriviaRoomDataSource.updateUserScore(quizState.roomId!,
                _currentUserId!, quizState.questionIndex, quizState.timeLeft);
          } else if (index == -1) {
            ref
                .read(currentTriviaAchievementsProvider.notifier)
                .updateAchievements(field: AchievementField.unanswered);

            // Update missed questions in Firestore
            await TriviaRoomDataSource.updateMissedQuestions(
                quizState.roomId!, _currentUserId!);
          } else {
            ref
                .read(currentTriviaAchievementsProvider.notifier)
                .updateAchievements(
                    field: AchievementField.wrongAnswers,
                    sumResponseTime: quizState.timeLeft);
          }

          // Store user's answer in Firestore
          await TriviaRoomDataSource.storeUserAnswer(quizState.roomId!,
              _currentUserId!, quizState.questionIndex, index);

          await _checkAllUsersAnswered(quizState);
        }
      },
    );
  }

  Future<void> _checkAllUsersAnswered(DuelQuizState quizState) async {
    if (quizState.roomId == null) return;

    // Check if all users have answered
    final allUsersAnswered = await TriviaRoomDataSource.checkAllUsersAnswered(
        quizState.roomId!, quizState.users, quizState.questionIndex);

    if (allUsersAnswered) {
      // Move to review stage
      await TriviaRoomDataSource.moveToReviewStage(quizState.roomId!);

      // Schedule next question after 3 seconds
      Timer(
        const Duration(seconds: 3),
        () async {
          // Get latest room data
          final updatedRoom =
              await TriviaRoomDataSource.getRoomById(quizState.roomId!);
          if (updatedRoom == null) return;

          // Only proceed if we're still in the review stage
          if (updatedRoom.currentStage == GameStage.questionReview) {
            await TriviaRoomDataSource.moveToNextQuestion(quizState.roomId!,
                quizState.questionIndex, quizState.questions.length);
          }
        },
      );
    }
  }

  ShuffledData _getShuffledOptions(Question question) {
    final options = [...question.incorrectAnswers!, question.correctAnswer!];
    options.shuffle();
    final shuffledCorrectIndex = options.indexOf(question.correctAnswer!);
    return ShuffledData(options: options, correctIndex: shuffledCorrectIndex);
  }
}
