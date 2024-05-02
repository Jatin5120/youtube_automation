import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class AuthViewModel {
  final AuthRepository _repository;

  AuthViewModel(this._repository);

  Future<bool> login(String email, String password) async {
    try {
      var res = await _repository.login(email, password);
      if (res.hasError) {
        return false;
      }
      return true;
    } catch (e, st) {
      AppLog.error(e, st);
      AppLog.error(st.toString());
      return false;
    }
  }
}
