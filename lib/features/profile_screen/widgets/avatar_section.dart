import 'package:flutter/material.dart';
import 'package:trivia/core/common_widgets/user_avater.dart';
import 'package:trivia/core/utils/size_config.dart';
import 'package:trivia/features/avatar_screen/avatar_screen.dart';
import 'package:trivia/core/constants/app_constant.dart';

class AvatarSection extends StatelessWidget {
  const AvatarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: calcHeight(-10),
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: calcHeight(25)),
        child: Container(
          width: calcWidth(155),
          height: calcWidth(155),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: calcWidth(145),
                  height: calcWidth(145),
                  child: const CircularProgressIndicator(
                    strokeWidth: 8.0,
                    value: 0.8,
                    color: AppConstant.onPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AvatarScreen.routeName);
                  },
                  child: const UserAvatar(
                    radius: 70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
