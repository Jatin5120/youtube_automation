// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/utils/utils.dart';
import 'package:get/get.dart';

class ReachController extends GetxController {
  DropzoneViewController? dropzoneController;

  final RxList<File> _selectedFiles = <File>[].obs;
  List<File> get selectedFiles => _selectedFiles;
  set selectedFiles(List<File> value) => _selectedFiles.value = value;

  void uploadFiles(List<dynamic>? files) {
    AppLog.info('Drop multiple: $files');
    if (files == null || files.isEmpty) {
      return;
    }
    var docs = files.where((e) => e.runtimeType == File).cast<File>().toList();
    for (var doc in docs) {
      AppLog(doc.name);
    }
    selectedFiles = docs;
  }
}
