import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/screens/SVDashboardScreen.dart';
import 'package:prokit_socialv/screens/auth/screens/SVForgetPasswordScreen.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/service/localrules.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../service/auth.dart';

class SVLoginInComponent extends StatefulWidget {
  final VoidCallback? callback;

  SVLoginInComponent({this.callback});

  @override
  State<SVLoginInComponent> createState() => _SVLoginInComponentState();
}

class _SVLoginInComponentState extends State<SVLoginInComponent> {
  bool doRemember = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  LocalRules localRules = LocalRules();

  AuthService _authService = AuthService();
  final s = Translations();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? userModel;
    String? username;
    return Container(
      width: context.width(),
      color: context.cardColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Text(s.welcomeBack, style: boldTextStyle(size: 24))
                .paddingSymmetric(horizontal: 16),
            8.height,
            Text(s.moreWelcome,
                    style: secondaryTextStyle(
                        weight: FontWeight.w500, color: svGetBodyColor()))
                .paddingSymmetric(horizontal: 16),
            Container(
              child: Column(
                children: [
                  30.height,
                  AppTextField(
                    textFieldType: TextFieldType.EMAIL,
                    textStyle: boldTextStyle(),
                    controller: emailController,
                    decoration: svInputDecoration(
                      context,
                      label: 'Email',
                      labelStyle: secondaryTextStyle(
                          weight: FontWeight.w600, color: svGetBodyColor()),
                    ),
                  ).paddingSymmetric(horizontal: 16),
                  16.height,
                  AppTextField(
                    textFieldType: TextFieldType.PASSWORD,
                    textStyle: boldTextStyle(),
                    suffixIconColor: svGetBodyColor(),
                    controller: passwordController,
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
                  12.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            shape:
                                RoundedRectangleBorder(borderRadius: radius(2)),
                            activeColor: SVAppColorPrimary,
                            value: doRemember,
                            onChanged: (val) {
                              doRemember = val.validate();
                              localRules.setRememberMeState(doRemember);
                              setState(() {});
                            },
                          ),
                          svRobotoText(text: s.rememberMe),
                        ],
                      ),
                      svRobotoText(
                        text: s.forgetPassword,
                        color: SVAppColorPrimary,
                        fontStyle: FontStyle.italic,
                        onTap: () {
                          SVForgetPasswordScreen().launch(context);
                        },
                      ).paddingSymmetric(horizontal: 16),
                    ],
                  ),
                  32.height,
                  svAppButton(
                    context: context,
                    text: s.login,
                    onTap: () {
                      _authService
                          .signIn(emailController.text, passwordController.text)
                          .then((value) {
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
                      svRobotoText(text: s.dontHaveAccount),
                      4.width,
                      Text(
                        s.signUp,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget ivIcon(BuildContext context, String imagePath, Function() onClick) {
    return InkWell(
      onTap: () {
        onClick();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Image.asset(imagePath, height: 36, width: 36, fit: BoxFit.cover),
      ),
    );
  }
}
