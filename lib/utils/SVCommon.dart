import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/model/SVPost.dart';
import 'package:prokit_socialv/screens/addPost/components/SVSharePostBottomSheetComponent.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';

InputDecoration svInputDecoration(BuildContext context,
    {String? hint,
    String? label,
    TextStyle? hintStyle,
    TextStyle? labelStyle,
    Widget? prefix,
    EdgeInsetsGeometry? contentPadding,
    String? errorText,
    InputBorder? inputBorder,
    Widget? prefixIcon}) {
  return InputDecoration(
    contentPadding: contentPadding,
    labelText: label,
    hintText: hint,
    hintStyle: hintStyle ?? secondaryTextStyle(),
    labelStyle: labelStyle ?? secondaryTextStyle(),
    prefix: prefix,
    prefixIcon: prefixIcon,
    errorText: errorText,
    errorMaxLines: 2,
    errorStyle: primaryTextStyle(color: Colors.red, size: 12),
    enabledBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: SVAppBorderColor)),
    focusedBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: SVAppColorPrimary)),
    border: inputBorder ??
        UnderlineInputBorder(borderSide: BorderSide(color: SVAppColorPrimary)),
    focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.0)),
    errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.0)),
    alignLabelWithHint: true,
  );
}

Widget svRobotoText(
    {required String text,
    Color? color,
    FontStyle? fontStyle,
    Function? onTap,
    TextAlign? textAlign}) {
  return Text(
    text,
    style: secondaryTextStyle(
      fontFamily: svFontRoboto,
      color: color ?? svGetBodyColor(),
      fontStyle: fontStyle ?? FontStyle.normal,
    ),
    textAlign: textAlign ?? TextAlign.center,
  ).onTap(onTap,
      splashColor: Colors.transparent, highlightColor: Colors.transparent);
}

Color svGetBodyColor() {
  if (appStore.isDarkMode)
    return SVBodyDark;
  else
    return SVBodyWhite;
}

Widget normalTextField({
  String? labelText,
  String? hintText,
  TextEditingController? controller,
  Function(String)? onTap,
  TextInputType? keyboardType,
  int? maxLines,
  int? maxLength,
  int? borderRadius,
  required FocusNode focusNode,
}) {
  // Define your primary color
  const Color primaryColor = Color(0xFF2F65B9);

  // Define common colors based on dark mode
  final Color textColor = appStore.isDarkMode ? Colors.white : Colors.black;
  final Color hintTextColor =
      appStore.isDarkMode ? Colors.white70 : Colors.black54;

  // Colors for label and border when focused
  final Color focusedColor = appStore.isDarkMode ? Colors.white : primaryColor;

  // Colors for label and border when unfocused
  final Color unfocusedLabelColor =
      appStore.isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  final Color unfocusedBorderColor =
      appStore.isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;

  return TextFormField(
    onFieldSubmitted: onTap,
    maxLines: maxLines,
    controller: controller,
    focusNode: focusNode,
    keyboardType: keyboardType,
    style: TextStyle(color: textColor),
    maxLengthEnforcement: (keyboardType == TextInputType.multiline)
        ? MaxLengthEnforcement.enforced
        : null,
    maxLength: maxLength,
    decoration: InputDecoration(
      labelText: labelText,
      alignLabelWithHint: keyboardType == TextInputType.multiline,
      counterStyle: TextStyle(color: textColor),
      hintText: hintText,
      hintStyle: TextStyle(
        color: hintTextColor,
      ),
      labelStyle: TextStyle(
        color: focusNode.hasFocus ? focusedColor : unfocusedLabelColor,
      ),
      filled: true,
      fillColor: appStore.isDarkMode
          ? Colors.grey[850]
          : Colors.grey[100], // Background color of the text field
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 1.2, color: unfocusedBorderColor),
        borderRadius: BorderRadius.circular((borderRadius ?? 4).toDouble()),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 1.2, color: focusedColor),
        borderRadius: BorderRadius.circular((borderRadius ?? 4).toDouble()),
      ),
      floatingLabelStyle: TextStyle(color: focusedColor),
    ),
  );
}

Color svGetScaffoldColor() {
  if (appStore.isDarkMode)
    return appBackgroundColorDark;
  else
    return SVAppLayoutBackground;
}

Widget svHeaderContainer(
    {required Widget child, required BuildContext context}) {
  return Stack(
    alignment: Alignment.bottomCenter,
    children: [
      Container(
        width: context.width(),
        decoration: BoxDecoration(
            color: SVAppColorPrimary,
            borderRadius: radiusOnly(
                topLeft: SVAppContainerRadius, topRight: SVAppContainerRadius)),
        padding: EdgeInsets.all(24),
        child: child,
      ),
      Container(
        height: 20,
        decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: radiusOnly(
                topLeft: SVAppContainerRadius, topRight: SVAppContainerRadius)),
      )
    ],
  );
}

Widget svAppButton(
    {required String text,
    required Function onTap,
    double? width,
    required BuildContext context}) {
  return AppButton(
    shapeBorder:
        RoundedRectangleBorder(borderRadius: radius(SVAppCommonRadius)),
    text: text,
    textStyle: boldTextStyle(color: Colors.white),
    onTap: onTap,
    elevation: 0,
    color: SVAppColorPrimary,
    width: width ?? context.width() - 32,
    height: 56,
  );
}

Widget normalButton(
    {required String text,
    required Function() onPressed,
    IconData? icon,
    bool? matchParent,
    int? fontSize}) {
  return SizedBox(
    width: matchParent == true ? double.infinity : null,
    child: ElevatedButton(
      style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all(Color.fromARGB(255, 47, 101, 185))),
      onPressed: () {
        onPressed();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          (icon == null)
              ? SizedBox()
              : Icon(
                  icon,
                  color: white,
                ).paddingRight(8),
          Text(
            text,
            style: TextStyle(color: white, fontSize: fontSize?.toDouble()),
          )
        ],
      ),
    ),
  );
}

Future<File> svGetImageSource() async {
  final picker = ImagePicker();
  final pickedImage = await picker.pickImage(source: ImageSource.camera);
  return File(pickedImage!.path);
}

void svShowShareBottomSheet(BuildContext context, Post post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    backgroundColor: context.cardColor,
    shape: RoundedRectangleBorder(
        borderRadius: radiusOnly(topLeft: 30, topRight: 30)),
    builder: (context) {
      return SVSharePostBottomSheetComponent(post: post);
    },
  );
}

Future<String?> handleImageSelection() async {
  final result = await ImagePicker().pickImage(
    imageQuality: 70,
    maxWidth: 1440,
    source: ImageSource.gallery,
  );

  return result?.path;
}

void showToast(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      textColor: Colors.white,
      fontSize: 16.0);
}
