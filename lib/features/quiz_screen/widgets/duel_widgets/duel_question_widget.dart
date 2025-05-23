import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia/core/common_widgets/custom_when.dart';
import 'package:trivia/core/constants/app_constant.dart';
import 'package:trivia/core/utils/enums/game_stage.dart';
import 'package:trivia/core/utils/size_config.dart';
import 'package:trivia/features/quiz_screen/view_model/duel_quiz_screen_manager.dart';
import 'package:trivia/features/quiz_screen/widgets/duel_widgets/duel_multiple_answer_widget.dart';
import 'package:trivia/features/quiz_screen/widgets/duel_widgets/user_score_bar.dart';
import 'package:trivia/features/quiz_screen/widgets/question_shemmer.dart';

class DuelQuestionWidget extends ConsumerWidget {
  final List<String> users;
  final Map<String, int> userScores;
  final String roomId;

  const DuelQuestionWidget(
      {super.key,
      required this.users,
      required this.userScores,
      required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsState = ref.watch(duelQuizScreenManagerProvider(roomId));

    return questionsState.customWhen(
      data: (data) {
        if (data.questions.length <= data.questionIndex) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentQuestion = data.questions[data.questionIndex];

        return Column(
          children: [
            // User Scores - now with user data
            UserScoreBar(
              users: users,
              userScores: userScores,
              opponent: data.opponent,
              currentUser: data.currentUser,
            ),

            SizedBox(height: calcHeight(10)),

            // Question and Answers
            Expanded(
              child: DuelMultipleAnswerWidget(
                question: currentQuestion.question!,
                options: data.shuffledOptions,
                onAnswerSelected: (index) {
                  // Only allow selection if not already selected and game is active
                  if (data.selectedAnswerIndex == null &&
                      data.gameStage == GameStage.active) {
                    // Ensure this is correct
                    ref
                        .read(duelQuizScreenManagerProvider(roomId).notifier)
                        .selectAnswer(index);
                  }
                },
                questionIndex: data.questionIndex,
                selectedAnswerIndex: data.selectedAnswerIndex,
                correctAnswerIndex: data.correctAnswerIndex,
                userAnswers: data.userAnswers,
                gameStage: data.gameStage,
                users: users,
              ),
            ),

            // Timer Bar
            SizedBox(height: calcHeight(10)),
            data.selectedAnswerIndex == null
                ? LinearProgressIndicator(
                    value: data.timeLeft / AppConstant.questionTime,
                    minHeight: calcHeight(10),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    color: data.timeLeft / AppConstant.questionTime < 0.2
                        ? AppConstant.red
                        : data.timeLeft / AppConstant.questionTime < 0.5
                            ? AppConstant.amber
                            : AppConstant.onPrimaryColor,
                  )
                : LinearProgressIndicator(
                    value: 1.0,
                    minHeight: calcHeight(10),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    color: AppConstant.onPrimaryColor,
                  ),
            SizedBox(height: calcHeight(20)),
          ],
        );
      },
      loading: () {
        return const ShimmerLoadingQuestionWidget();
      },
    );
  }
}
