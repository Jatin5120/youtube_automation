import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';

class DashboardRepository {
  DashboardRepository(this._apiWrapper);

  final ApiWrapper _apiWrapper;

  Future<ResponseModel> getVideos(String ids) async {
    // return ResponseModel(
    //     data: jsonEncode([
    //       {
    //         "subscriberCount": "1160",
    //         "totalVideos": "173",
    //         "channelName": "another homosapien",
    //         "userName": "@anotherhomosapien",
    //         "totalVideosLastMonth": 1,
    //         "latestVideoTitle": "He funded Wolf of the Wall Street🐺😱 #funding #startup #scam #wolfofthewallstreet #anotherhomosapien",
    //         "lastUploadDate": "2022-02-02T12:05:47Z",
    //         "uploadedThisMonth": false
    //       },
    //       {
    //         "subscriberCount": "549000",
    //         "totalVideos": "504",
    //         "channelName": "Flutter",
    //         "userName": "@flutterdev",
    //         "totalVideosLastMonth": 6,
    //         "latestVideoTitle": "Observable Flutter #38: Building with Serverpod, Initial Setup",
    //         "lastUploadDate": "2024-03-15T06:42:43Z",
    //         "uploadedThisMonth": true
    //       }
    //     ]),
    //     hasError: false);
    return _apiWrapper.makeRequest(
      '${Endpoints.videos}?ids=$ids',
      type: RequestType.get,
      showLoader: true,
    );
  }
}
