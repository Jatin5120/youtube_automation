import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';

class DashboardRepository {
  DashboardRepository(this._apiWrapper);

  final ApiWrapper _apiWrapper;

  Future<ResponseModel> getVideos(String ids) => _apiWrapper.makeRequest(
        '${Endpoints.videos}?ids=$ids',
        type: RequestType.get,
        showLoader: true,
      );
}
