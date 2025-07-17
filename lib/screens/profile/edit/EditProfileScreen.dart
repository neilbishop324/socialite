import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/service/localrules.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  LocalRules localRules = LocalRules();
  AuthService authService = AuthService();
  FirestoreService firestoreService = FirestoreService();
  final borderRadius = BorderRadius.circular(100); // Image border

  String imageLink = SVConstants.imageLinkDefault;
  String bgImageLink = SVConstants.backgroundLinkDefault;

  File? imageFile;
  File? bgImageFile;

  bool showFileForImage = false;
  bool showFileForBgImage = false;

  String name = 'Mal Nurrisht';
  UserDetails? userModel;

  String gender = "";
  String birthday = "";
  String location = "";
  UserLocation? locationVal;

  Color aboutContainerColor = appStore.isDarkMode
      ? Color.fromARGB(255, 44, 45, 49)
      : Color.fromARGB(255, 221, 221, 225);

  Color oppositeColor = appStore.isDarkMode ? Colors.white : Colors.black;

  final nameController = TextEditingController();
  final bioController = TextEditingController();

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);

    final uid = authService.getUid();
    firestoreService.getUser(uid).then((user) {
      if (user != null) {
        setState(() {
          name = user.name;
          imageLink = user.ppUrl;
          bgImageLink = user.bgUrl;
          userModel = user;
          gender = (userModel != null) ? userModel!.gender : "";
          birthday = (userModel != null) ? userModel!.birthDay : "";
          location = (userModel != null)
              ? userModel!.location.city +
                  ((userModel!.location.city.length != 0) ? ", " : "") +
                  userModel!.location.state +
                  ((userModel!.location.state.length != 0) ? ", " : "") +
                  userModel!.location.country
              : "";
          bioController.text = userModel!.bio;
          nameController.text = name;
        });
      }
    });
    super.initState();
  }

  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          title: Text(s.editYourProfile, style: boldTextStyle(size: 20)),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: context.iconColor),
        ),
        body: WillPopScope(
            child: bodyWidget(context),
            onWillPop: () async {
              Navigator.pop(context);
              return true;
            }),
      ),
    );
  }

  Widget bodyWidget(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
                child: Column(
              children: [
                profileHeader(context),
                AppTextField(
                    textFieldType: TextFieldType.NAME,
                    controller: nameController,
                    decoration: InputDecoration(
                      floatingLabelStyle: TextStyle(color: oppositeColor),
                      focusColor: Colors.deepOrange,
                      labelText: s.yourName,
                    )).paddingSymmetric(horizontal: 16),
                bioLayout(context),
                accountInfo(context)
              ],
            ).paddingBottom(32))));
  }

  Widget bioLayout(BuildContext context) {
    return AppTextField(
            textFieldType: TextFieldType.MULTILINE,
            controller: bioController,
            decoration: InputDecoration(
              floatingLabelStyle: TextStyle(color: oppositeColor),
              labelText: s.yourBio,
            ))
        .paddingTop((userModel != null) ? 12 : 0)
        .paddingSymmetric(horizontal: 16);
  }

  Widget profileHeader(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: <Widget>[
          InkWell(
            onTap: () async {
              bgImageFile = await Extensions.getFromGallery();
              if (bgImageFile != null) {
                setState(() {
                  showFileForBgImage = true;
                });
              }
            },
            child: (showFileForBgImage)
                ? Image.file(bgImageFile!)
                : Image.network(
                    bgImageLink,
                    height: 150,
                  ),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                  onTap: () async {
                    imageFile = await Extensions.getFromGallery();
                    if (imageFile != null) {
                      setState(() {
                        showFileForImage = true;
                      });
                    }
                  },
                  child: Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          fit: BoxFit.cover,
                          image: (showFileForImage)
                              ? FileImage(imageFile!) as ImageProvider
                              : NetworkImage(imageLink)),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      color: Colors.redAccent,
                    ),
                  )))
        ],
      ),
    );
  }

  Widget mSafeArea(BuildContext context, List<Widget> children) {
    return SafeArea(
        child: Container(
            width: MediaQuery.of(context).size.width / 3 - 16,
            height: 70,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            )).paddingSymmetric(horizontal: 8));
  }

  Widget saveProfile(BuildContext context) {
    return ElevatedButton(
      child: Row(children: [
        Image.asset(
          "images/socialv/icons/save-pngrepo-com.png",
          width: 18,
          height: 18,
          color: appStore.isDarkMode ? Colors.white : null,
        ).paddingRight(6),
        Text(
          s.saveProfile,
          style: TextStyle(color: appStore.isDarkMode ? Colors.white : null),
        )
      ], mainAxisSize: MainAxisSize.min),
      onPressed: () => {saveInfos()},
    ).paddingTop(8);
  }

  Widget accountInfo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: aboutContainerColor,
          ),
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: aboutContainerColor),
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: new List.from([
          Center(
            child: infoItem("images/socialv/icons/ic_about.png", s.about, "",
                null, (details) {},
                center: true),
          )
        ])
          ..addAll(infosLay(context)),
      ).paddingBottom(12),
    ).paddingTop(32).paddingSymmetric(horizontal: 32);
  }

  List<Widget> infosLay(BuildContext context) {
    return [
      infoItem("images/socialv/icons/gender-pngrepo-com.png", s.gender + ": ",
          s.yourGender, gender, (details) {
        _showPopupMenu(details.globalPosition);
      }),
      infoItem("images/socialv/icons/birthday-card-pngrepo-com.png",
          s.birthday + ": ", s.yourBirthday, birthday, (details) {
        showDatePickerDialog();
      }),
      infoItem("images/socialv/icons/location-pngrepo-com.png",
          s.location + ": ", s.yourLocation, location, (details) {
        Extensions.showLocationDialog(context, ((locationArg) {
          setState(() {
            locationVal = locationArg;
            if (locationVal != null) {
              location = locationVal!.city +
                  ((locationVal!.city.length != 0) ? ", " : "") +
                  locationVal!.state +
                  ((locationVal!.state.length != 0) ? ", " : "") +
                  locationVal!.country;
            }
          });
        }));
      }),
      saveProfile(context),
    ];
  }

  showDatePickerDialog() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2100));

    if (pickedDate != null) {
      print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('dd MM yyyy').format(pickedDate);
      print(
          formattedDate); //formatted date output using intl package => 2021-03-16
      setState(() {
        birthday = formattedDate; //set output date to TextField value.
      });
    } else {}
  }

  void _showPopupMenu(Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    final screenSize = MediaQuery.of(context).size;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, screenSize.width - offset.dx,
          screenSize.height - offset.dy),
      items: [
        PopupMenuItem(
          value: 1,
          child: Text(s.male),
        ),
        PopupMenuItem(
          value: 2,
          child: Text(s.female),
        ),
        PopupMenuItem(
          value: 3,
          child: Text(s.ratherNotSay),
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      setState(() {
        switch (value) {
          case 1:
            gender = s.male;
            break;
          case 2:
            gender = s.female;
            break;
          case 3:
            gender = "";
            break;
          default:
        }
      });
    });
  }

  Widget infoItem(String iconPath, String title, String hint, String? content,
      Function(TapDownDetails details) onClick,
      {bool center = false}) {
    return Row(children: [
      Image.asset(
        iconPath,
        width: 25,
        color: Theme.of(context).disabledColor,
      ).paddingRight(8).paddingLeft((center) ? 0 : 16),
      Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      (content != null)
          ? SizedBox(
              width: MediaQuery.of(context).size.width * 5 / 13,
              child: GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    onClick(details);
                  },
                  child: Flex(
                    direction: Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                          child: Text((content.length == 0) ? hint : content,
                                  style: TextStyle(fontSize: 16))
                              .paddingSymmetric(horizontal: 8)),
                    ],
                  )))
          : SizedBox()
    ], mainAxisSize: (center) ? MainAxisSize.min : MainAxisSize.max)
        .paddingTop(16);
  }

  saveInfos() async {
    if (showFileForBgImage) {
      //download bg image to firestore
      await firestoreService
          .downloadImage(bgImageFile!, "bgImages/${userModel?.id}")
          .then((downloadUrl) => {
                if (downloadUrl != null) {bgImageLink = downloadUrl}
              });
    }

    if (showFileForImage) {
      //download image to firestore
      await firestoreService
          .downloadImage(imageFile!, "images/${userModel?.id}")
          .then((downloadUrl) => {
                if (downloadUrl != null) {imageLink = downloadUrl}
              });
    }

    firestoreService.updateUserData(userModel!.id, {
      "name": nameController.text,
      "bio": bioController.text,
      "ppUrl": imageLink,
      "bgUrl": bgImageLink,
      "gender": gender,
      "birthDay": birthday,
      "location": (locationVal == null)
          ? userModel!.location.toJson()
          : locationVal!.toJson()
    }).then((success) => {
          if (success)
            {
              Navigator.pop(context, () {
                initState();
              }),
              showToast(s.yourInfoChanged)
            }
          else
            {showToast(s.sthWentWrong)}
        });
  }
}
