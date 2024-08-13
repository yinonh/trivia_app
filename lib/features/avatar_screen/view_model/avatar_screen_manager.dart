import 'dart:io';
import 'dart:typed_data';
import 'package:custom_image_crop/custom_image_crop.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia/service/user_provider.dart';
import 'package:trivia/utility/constant_strings.dart';
import 'package:trivia/utility/fluttermoji/fluttermojiController.dart';

part 'avatar_screen_manager.freezed.dart';
part 'avatar_screen_manager.g.dart';

@freezed
class AvatarState with _$AvatarState {
  const factory AvatarState({
    required String userName,
    File? selectedImage,
    File? originalImage,
    required bool showTrashIcon,
    required CustomImageCropController cropController,
  }) = _AvatarState;
}

@riverpod
class AvatarScreenManager extends _$AvatarScreenManager {
  @override
  Future<AvatarState> build() async {
    final currentUser = ref.read(userProvider).currentUser;
    File? userImage = currentUser.userImage;
    final prefs = await SharedPreferences.getInstance();
    final originalImagePath = prefs.getString(Strings.originalUserImagePathKey);
    final originalImage =
        originalImagePath != null ? File(originalImagePath) : userImage;
    return AvatarState(
      userName: currentUser.name ?? "",
      showTrashIcon: false,
      selectedImage: userImage,
      originalImage: originalImage,
      cropController: CustomImageCropController(),
    );
  }

  void switchImage(XFile? image) {
    state.whenData((data) {
      state = AsyncValue.data(data.copyWith(
        originalImage: image != null ? File(image.path) : null,
        selectedImage: image != null ? File(image.path) : null,
      ));
    });
  }

  Future<File> convertMemoryImageToFile(
      MemoryImage memoryImage, String fileName) async {
    final Uint8List byteData = memoryImage.bytes;

    final Directory tempDir = await getApplicationDocumentsDirectory();
    final String tempPath = tempDir.path;

    final File file = File('$tempPath/$fileName');

    await file.writeAsBytes(byteData);

    return file;
  }

  Future<void> saveImage() async {
    state.whenData((data) async {
      final MemoryImage? croppedImage = await data.cropController.onCropImage();

      if (croppedImage != null) {
        String currentTime = DateTime.now().toString();
        final byteData = croppedImage.bytes;
        final buffer = byteData.buffer;

        final appDir = await getApplicationDocumentsDirectory();
        final imagePath = Strings.getCroppedImagePath(appDir.path, currentTime);
        final file = File(imagePath);
        await file.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

        // Now copy the file to the Application Documents Directory
        final originalImagePath =
            Strings.getOriginalImagePath(appDir.path, currentTime);
        await data.originalImage!.copy(originalImagePath);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            Strings.originalUserImagePathKey, originalImagePath);

        await ref.read(userProvider.notifier).setImage(file);
      } else {
        await ref.read(userProvider.notifier).setImage(null);
        state = AsyncValue.data(data.copyWith(showTrashIcon: false));
      }
    });
  }

  void toggleShowTrashIcon([bool? value]) {
    state.whenData((data) {
      state = AsyncValue.data(data.copyWith(
        showTrashIcon: value ?? !data.showTrashIcon,
      ));
    });
  }

  Future<void> saveAvatar() async {
    final fluttermojiController = Get.find<FluttermojiController>();
    await fluttermojiController.setFluttermoji();
    await ref.read(userProvider.notifier).setAvatar();
  }
}
