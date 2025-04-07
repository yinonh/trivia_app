import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia/core/common_widgets/app_bar.dart';
import 'package:trivia/core/common_widgets/base_screen.dart';
import 'package:trivia/core/constants/app_constant.dart';
import 'package:trivia/core/constants/constant_strings.dart';
import 'package:trivia/core/utils/general_functions.dart';
import 'package:trivia/features/quiz_screen/view_model/solo_quiz_screen_manager.dart';
import 'package:trivia/features/quiz_screen/widgets/question_shemmer.dart';
import 'package:trivia/features/quiz_screen/widgets/solo_widgets/solo_question_widget.dart';

class SoloQuizScreen extends ConsumerWidget {
  static const routeName = Strings.soloQuizRouteName;

  const SoloQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsState = ref.watch(soloQuizScreenManagerProvider);

    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppConstant.primaryColor,
        appBar: CustomAppBar(
          title: questionsState.when(
            data: (state) => cleanCategoryName(state.categoryName),
            error: (error, _) => "",
            loading: () => "",
          ),
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
          child: questionsState.when(
            data: (data) => SoloQuestionWidget(),
            error: (error, _) => Text(error.toString()),
            loading: () => const ShimmerLoadingQuestionWidget(),
          ),
        ),
      ),
    );
  }
}
