import 'package:nb_utils/nb_utils.dart';

class LocalRules {
  Future<SharedPreferences> getSharedPref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  bool rememberMeState(SharedPreferences sharedPreferences) {
    final bool? rememberMe = sharedPreferences.getBool("rememberMe");
    bool rememberMeNN;
    rememberMeNN = (rememberMe == null) ? true : rememberMe;
    return rememberMeNN;
  }

  void setRememberMeState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("rememberMe", state);
  }

  int loginTypeState(SharedPreferences sharedPreferences) {
    final int? loginType = sharedPreferences.getInt("loginType");
    int loginTypeNN;
    loginTypeNN = (loginType == null) ? 0 : loginType;
    return loginTypeNN;
  }

  void setLoginType(int loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("loginType", loginType);
  }
}
