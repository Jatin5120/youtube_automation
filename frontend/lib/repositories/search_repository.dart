import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';

class SearchRepository {
  SearchRepository(this._apiWrapper);

  final ApiWrapper _apiWrapper;

  Future<ResponseModel> searchChannels({
    required String query,
    required String pageToken,
  }) async {
    var params = 'query=$query';
    if (pageToken.trim().isNotEmpty) {
      params += '&pageToken=$pageToken';
    }
    return _apiWrapper.makeRequest(
      '${Endpoints.search}?$params',
      type: RequestType.get,
      showLoader: true,
    );
  }
}
