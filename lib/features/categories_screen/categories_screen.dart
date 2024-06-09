import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trivia/common_widgets/user_app_bar.dart';
import 'package:trivia/features/categories_screen/view_model/categories_screen_manager.dart';
import 'package:trivia/features/categories_screen/widgets/horizontal_list.dart';
import 'package:trivia/features/categories_screen/widgets/info_container.dart';
import 'package:trivia/features/categories_screen/widgets/section_header.dart';
import 'package:trivia/features/categories_screen/widgets/top_button.dart';

class CategoriesScreen extends ConsumerWidget {
  static const routeName = "/categories_screen";

  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesScreenManagerProvider);

    return Scaffold(
      appBar: const UserAppBar(),
      body: categoriesState.when(
        data: (data) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TopButton(
                      icon: Icons.add_rounded,
                      label: "Create Quiz",
                      color: Colors.blueAccent,
                      onTap: () {
                        // Handle create quiz tap
                      },
                    ),
                    TopButton(
                      icon: Icons.person_2,
                      label: "Solo Mode",
                      color: Colors.greenAccent,
                      onTap: () {
                        // Handle solo mode tap
                      },
                    ),
                    TopButton(
                      icon: Icons.groups_2,
                      label: "Multiplayer",
                      color: Colors.orangeAccent,
                      onTap: () {
                        // Handle multiplayer tap
                      },
                    ),
                  ],
                ),
              ),

              // Featured Categories
              SectionHeader(
                title: "Featured Categories",
                onTap: () {
                  // Navigate to full categories list screen
                },
              ),
              HorizontalList(
                categories: data.categories.triviaCategories?.take(4).toList(),
              ),

              // Recent Quiz
              SectionHeader(
                title: "Recent Quiz",
                onTap: () {
                  // Navigate to full recent quiz list screen
                },
              ),
              InfoContainer(text: "Recent Quiz Information"),

              // Personal Rooms
              SectionHeader(
                title: "Personal Rooms",
                onTap: () {
                  // Navigate to full personal rooms list screen
                },
              ),
              InfoContainer(text: "Personal Rooms Information"),
            ],
          ),
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final categoriesState = ref.watch(categoriesScreenManagerProvider);
//     final categoriesNotifier =
//         ref.read(categoriesScreenManagerProvider.notifier);
//     return Scaffold(
//       appBar: const UserAppBar(),
//       body: categoriesState.when(data: (data) {
//         return ListView.builder(
//             itemCount: data.categories.triviaCategories?.length,
//             itemBuilder: (context, index) {
//               return ListTile(
//                 title: Text(data.categories.triviaCategories![index].name!),
//                 trailing: const Icon(Icons.arrow_forward_ios_rounded),
//                 onTap: () {
//                   categoriesNotifier.setCategory(
//                       data.categories.triviaCategories![index].id!);
//                   categoriesNotifier.resetAchievements();
//                   Navigator.pushNamed(context, QuizScreen.routeName);
//                 },
//               );
//             });
//       }, error: (error, _) {
//         return Text(error.toString());
//       }, loading: () {
//         return const CircularProgressIndicator();
//       }),
//     );
//   }
// }
