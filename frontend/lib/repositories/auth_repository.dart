import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<ResponseModel> loginWithEmail(String email, String password) async {
    try {
      Utility.showLoader();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Utility.closeLoader();
      DBWrapper.i.saveValue(AppKeys.isLoggedIn, true);
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

  Future<ResponseModel> loginWithGoogle() async {
    try {
      Utility.showLoader();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        Utility.closeLoader();
        return ResponseModel.message('Error occured from Google provider', isSuccess: false);
      }
      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      var userCredential = await _auth.signInWithCredential(credential);
      var user = userCredential.user;

      if (user == null) {
        Utility.closeLoader();
        return ResponseModel.message('Google user not found', isSuccess: false);
      }
      Utility.closeLoader();
      DBWrapper.i.saveValue(AppKeys.isLoggedIn, true);
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
