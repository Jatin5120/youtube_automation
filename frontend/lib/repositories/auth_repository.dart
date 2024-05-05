import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';

class AuthRepository {
  Future<ResponseModel> login(String email, String password) async {
    try {
      Utility.showLoader();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Utility.closeLoader();
      return ResponseModel.message(
        'Logged In Successfully',
        isSuccess: true,
      );
    } on FirebaseAuthException catch (e, st) {
      Utility.closeLoader();
      AppLog.error(e);
      AppLog.error(st);
      var error = '';
      if (e.code == 'network-request-failed') {
        error = AppStrings.noInternet;
      } else if (e.code == 'user-not-found') {
        error = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        error = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-credential') {
        error = 'Invalid Credentials';
      }
      var res = ResponseModel.message(error, isSuccess: false);
      await Utility.showInfoDialog(res);
      return res;
    } on FirebaseException catch (e, st) {
      Utility.closeLoader();
      AppLog.error(e);
      AppLog.error(st);
      var res = ResponseModel.message(e.message ?? 'Unknown Firebase Exception', isSuccess: false);
      await Utility.showInfoDialog(res);
      return res;
    } catch (e, st) {
      Utility.closeLoader();
      AppLog.error(e);
      AppLog.error(st);
      var res = ResponseModel.message('Unknown Error occured', isSuccess: false);
      await Utility.showInfoDialog(res);
      return res;
    }
  }
}
