// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/app.dart';
import 'package:get/get.dart';

class UploadController extends GetxController {
  DropzoneViewController? dropzoneController;

  final RxList<dynamic> _selectedFiles = <dynamic>[].obs;
  List<dynamic> get selectedFiles => _selectedFiles;
  set selectedFiles(List<dynamic> value) => _selectedFiles.value = value;

  final RxBool _isDropping = false.obs;
  bool get isDropping => _isDropping.value;
  set isDropping(bool value) {
    if (value == isDropping) {
      return;
    }
    _isDropping.value = value;
  }

  var channelIdIndex = 0;
  var channelIdHeader = 'user_id';

  var channelIdMap = <String, List<String>>{};
  List<String> _validChannelIds = [];

  int get validChannelIdsCount => _validChannelIds.length;

  // File input element for file picker
  final FileUploadInputElement _uploadInput = FileUploadInputElement()
    ..accept = '.csv'
    ..multiple = true
    ..style.display = 'none';

  // Initialize file input element
  @override
  void onInit() {
    super.onInit();
    // Add file input to the DOM
    document.body?.append(_uploadInput);

    // Add event listener for file selection
    _uploadInput.onChange.listen((event) {
      final files = _uploadInput.files;
      uploadFilesFromInput(files ?? []);
      _uploadInput.value = '';
    });
  }

  // Clean up file input element
  @override
  void onClose() {
    _uploadInput.remove();
    super.onClose();
  }

  // Method to open file picker
  void openFilePicker() {
    _uploadInput.value = ''; // Clear before opening
    _uploadInput.click();
  }

  // Method to handle files from input element
  void uploadFilesFromInput(List<File> files) {
    AppLog.info('uploadFilesFromInput triggered with ${files.length} files');
    if (files.isEmpty) return;

    // Add files to selected files
    selectedFiles.insertAll(0, files);
    _readData();
  }

  void uploadFiles(List<DropzoneFileInterface>? files) async {
    AppLog.info('uploadFiles triggered with ${files?.length ?? 0} files');
    isDropping = false;
    if (files == null || files.isEmpty) {
      return;
    }

    selectedFiles.insertAll(0, files);
    _readData();
  }

  void _readData() async {
    _validChannelIds.clear();
    if (selectedFiles.isEmpty) {
      update([UploadView.updateId]);
      return;
    }

    Utility.showLoader('Reading ${selectedFiles.length} file(s)');
    await Future.delayed(Duration.zero);

    for (var doc in selectedFiles) {
      var reader = FileReader();
      final file = doc is DropzoneFileInterface ? doc.getNative() : doc;
      reader.readAsText(file as Blob);
      await reader.onLoad.first;
      var data = reader.result as String;

      final rowsAsListOfValues = await compute(
        (String csv) => const CsvToListConverter().convert(csv),
        data,
      );

      channelIdIndex = rowsAsListOfValues.first.indexOf(channelIdHeader);
      if (channelIdIndex == -1) {
        channelIdIndex = 0;
      }

      // Process each row - extract first column (channel ID)
      for (var row in rowsAsListOfValues) {
        if (row.isNotEmpty) {
          final channelId = row[channelIdIndex].toString().trim();
          if (validateChannelId(channelId)) {
            _validChannelIds.add(channelId);
          }
        }
      }
    }

    // Remove duplicates
    _validChannelIds = _validChannelIds.toSet().toList();

    Utility.closeLoader();
    update([UploadView.updateId]);
  }

  bool validateChannelId(String id) {
    if (id.isEmpty) return false;
    // YouTube channel ID format: UC followed by 22 characters
    return RegExp(r'^UC[a-zA-Z0-9_-]{22}$').hasMatch(id);
  }

  void clearFiles() {
    selectedFiles.clear();
    _validChannelIds.clear();
    update([UploadView.updateId]);
  }

  void removeFile(dynamic file) {
    selectedFiles.remove(file);
    _readData();
  }

  void fetchDetails() async {
    channelIdMap['CSV Upload'] = _validChannelIds;
    Get.find<DbClient>().save(LocalKeys.queriesChannels, channelIdMap);

    RouteManagement.goToDashboard();

    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().fetchChannels();
    }
  }
}
