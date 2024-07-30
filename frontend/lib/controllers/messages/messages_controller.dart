// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:csv/csv.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class MessagesController extends GetxController {
  DropzoneViewController? dropzoneController;

  final RxList<File> _selectedFiles = <File>[].obs;
  List<File> get selectedFiles => _selectedFiles;
  set selectedFiles(List<File> value) => _selectedFiles.value = value;

  final RxBool _isGenerating = false.obs;
  bool get isGenerating => _isGenerating.value;
  set isGenerating(bool value) {
    if (value == isGenerating) {
      return;
    }
    _isGenerating.value = value;
  }

  final RxDouble _generateProgress = 0.0.obs;
  double get generateProgress => _generateProgress.value;
  set generateProgress(double value) {
    if (value == generateProgress) {
      return;
    }
    _generateProgress.value = value;
  }

  var totalData = <List<dynamic>>[];

  var header = <String>[];

  // var emailTEC = TextEditingController();
  var dmTEC = TextEditingController();

  var nameIndex = 0;
  var titleIndex = 0;
  var instaIndex = 0;
  var descriptionIndex = 0;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<AnalysisController>()) {
      AnalysisBinding().dependencies();
    }
  }

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
    nameIndex = header.indexOf(AppConstants.nameColumnHead);
    titleIndex = header.indexOf(AppConstants.titleColumnHead);
    instaIndex = header.indexOf(AppConstants.instaColumnHead);
    descriptionIndex = header.indexOf(AppConstants.descriptionColumnHead);
  }

  void clearFiles() {
    selectedFiles.clear();
    totalData.clear();
  }

  void removeFile(File file) {
    selectedFiles.remove(file);
    _readData();
  }

  void onDmContentChange() {
    update([MessagesView.dmContentId]);
  }

  void generateContent() async {
    if (dmTEC.text.trim().isEmpty) {
      Utility.showInfoDialog(ResponseModel.message('DM Content Template must be filled'));
      return;
    }
    if (selectedFiles.isEmpty) {
      Utility.showInfoDialog(ResponseModel.message('No file is selected'));
      return;
    }
    if (!Get.isRegistered<AnalysisController>()) {
      AnalysisBinding().dependencies();
    }
    isGenerating = true;
    final controller = Get.find<AnalysisController>();

    var output = <List<dynamic>>[];
    for (var rowData in totalData.indexed) {
      final row = rowData.$2;
      final index = rowData.$1;
      var title = row[titleIndex];
      var name = row[nameIndex];
      var instagram = row[instaIndex].toString();
      var description = row[descriptionIndex];

      generateProgress = (index / totalData.length);

      final content = await controller.generateDm(
        title: title,
        username: name,
        description: description,
        template: dmTEC.text,
      );

      // var emailContent = emailTEC.text.split(ContentItem.name.text).join(name).split(ContentItem.title.text).join(title);

      var instaContent = instagram.isEmpty ? 'N/A' : instagram.split('com/').last.replaceAll('/', '');
      var data = <String>[
        instaContent,
        content ?? '',
        '',
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
    generateProgress = 100;
    isGenerating = false;
    var titles = <String>[
      'Instagram Username',
      'Personalized Message',
      '',
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
