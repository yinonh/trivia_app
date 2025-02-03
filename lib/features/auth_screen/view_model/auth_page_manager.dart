import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:trivia/core/common_widgets/base_screen.dart';
import 'package:trivia/core/utils/map_firebase_errors_to_message.dart';
import 'package:trivia/data/data_source/user_statistics_data_source.dart';
import 'package:trivia/data/providers/user_provider.dart';
import 'package:trivia/core/constants/constant_strings.dart';

part 'auth_page_manager.freezed.dart';
part 'auth_page_manager.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    required bool isLogin,
    required bool showPassword,
    required bool showConfirmPassword,
    required String email,
    required String password,
    required String confirmPassword,
    required String emailErrorMessage,
    required String passwordErrorMessage,
    required String confirmPasswordErrorMessage,
    String? firebaseErrorMessage,
    required bool navigate,
    required bool isNewUser,
    required GlobalKey<FormState> formKey,
  }) = _AuthState;
}

@riverpod
class AuthScreenManager extends _$AuthScreenManager {
  final _formKey = GlobalKey<FormState>();

  @override
  AuthState build() {
    return AuthState(
      isLogin: true,
      showPassword: false,
      showConfirmPassword: false,
      email: '',
      password: '',
      confirmPassword: '',
      emailErrorMessage: '',
      passwordErrorMessage: '',
      confirmPasswordErrorMessage: '',
      navigate: false,
      isNewUser: false,
      formKey: _formKey,
    );
  }

  void toggleFormMode() {
    ref.read(loadingProvider.notifier).state = false;
    state = state.copyWith(
      isLogin: !state.isLogin,
      showPassword: false,
      showConfirmPassword: false,
      email: '',
      password: '',
      confirmPassword: '',
      emailErrorMessage: '',
      passwordErrorMessage: '',
      confirmPasswordErrorMessage: '',
      firebaseErrorMessage: null,
      navigate: false,
      isNewUser: !state.isLogin,
      formKey: GlobalKey<FormState>(),
    );
  }

  void toggleShowPassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void toggleShowConfirmPassword() {
    state = state.copyWith(showConfirmPassword: !state.showConfirmPassword);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  void setConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword);
  }

  void deleteFirebaseMessage() {
    state = state.copyWith(firebaseErrorMessage: null);
  }

  void resetNavigate() {
    state = state.copyWith(navigate: false);
  }

  Future<void> submit() async {
    String emailError = '';
    String passwordError = '';
    String confirmPasswordError = '';

    if (!EmailValidator.validate(state.email)) {
      emailError = Strings.invalidEmail;
    }
    if (state.password.length < 6) {
      passwordError = Strings.passwordTooShort;
    }
    if (!state.isLogin && state.password != state.confirmPassword) {
      confirmPasswordError = Strings.passwordsNotMatch;
    }

    if (emailError.isNotEmpty ||
        passwordError.isNotEmpty ||
        confirmPasswordError.isNotEmpty) {
      state = state.copyWith(
        emailErrorMessage: emailError,
        passwordErrorMessage: passwordError,
        confirmPasswordErrorMessage: confirmPasswordError,
      );
      return;
    }

    ref.read(loadingProvider.notifier).state = true;
    state = state.copyWith(
        emailErrorMessage: '',
        passwordErrorMessage: '',
        confirmPasswordErrorMessage: '');

    try {
      if (state.isLogin) {
        await ref
            .read(authProvider.notifier)
            .signIn(state.email, state.password);
        state = state.copyWith(navigate: true, isNewUser: false);
      } else {
        final userCredential = await ref
            .read(authProvider.notifier)
            .createUser(state.email, state.password);
        final newUserUid = userCredential.user!.uid;
        await UserStatisticsDataSource.createUserStatistics(newUserUid);
        state = state.copyWith(navigate: true, isNewUser: true);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
          firebaseErrorMessage: mapFirebaseErrorCodeToMessage(e));
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final additionalUserInfo =
          await ref.read(authProvider.notifier).signInWithGoogle();
      state = state.copyWith(
          navigate: true, isNewUser: additionalUserInfo?.isNewUser ?? true);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
          firebaseErrorMessage: mapFirebaseErrorCodeToMessage(e));
    }
  }
}
