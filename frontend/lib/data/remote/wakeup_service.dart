import 'package:frontend/data/data.dart';
import 'package:frontend/utils/utils.dart';

/// Service to keep the Render.com server alive by calling the wakeup endpoint
class WakeupService {
  WakeupService(this._apiWrapper);

  final ApiClient _apiWrapper;

  /// Call the wakeup endpoint to keep the server alive
  /// This should be called when the app starts to prevent Render.com from spinning down the server
  Future<bool> wakeupServer() async {
    try {
      AppLog.info('Waking up server...');

      final response = await _apiWrapper.makeRequest(
        Endpoints.wakeup,
        type: RequestType.get,
      );

      if (response.decode()['status'] == 'awake') {
        AppLog.info('Server wakeup successful');
        return true;
      } else {
        AppLog.error('Server wakeup failed');
        return false;
      }
    } catch (e) {
      AppLog.error('Server wakeup error');
      return false;
    }
  }
}
