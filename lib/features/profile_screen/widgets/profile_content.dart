import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:trivia/core/common_widgets/stars.dart';
import 'package:trivia/core/constants/app_constant.dart';
import 'package:trivia/core/utils/size_config.dart';
import 'package:trivia/features/profile_screen/view_modle/profile_screen_manager.dart';
import 'package:trivia/features/profile_screen/widgets/edit_user_details.dart';
import 'package:trivia/features/profile_screen/widgets/user_details.dart';

class ProfileContent extends ConsumerWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileScreenManagerProvider);
    final profileNotifier = ref.read(profileScreenManagerProvider.notifier);

    ref.listen<ProfileState>(profileScreenManagerProvider, (previous, next) {
      if (next.firebaseErrorMessage != null) {
        final message = next.firebaseErrorMessage!;
        profileNotifier.deleteFirebaseMessage();
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.info(
            message: message,
            backgroundColor: AppConstant.onPrimaryColor,
            icon: Icon(
              Icons.warning_rounded,
              color: Colors.black.withOpacity(0.2),
              size: 120,
            ),
          ),
          snackBarPosition: SnackBarPosition.bottom,
          padding: EdgeInsets.symmetric(
            horizontal: calcWidth(20),
            vertical: calcHeight(80),
          ),
          displayDuration: const Duration(seconds: 1, milliseconds: 500),
        );
      }
    });

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 60, left: 10, right: 10),
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(35.0),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: calcWidth(20),
                  right: calcWidth(20),
                  top: calcHeight(100),
                ),
                child: const SizedBox(height: 5),
              ),
              Container(
                width: calcWidth(150),
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppConstant.onPrimaryColor,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: const UserStars(),
              ),
              SizedBox(height: calcHeight(16)),
              profileState.isEditing
                  ? const EditUserDetails()
                  : const UserDetails()
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(
                profileState.isEditing
                    ? Icons.edit_off_rounded
                    : Icons.edit_rounded,
                color: AppConstant.primaryColor,
              ),
              onPressed: profileNotifier.toggleIsEditing,
            ),
          )
        ],
      ),
    );
  }
}
