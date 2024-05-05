import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';

class DashboardRepository {
  DashboardRepository(this._apiWrapper);

  final ApiWrapper _apiWrapper;

  Future<ResponseModel> getVideosByChannelIdentifier(
    Map<String, dynamic> payload,
  ) async {
    return _apiWrapper.makeRequest(
      Endpoints.videos,
      type: RequestType.patch,
      payload: payload,
      showLoader: true,
    );
  }
}
