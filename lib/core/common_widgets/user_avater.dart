import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trivia/core/utils/size_config.dart';
import 'package:trivia/core/constants/app_constant.dart';
import 'package:trivia/data/service/user_provider.dart';

class UserAvatar extends ConsumerWidget {
  final double radius;
  final bool showProgress;

  const UserAvatar({this.radius = 42, this.showProgress = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    if (userState.imageLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        if (showProgress)
          SizedBox(
            width: calcWidth(radius * 2.1),
            height: calcWidth(radius * 2.1),
            child: CircularProgressIndicator(
              strokeWidth: 6.0,
              value: userState.currentUser.userXp / 100,
              color: AppConstant.onPrimary,
            ),
          ),
        userState.currentUser.userImage != null
            ? CircleAvatar(
                backgroundImage: FileImage(userState.currentUser.userImage!),
                radius: calcWidth(radius),
              )
            : userState.currentUser.avatar != null
                ? CircleAvatar(
                    backgroundColor: AppConstant.userAvatarBackground,
                    radius: calcWidth(radius),
                    child: ClipOval(
                      child: SvgPicture.string(
                        userState.currentUser.avatar!,
                        fit: BoxFit.cover,
                        height: calcWidth(radius * 2),
                        width: calcWidth(radius * 2),
                      ),
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: AppConstant.userAvatarBackground,
                    radius: calcWidth(radius),
                  ),
      ],
    );
  }
}
