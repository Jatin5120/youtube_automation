import 'package:frontend/repositories/repositories.dart';
import 'package:frontend/utils/utils.dart';

class AuthViewModel {
  final AuthRepository _repository;

  AuthViewModel(this._repository);

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      var res = await _repository.loginWithEmail(email, password);
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

  Future<bool> loginWithGoogle() async {
    try {
      var res = await _repository.loginWithGoogle();
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
