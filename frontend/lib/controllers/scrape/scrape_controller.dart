import 'dart:convert';
import 'dart:typed_data';

import 'package:chaleno/chaleno.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/views/views.dart';
import 'package:get/get.dart';

class ScrapeController extends GetxController {
  var channels = <ScrapeModel>[];

  var searchController = TextEditingController();

  var tableController = ScrollController();

  var fetchedResult = false;

  void getVideos() async {
    if (searchController.text.trim().isEmpty) {
      return;
    }

    channels = await _getVideosByUrl();
    fetchedResult = true;
    update([ScrapeView.updateId]);
  }

  Future<List<ScrapeModel>> _getVideosByUrl() async {
    if (searchController.text.trim().isEmpty) {
      return [];
    }
    try {
      var parser = await Chaleno().load(
        searchController.text.trim(),
      );
      if (parser == null) {
        return [];
      }
      var d = parser.children;
      if (d == null || d.isEmpty) {
        return [];
      }
      var body = d.first.children.last;
      var script = body.children.where((e) => e.localName == 'script').firstWhere((e) => e.innerHtml.startsWith('var ytInitialData'));
      var content = jsonDecode(script.innerHtml.split("var ytInitialData =").last.trim().replaceAll(';', ''));

      var dataList = content['contents']['twoColumnSearchResultsRenderer']['primaryContents']['sectionListRenderer']['contents'] as List;

      var data = (dataList.first['itemSectionRenderer']['contents'] as List)
          .where((e) => e['channelRenderer'] != null)
          .map((e) => e['channelRenderer'])
          .toList();
      return data.map((e) => ScrapeModel.fromMap(e)).toList();
    } catch (e, st) {
      AppLog.error(e, st);
      AppLog.error(st);
      return [];
    }
  }

  void downloadCSV() async {
    Utility.showLoader();
    String file = const ListToCsvConverter().convert(
      [
        [
          'Channel Name',
          'UserName',
          'Channel Id',
          'Channel Link',
          'Subscribers',
        ],
        ...channels.map((e) => e.properties.toList()),
      ],
    );

    Uint8List bytes = Uint8List.fromList(utf8.encode(file));

    await FileSaver.instance.saveFile(
      name: 'scrape-${DateTime.now()}',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
    Utility.closeLoader();
  }
}
