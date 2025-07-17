import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/screens/auth/screens/SVSignInScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/Translations.dart';

class SVForgetPasswordScreen extends StatefulWidget {
  const SVForgetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<SVForgetPasswordScreen> createState() => _SVForgetPasswordState();
}

class _SVForgetPasswordState extends State<SVForgetPasswordScreen> {
  AuthService authService = AuthService();
  final mailController = TextEditingController();
  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      body: Column(
        children: [
          SizedBox(height: context.statusBarHeight + 30),
          svHeaderContainer(
            child: Text(
              s.forgetPassword,
              style: boldTextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ).paddingOnly(bottom: 16),
            context: context,
          ),
          Container(
            width: context.width(),
            color: context.cardColor,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  20.height,
                  svRobotoText(text: s.forgetPassDetail),
                  50.height,
                  AppTextField(
                    controller: mailController,
                    textFieldType: TextFieldType.EMAIL,
                    textStyle: boldTextStyle(),
                    decoration: svInputDecoration(
                      context,
                      label: s.enterYourEmail,
                      labelStyle: secondaryTextStyle(
                          weight: FontWeight.w600, color: svGetBodyColor()),
                    ),
                  ).paddingSymmetric(horizontal: 16),
                  100.height,
                  svAppButton(
                    context: context,
                    text: s.getMail,
                    onTap: () {
                      authService.sendResetLink(mailController.text);
                    },
                  ),
                  16.height,
                  svRobotoText(
                    text: s.backToLogin,
                    color: Color(0XFF7B8BB2),
                    onTap: () {
                      finish(context);
                      SVSignInScreen().launch(context);
                    },
                  ),
                ],
              ),
            ),
          ).expand()
        ],
      ),
    );
  }
}
