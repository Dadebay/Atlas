import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class NavigationService {
  static Widget Function()? _loginBuilder;

  static void setLoginBuilder(Widget Function() builder) {
    _loginBuilder = builder;
  }

  static void goToLogin() {
    if (_loginBuilder != null) Get.to(_loginBuilder!, routeName: '/auth/phone');
  }
}
