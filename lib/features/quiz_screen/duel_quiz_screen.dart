import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia/core/common_widgets/app_bar.dart';
import 'package:trivia/core/common_widgets/base_screen.dart';
import 'package:trivia/core/common_widgets/custom_when.dart';
import 'package:trivia/core/constants/app_constant.dart';
import 'package:trivia/core/constants/app_routes.dart';
import 'package:trivia/core/constants/constant_strings.dart';
import 'package:trivia/core/utils/enums/game_stage.dart';
import 'package:trivia/core/utils/size_config.dart';
import 'package:trivia/features/quiz_screen/view_model/duel_quiz_screen_manager.dart';
import 'package:trivia/features/quiz_screen/widgets/duel_widgets/duel_question_widget.dart';
import 'package:trivia/features/quiz_screen/widgets/duel_widgets/question_review.dart';
import 'package:trivia/features/quiz_screen/widgets/duel_widgets/waiting_or_countdown.dart';
import 'package:trivia/features/quiz_screen/widgets/question_shemmer.dart';
import 'package:trivia/features/results_screen/duel_result_screen.dart';
import 'package:trivia/features/results_screen/game_canceled.dart';

class DuelQuizScreen extends ConsumerWidget {
  static const routeName = AppRoutes.duelQuizRouteName;
  final String roomId;

  const DuelQuizScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsState = ref.watch(duelQuizScreenManagerProvider(roomId));

    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppConstant.primaryColor,
        appBar: CustomAppBar(
          actions: [
            // Score indicator
            questionsState.customWhen(
              data: (state) {
                final myScore = state.userScores[state.currentUser?.uid] ?? 0;
                return Padding(
                  padding: EdgeInsets.only(right: calcWidth(16)),
                  child: Chip(
                    label: Text(
                      "${Strings.score} $myScore",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppConstant.secondaryColor,
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35.0),
              topRight: Radius.circular(35.0),
            ),
          ),
          child: questionsState.customWhen(
            data: (state) {
              // If game is completed, navigate to results
              if (state.gameStage == GameStage.completed) {
                // Use post-frame callback to navigate after the build is complete
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  // Show loading indicator for 3 seconds
                  await Future.delayed(const Duration(seconds: 3));

                  // Navigate only if the widget is still mounted
                  if (context.mounted) {
                    context.goNamed(
                      DuelResultsScreen.routeName,
                      pathParameters: {'roomId': state.roomId!},
                    );
                  }
                });
                return const Center(child: CircularProgressIndicator());
              }

              // Handle canceled game state
              if (state.gameStage == GameStage.canceled) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  // Show loading indicator for 3 seconds
                  await Future.delayed(const Duration(seconds: 3));
                  // Navigate only if the widget is still mounted
                  if (context.mounted) {
                    context.goNamed(
                      GameCanceledScreen.routeName,
                      extra: {
                        'users': state.users,
                        'userScores': state.userScores,
                        'currentUserId': state.currentUser?.uid ?? '',
                        'opponentId': state.opponent?.uid ?? '',
                      },
                    );
                  }
                });
                return const Center(child: CircularProgressIndicator());
              }

              if (state.gameStage == GameStage.created) {
                return const WaitingOrCountdown();
              }

              // Show different widgets based on game stage
              if (state.gameStage == GameStage.questionReview) {
                return QuestionReviewWidget(
                  question: state.questions[state.questionIndex],
                  correctAnswer:
                      state.questions[state.questionIndex].correctAnswer!,
                  selectedAnswerIndex: state.selectedAnswerIndex,
                  correctAnswerIndex: state.correctAnswerIndex,
                  userScores: state.userScores,
                  users: state.users,
                  currentUser: state.currentUser,
                  opponent: state.opponent,
                );
              } else {
                return DuelQuestionWidget(
                  users: state.users,
                  userScores: state.userScores,
                  roomId: roomId,
                );
              }
            },
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppConstant.red),
                  SizedBox(height: calcHeight(16)),
                  Text(
                    "${Strings.error} ${error.toString()}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: calcHeight(24)),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text(Strings.back),
                  ),
                ],
              ),
            ),
            loading: () => const ShimmerLoadingQuestionWidget(),
          ),
        ),
      ),
    );
  }
}
