import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class Utility {
  const Utility._();

  static void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  static void updateLater(VoidCallback callback, [bool addDelay = true]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(addDelay ? const Duration(milliseconds: 10) : Duration.zero, () {
        callback();
      });
    });
  }

  static void launchURL(
    String url, {
    bool newTab = true,
  }) async {
    launchCallback() => launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: newTab ? '_blank' : '_self',
        );
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchCallback();
    } else {
      try {
        await launchCallback();
      } catch (e, st) {
        var path = url.split('?').first;
        AppLog.error('Could not open $path\n$e', st);
      }
    }
  }

  static void setWebTitle(String title) {
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: title,
        primaryColor: 0xFFFFFFFF,
      ),
    );
  }

  static void showLoader([String? message]) {
    Get.dialog(
      AppLoader(message: message),
      barrierDismissible: false,
    );
  }

  static void closeLoader() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Show error dialog from response model
  static Future<void> showInfoDialog(
    ResponseModel data, {
    bool isSuccess = false,
    String? title,
    VoidCallback? onRetry,
  }) async {
    await Get.dialog(
      CupertinoAlertDialog(
        title: Text(
          title ?? (isSuccess ? 'Success' : 'Error'),
        ),
        content: Text(
          jsonDecode(data.data)['error'] as String,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: Get.back,
            isDefaultAction: true,
            child: const Text('Okay'),
          ),
          if (onRetry != null)
            CupertinoDialogAction(
              onPressed: () {
                Get.back();
                onRetry();
              },
              isDefaultAction: true,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  static Future<void> downloadCSV({
    required List<List<dynamic>> data,
    String? filename,
  }) async {
    Utility.showLoader();

    String file = const ListToCsvConverter().convert(data);

    Uint8List bytes = Uint8List.fromList(utf8.encode(file));

    await FileSaver.instance.saveFile(
      name: '${filename ?? "data"}-${DateTime.now()}',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
    Utility.closeLoader();
  }
}
