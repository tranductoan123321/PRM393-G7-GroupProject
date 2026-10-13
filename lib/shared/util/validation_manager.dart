import 'package:efashion_flutter/shared/util/strings_manager.dart';
import 'package:flutter/cupertino.dart';

class ValidationManager {
  static basicValidator({required String? label}) {
    return (value) {
      // Sửa: Kiểm tra null an toàn thay vì dùng value!
      if (value == null || value.trim().isEmpty) {
        return '$label ${StringsManager.textIsRequired}';
      } else if (value.trim().length < 8) {
        return '$label ${StringsManager.textIsTooShort}';
      }
      return null;
    };
  }

  static phoneNumberValidator({required TextEditingController phoneController,}){
    final phoneNumberRegex = RegExp(r'^\d{10}$');
    return  (value) {
      // Thêm .trim() để loại bỏ khoảng trắng thừa
      if (!phoneNumberRegex.hasMatch((value ?? '').trim())) {
        return StringsManager.phoneNumberValidationMessage;
      } else {
        return null;
      }
    };
  }

  static emailValidator() {
    return (value) {
      final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
      // Sửa: Đã thêm .trim() vào đây để fix lỗi ở ảnh trước
      if (!emailRegex.hasMatch((value ?? '').trim())) {
        return StringsManager.emailValidationMessage;
      }
      return null;
    };
  }

  static changePasswordValidator({
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
  }) {
    return (value) {
      final lowercaseRegex = RegExp(r'[a-z]');
      final uppercaseRegex = RegExp(r'[A-Z]');
      final digitRegex = RegExp(r'[0-9]');
      if (value == null || value.isEmpty) {
        return StringsManager.passwordIsRequiredMessage;
      } else if (passwordController.text != confirmPasswordController.text &&
          confirmPasswordController.text.isNotEmpty) {
        return StringsManager.passwordNoMatch;
      } else if (value.length < 8) {
        return StringsManager.passwordTooShort;
      } else if (!lowercaseRegex.hasMatch(value)) {
        return StringsManager.passwordMustHaveLowerCaseLetter;
      } else if (!uppercaseRegex.hasMatch(value)) {
        return StringsManager.passwordMustHaveUpperCaseLetter;
      } else if (!digitRegex.hasMatch(value)) {
        return StringsManager.passwordMustHaveOneDigit;
      } else {
        return null;
      }
    };
  }

  static passwordValidator({
    required TextEditingController passwordController,
  }) {
    return (value) {
      final lowercaseRegex = RegExp(r'[a-z]');
      final uppercaseRegex = RegExp(r'[A-Z]');
      final digitRegex = RegExp(r'[0-9]');
      if (value == null || value.isEmpty) {
        return StringsManager.passwordIsRequiredMessage;
      } else if (value.length < 8) {
        return StringsManager.passwordTooShort;
      } else if (!lowercaseRegex.hasMatch(value)) {
        return StringsManager.passwordMustHaveLowerCaseLetter;
      } else if (!uppercaseRegex.hasMatch(value)) {
        return StringsManager.passwordMustHaveUpperCaseLetter;
      } else if (!digitRegex.hasMatch(value)) {
        return StringsManager.passwordMustHaveOneDigit;
      } else {
        return null;
      }
    };
  }

  static reviewValidator(){
    return (value) {
      // Sửa: Kiểm tra null an toàn thay vì dùng value!
      if(value == null || value.trim().length < 20){
        return StringsManager.reviewValidationMessage;
      }else{
        return null;
      }
    };
  }
}