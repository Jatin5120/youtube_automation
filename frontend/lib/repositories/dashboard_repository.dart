import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';

class DashboardRepository {
  DashboardRepository(this._apiWrapper);

  final ApiWrapper _apiWrapper;

  Future<ResponseModel> getVideos(String ids, bool useId) async {
    return _apiWrapper.makeRequest(
      '${Endpoints.videos}?ids=$ids&useId=$useId',
      type: RequestType.get,
      showLoader: true,
    );
  }
}
