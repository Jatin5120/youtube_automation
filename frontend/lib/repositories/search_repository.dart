import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/utils/utils.dart';

class SearchRepository {
  SearchRepository(this._apiWrapper);

  final ApiWrapper _apiWrapper;

  Future<ResponseModel> searchChannels(String query) async {
    return _apiWrapper.makeRequest(
      '${Endpoints.search}?query=$query',
      type: RequestType.get,
      showLoader: true,
    );
  }
}
