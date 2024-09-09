import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trivia/service/user_provider.dart';
import 'package:trivia/utility/app_constant.dart';
import 'package:trivia/utility/color_utility.dart';
import 'package:trivia/utility/size_config.dart';

class UserAvatar extends ConsumerWidget {
  final double radius;

  const UserAvatar({this.radius = 42, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    if (userState.imageLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return userState.currentUser.userImage != null
        ? CircleAvatar(
            backgroundImage: FileImage(userState.currentUser.userImage!),
            radius: calcWidth(radius),
          )
        : userState.currentUser.avatar != null
            ? CircleAvatar(
                backgroundColor: AppConstant.userAvatarBackground.toColor(),
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
                backgroundColor: AppConstant.userAvatarBackground.toColor(),
                radius: calcWidth(radius),
              );
  }
}
