import 'package:flutter/material.dart';
import 'package:frontend/data/data.dart';
import 'package:frontend/res/res.dart';
import 'package:get/get.dart';

class StrictAuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (DBWrapper.i.getValue<bool>(AppKeys.isLoggedIn) ?? false) {
      return null;
    }
    return const RouteSettings(name: AppRoutes.auth);
  }
}
