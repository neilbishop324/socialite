import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/utils/Translations.dart';
import 'dart:math';
import 'package:csc_picker_plus/csc_picker_plus.dart';

import '../main.dart';

class Extensions {
  showAlertDialog(BuildContext context, String title, String message,
      String posButtonText, Function() posButtonOnClick) {
    // Create button
    Widget okButton = ElevatedButton(
      child: Text(posButtonText, style: TextStyle(color: Colors.white)),
      onPressed: () {
        Navigator.of(context).pop();
        posButtonOnClick();
      },
    );

    Widget cancelButton = ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child:
            Text(Translations().cancel, style: TextStyle(color: Colors.white)));

    // Create AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [cancelButton, okButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static final TextEditingController _emailEditingController =
      TextEditingController();
  static final TextEditingController _passwordEditingController =
      TextEditingController();

  static Future<void> showInformationDialog(
      BuildContext context,
      String title,
      String field1hint,
      String field2hint,
      String posButtonTitle,
      Function(UserLogInfo) posButtonOnClick) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailEditingController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return;
                          }
                          return null;
                        },
                        decoration: InputDecoration(hintText: field1hint),
                      ),
                      TextFormField(
                        controller: _passwordEditingController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return Translations().incompleteInfo;
                          }
                          return null;
                        },
                        decoration: InputDecoration(hintText: field2hint),
                      )
                    ],
                  )),
              title: Text(title),
              actions: <Widget>[
                ElevatedButton(
                    onPressed: () => {
                          if (_formKey.currentState!.validate())
                            {
                              // Do something like updating SharedPreferences or User Settings etc.
                              Navigator.of(context).pop(),
                              posButtonOnClick(UserLogInfo(
                                  email: _emailEditingController.text,
                                  password: _passwordEditingController.text))
                            }
                        },
                    child: Text(
                      posButtonTitle,
                      style: TextStyle(color: Colors.white),
                    ))
              ],
            );
          });
        });
  }

  static String? countryValue = "";
  static String? stateValue = "";
  static String? cityValue = "";
  static String address = "";

  static Future<void> showLocationDialog(
      BuildContext context, Function(UserLocation location) saveOnClick) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            height: 250,
                            child: Column(
                              children: [
                                ///Adding CSC Picker Widget in app
                                CSCPickerPlus(
                                  ///Enable disable state dropdown [OPTIONAL PARAMETER]
                                  showStates: true,

                                  /// Enable disable city drop down [OPTIONAL PARAMETER]
                                  showCities: true,

                                  ///Enable (get flat with country name) / Disable (Disable flag) / ShowInDropdownOnly (display flag in dropdown only) [OPTIONAL PARAMETER]
                                  flagState: CountryFlag.SHOW_IN_DROP_DOWN_ONLY,

                                  ///Dropdown box decoration to style your dropdown selector [OPTIONAL PARAMETER] (USE with disabledDropdownDecoration)
                                  dropdownDecoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      color: Colors.white,
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1)),

                                  ///Disabled Dropdown box decoration to style your dropdown selector [OPTIONAL PARAMETER]  (USE with disabled dropdownDecoration)
                                  disabledDropdownDecoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      color: Colors.grey.shade300,
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1)),

                                  ///selected item style [OPTIONAL PARAMETER]
                                  selectedItemStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),

                                  ///DropdownDialog Heading style [OPTIONAL PARAMETER]
                                  dropdownHeadingStyle: TextStyle(
                                      color:
                                          appStore.isDarkMode ? white : black,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),

                                  ///DropdownDialog Item style [OPTIONAL PARAMETER]
                                  dropdownItemStyle: TextStyle(
                                    color: appStore.isDarkMode ? white : black,
                                    fontSize: 14,
                                  ),

                                  ///Dialog box radius [OPTIONAL PARAMETER]
                                  dropdownDialogRadius: 10.0,

                                  ///Search bar radius [OPTIONAL PARAMETER]
                                  searchBarRadius: 10.0,

                                  ///triggers once country selected in dropdown
                                  onCountryChanged: (value) {
                                    setState(() {
                                      ///store value in country variable
                                      countryValue = value;
                                    });
                                  },

                                  ///triggers once state selected in dropdown
                                  onStateChanged: (value) {
                                    setState(() {
                                      ///store value in state variable
                                      stateValue = value;
                                    });
                                  },

                                  ///triggers once city selected in dropdown
                                  onCityChanged: (value) {
                                    setState(() {
                                      ///store value in city variable
                                      cityValue = value;
                                    });
                                  },

                                  countrySearchPlaceholder:
                                      Translations().sCountry,
                                  stateSearchPlaceholder: Translations().sState,
                                  citySearchPlaceholder: Translations().sCity,
                                  countryDropdownLabel: Translations().country,
                                  stateDropdownLabel: Translations().state,
                                  cityDropdownLabel: Translations().city,
                                ),

                                ///print newly selected country state and city in Text Widget
                                TextButton(
                                    onPressed: () {
                                      setState(() {
                                        address =
                                            "$cityValue, $stateValue, $countryValue";
                                      });
                                    },
                                    child: Text(Translations().showLocInfo,
                                        style: TextStyle(
                                            color: appStore.isDarkMode
                                                ? white
                                                : black))),
                                Text(address)
                              ],
                            )),
                      )
                    ],
                  )),
              title: Text(Translations().selectLoc),
              actions: <Widget>[
                ElevatedButton(
                    onPressed: () => {
                          if (_formKey.currentState!.validate())
                            {
                              // Do something like updating SharedPreferences or User Settings etc.
                              Navigator.of(context).pop(),
                              saveOnClick(UserLocation(
                                  city: cityValue.toString(),
                                  state: stateValue.toString(),
                                  country: countryValue.toString()))
                            }
                        },
                    child: Text(
                      Translations().save,
                      style: TextStyle(color: Colors.white),
                    ))
              ],
            );
          });
        });
  }

  static Future<File?> getFromGallery() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      return imageFile;
    }
    return null;
  }

  static String generateRandomString(int len) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }
}

void handleAttachmentPressed(
    BuildContext context, List<NameAndAction> nameAndActionList) {
  List<Widget> widgetList = [];
  for (NameAndAction naa in nameAndActionList) {
    widgetList.add(
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          naa.onClick();
        },
        child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(naa.name,
                style:
                    TextStyle(color: (appStore.isDarkMode) ? white : black))),
      ),
    );
  }
  showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: SizedBox(
        height: 48 * (nameAndActionList.length + 1),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.from(widgetList)
              ..add(
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(Translations().cancel,
                        style: TextStyle(
                            color: (appStore.isDarkMode) ? white : black)),
                  ),
                ),
              )),
      ),
    ),
  );
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

class NameAndAction {
  final String name;
  final Function() onClick;

  NameAndAction(this.name, this.onClick);
}

class UserLogInfo {
  final String email;
  final String password;
  const UserLogInfo({required this.email, required this.password});
}

List<Color> colors = [
  Color(0xff92cbf1),
  Color(0xfface5ee),
  Color(0xffa1d7c9),
  Color(0xffefc5b5),
  Color(0xffe1d590),
  Color(0xfffdee73),
  Color(0xfff5dcb4),
  Color(0xffaaffaa),
  Color(0xff95e3c0),
  Color(0xffaefd6c),
  Color(0xffccfd7f),
  Color(0xffcae1d9),
  Color(0xffa5fbd5),
  Color(0xffbde8d8),
  Color(0xffffa180),
  Color(0xffefc0fe),
  Color(0xff9ab8c2),
  Color(0xffffc5cb),
  Color(0xffeeaaff),
  Color(0xfff3bbca),
];
