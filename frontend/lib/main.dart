import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:frontend/data/data.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' show Client;

late String kApiKey;
Rx<Variant> _kVariant = Variant.variant1.obs;
Variant get kVariant => _kVariant.value;
set kVariant(Variant value) {
  if (kVariant == value) {
    return;
  }
  _kVariant.value = value;
}

var _apiKeys = <Variant, String>{};

void _fetchKeys() {
  _apiKeys = {
    Variant.development: const String.fromEnvironment('API_KEY', defaultValue: ''),
    Variant.variant1: const String.fromEnvironment('API_KEY_VARIANT1', defaultValue: ''),
    Variant.variant2: const String.fromEnvironment('API_KEY_VARIANT2', defaultValue: ''),
    Variant.variant3: const String.fromEnvironment('API_KEY_VARIANT3', defaultValue: ''),
    Variant.variant4: const String.fromEnvironment('API_KEY_VARIANT4', defaultValue: ''),
    Variant.variant5: const String.fromEnvironment('API_KEY_VARIANT5', defaultValue: ''),
    Variant.variant6: const String.fromEnvironment('API_KEY_VARIANT6', defaultValue: ''),
    Variant.variant7: const String.fromEnvironment('API_KEY_VARIANT7', defaultValue: ''),
    Variant.variant8: const String.fromEnvironment('API_KEY_VARIANT8', defaultValue: ''),
    Variant.variant9: const String.fromEnvironment('API_KEY_VARIANT9', defaultValue: ''),
  };
}

void setGeminiApiKey() {
  kApiKey = _apiKeys[kVariant]!;
}

void start(Variant variant) async {
  kVariant = variant;
  await initialize();
  runApp(const MyApp());
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}

Future<void> initialize() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  _fetchKeys();
  setGeminiApiKey();
  Get.put(ApiWrapper(Client()));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Trisdel Media',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      unknownRoute: AppPages.auth,
    );
  }
}
