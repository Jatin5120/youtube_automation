import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:frontend/data/data.dart';
import 'package:frontend/res/res.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' show Client;

void main() {
  initialize();
  runApp(const MyApp());
}

void initialize() {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ApiWrapper(Client()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Youtube Automation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      unknownRoute: AppPages.dashboard,
    );
  }
}
