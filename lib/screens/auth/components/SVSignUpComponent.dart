import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/screens/SVDashboardScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/localrules.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/Translations.dart';

class UserAFD {
  final String name;
  final String username;
  final String email;
  final String password;

  const UserAFD(this.name, this.username, this.email, this.password);
} // User a few details data class

class SVSignUpComponent extends StatefulWidget {
  final VoidCallback? callback;

  SVSignUpComponent({this.callback});

  @override
  State<SVSignUpComponent> createState() => _SVSignUpComponentState();
}

class _SVSignUpComponentState extends State<SVSignUpComponent> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  AuthService authService = AuthService();
  LocalRules localRules = LocalRules();
  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      color: context.cardColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Text(s.helloUser, style: boldTextStyle(size: 24))
                .paddingSymmetric(horizontal: 16),
            8.height,
            Text(
                    s.tr
                        ? "Daha İyi Deneyim İçin Hesap Oluştur"
                        : 'Create Your Account For Better Experience',
                    style: secondaryTextStyle(
                        weight: FontWeight.w500, color: svGetBodyColor()))
                .paddingSymmetric(horizontal: 16),
            Container(
              child: Column(
                children: [
                  30.height,
                  AppTextField(
                    controller: nameController,
                    textFieldType: TextFieldType.NAME,
                    textStyle: boldTextStyle(),
                    decoration: svInputDecoration(
                      context,
                      label: s.name,
                      labelStyle: secondaryTextStyle(
                          weight: FontWeight.w600, color: svGetBodyColor()),
                    ),
                  ).paddingSymmetric(horizontal: 16),
                  8.height,
                  AppTextField(
                    controller: usernameController,
                    textFieldType: TextFieldType.NAME,
                    textStyle: boldTextStyle(),
                    decoration: svInputDecoration(
                      context,
                      label: s.username,
                      labelStyle: secondaryTextStyle(
                          weight: FontWeight.w600, color: svGetBodyColor()),
                    ),
                  ).paddingSymmetric(horizontal: 16),
                  8.height,
                  AppTextField(
                    controller: emailController,
                    textFieldType: TextFieldType.EMAIL,
                    textStyle: boldTextStyle(),
                    decoration: svInputDecoration(
                      context,
                      label: 'Email',
                      labelStyle: secondaryTextStyle(
                          weight: FontWeight.w600, color: svGetBodyColor()),
                    ),
                  ).paddingSymmetric(horizontal: 16),
                  16.height,
                  AppTextField(
                    controller: passwordController,
                    textFieldType: TextFieldType.PASSWORD,
                    textStyle: boldTextStyle(),
                    suffixIconColor: svGetBodyColor(),
                    suffixPasswordInvisibleWidget: Image.asset(
                            'images/socialv/icons/ic_Hide.png',
                            height: 16,
                            width: 16,
                            fit: BoxFit.fill)
                        .paddingSymmetric(vertical: 16, horizontal: 14),
                    suffixPasswordVisibleWidget:
                        svRobotoText(text: s.show, color: SVAppColorPrimary)
                            .paddingOnly(top: 20),
                    decoration: svInputDecoration(
                      context,
                      label: s.password,
                      contentPadding: EdgeInsets.all(0),
                      labelStyle: secondaryTextStyle(
                          weight: FontWeight.w600, color: svGetBodyColor()),
                    ),
                  ).paddingSymmetric(horizontal: 16),
                  80.height,
                  svAppButton(
                    context: context,
                    text: s.signUp.toUpperCase(),
                    onTap: () {
                      final name = nameController.text;
                      final username = usernameController.text;
                      final email = emailController.text;
                      final password = passwordController.text;
                      final userAFD = UserAFD(name, username, email, password);

                      authService.signUp(userAFD).then((value) {
                        if (value != null) {
                          //with email
                          localRules.setLoginType(0);
                          SVDashboardScreen().launch(context);
                        }
                      });
                    },
                  ),
                  16.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      svRobotoText(text: s.alreadyHaveAccount),
                      4.width,
                      Text(
                        s.tr ? "Giriş Yap" : "Sign In",
                        style: secondaryTextStyle(
                            color: SVAppColorPrimary,
                            decoration: TextDecoration.underline),
                      ).onTap(() {
                        widget.callback?.call();
                      },
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent)
                    ],
                  ),
                  50.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
