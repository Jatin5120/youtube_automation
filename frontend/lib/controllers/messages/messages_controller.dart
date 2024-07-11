// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:csv/csv.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class MessagesController extends GetxController {
  DropzoneViewController? dropzoneController;

  final RxList<File> _selectedFiles = <File>[].obs;
  List<File> get selectedFiles => _selectedFiles;
  set selectedFiles(List<File> value) => _selectedFiles.value = value;

  var totalData = <List<dynamic>>[];

  var header = <String>[];

  var emailTEC = TextEditingController();
  var dmTEC = TextEditingController();

  var nameIndex = 2;
  var titleIndex = 3;

  var instaIndex = 5;

  void uploadFiles(List<dynamic>? files) async {
    if (files == null || files.isEmpty) {
      return;
    }
    var docs = files.where((e) => e.runtimeType == File).cast<File>().toList();

    selectedFiles.insertAll(0, docs);
    _readData();
  }

  void _readData() async {
    totalData.clear();
    var count = 0;
    for (var doc in selectedFiles) {
      var reader = FileReader();
      reader.readAsText(doc);
      await reader.onLoad.first;
      var data = reader.result as String;
      var rowsAsListOfValues = const CsvToListConverter().convert(data);
      if (count == 0 && rowsAsListOfValues.isNotEmpty) {
        header = rowsAsListOfValues.first.cast();
        count++;
      }
      rowsAsListOfValues.removeAt(0);
      totalData.addAll(rowsAsListOfValues);
    }
  }

  void clearFiles() {
    selectedFiles.clear();
    totalData.clear();
  }

  void removeFile(File file) {
    selectedFiles.remove(file);
    _readData();
  }

  void onEmailContentChange() {
    update([MessagesView.emailContentId]);
  }

  void onDmContentChange() {
    update([MessagesView.dmContentId]);
  }

  void generateContent() async {
    if (emailTEC.text.trim().isEmpty || dmTEC.text.trim().isEmpty) {
      Utility.showInfoDialog(ResponseModel.message('Both Email Content and DM Content must be filled'));
      return;
    }
    if (selectedFiles.isEmpty) {
      Utility.showInfoDialog(ResponseModel.message('No file is selected'));
      return;
    }
    AppLog.info(header);
    var output = <List<dynamic>>[];
    for (var row in totalData) {
      var title = row[titleIndex];
      var name = row[nameIndex];
      var instagram = row[instaIndex].toString();
      var emailContent = emailTEC.text.split(ContentItem.name.text).join(name).split(ContentItem.title.text).join(title);
      var dmContent = dmTEC.text.split(ContentItem.name.text).join(name).split(ContentItem.title.text).join(title);
      var instaContent = instagram.isEmpty ? 'N/A' : instagram.split('com/').last.replaceAll('/', '');
      var data = <String>[
        instaContent,
        emailContent,
        dmContent,
        ...List.generate(3, (_) => ''),
      ];
      var emptyData = [
        DateTime.now().formatDate,
        ...List.generate(6, (_) => ''),
      ];
      row.insertAll(10, data);
      row.insertAll(0, emptyData);
      output.add(row);
    }
    var titles = <String>[
      'Instagram Username',
      'Email Content',
      'Dm Content',
      'Status',
      'Platform',
      'Sent Date',
    ];
    var emptyTitles = [
      'First Connected Date',
      'Last Connected Date',
      'Notes',
      'Which Channel',
      'Which Subchannel',
      'Stage',
      'Sales Rep',
    ];
    header.insertAll(10, titles);
    header.insertAll(0, emptyTitles);
    output.insert(0, header);

    await Utility.downloadCSV(
      data: output,
      filename: 'message-content',
    );
    Utility.showInfoDialog(
      ResponseModel.message('Your Message content is downloaded'),
      isSuccess: true,
    );
  }
}
