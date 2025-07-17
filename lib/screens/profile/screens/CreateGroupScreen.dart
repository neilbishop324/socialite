import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/Group.dart';
import 'package:prokit_socialv/screens/profile/screens/ShowGroupScreen.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../main.dart';
import '../../../service/auth.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  int _currentStep = 0;
  Color cancelTextColor = (appStore.isDarkMode)
      ? Color.fromARGB(255, 184, 184, 184)
      : Color.fromARGB(255, 144, 145, 145);
  final oppositeColor = (appStore.isDarkMode) ? white : black;

  Color coverPhotoLayColor = appStore.isDarkMode
      ? Color.fromARGB(255, 44, 45, 49)
      : Color.fromARGB(255, 221, 221, 225);

  final _groupName = TextEditingController();
  final _description = TextEditingController();
  bool _validateGroupName = false;

  File? imageFile;
  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create a Group',
          style: TextStyle(color: oppositeColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: oppositeColor),
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: Stepper(
                type: StepperType.horizontal,
                physics: ScrollPhysics(),
                currentStep: _currentStep,
                onStepTapped: (step) => tapped(step),
                controlsBuilder: (context, details) {
                  return Row(children: [
                    normalButton(text: s.continue0, onPressed: continued)
                        .paddingRight(16),
                    InkWell(
                      onTap: cancel,
                      child: Text(
                        s.previous,
                        style: TextStyle(color: cancelTextColor),
                      ).paddingAll(16),
                    ),
                  ]).paddingSymmetric(vertical: 16, horizontal: 8);
                },
                steps: <Step>[
                  Step(
                    title: Text(
                      _currentStep == 0 ? s.name : "",
                      style: TextStyle(color: oppositeColor),
                    ),
                    isActive: _currentStep >= 0,
                    state: _currentStep >= 0
                        ? StepState.complete
                        : StepState.disabled,
                    content: Column(
                      children: <Widget>[
                        TextFormField(
                          style: TextStyle(color: oppositeColor),
                          onChanged: (value) {
                            setState(() {
                              _validateGroupName = value.isEmpty;
                            });
                          },
                          controller: _groupName,
                          decoration: InputDecoration(
                            labelText: s.groupName,
                            labelStyle: TextStyle(color: oppositeColor),
                            errorText: _validateGroupName
                                ? s.groupName + ' ' + s.cantBeEmpty
                                : null,
                          ),
                        )
                      ],
                    ),
                  ),
                  Step(
                    title: Text(
                      _currentStep == 1 ? s.desc : "",
                      style: TextStyle(color: oppositeColor),
                    ),
                    isActive: _currentStep >= 1,
                    state: _currentStep >= 1
                        ? StepState.complete
                        : StepState.disabled,
                    content: Column(
                      children: <Widget>[
                        TextFormField(
                          style: TextStyle(color: oppositeColor),
                          controller: _description,
                          decoration: InputDecoration(
                            labelText: s.descYourGroup,
                            labelStyle: TextStyle(color: oppositeColor),
                          ),
                        )
                      ],
                    ),
                  ),
                  Step(
                    title: new Text(
                      _currentStep == 2 ? s.coverPhoto : "",
                      style: TextStyle(color: oppositeColor),
                    ),
                    content: Column(
                      children: <Widget>[
                        Container(
                          color: coverPhotoLayColor,
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.width / 2,
                          child: (imageFile == null)
                              ? Align(
                                  child: normalButton(
                                      icon: Icons.upload,
                                      text: s.uploadImage,
                                      onPressed: () async {
                                        final imagePath =
                                            await handleImageSelection();
                                        if (imagePath != null) {
                                          setState(() {
                                            imageFile = File(imagePath);
                                          });
                                        }
                                      }))
                              : GestureDetector(
                                  onTap: () async {
                                    final imagePath =
                                        await handleImageSelection();
                                    if (imagePath != null) {
                                      setState(() {
                                        imageFile = File(imagePath);
                                      });
                                    }
                                  },
                                  child: Image.file(imageFile!)),
                        ).cornerRadiusWithClipRRect(SVAppCommonRadius)
                      ],
                    ),
                    isActive: _currentStep >= 0,
                    state: _currentStep >= 2
                        ? StepState.complete
                        : StepState.disabled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  tapped(int step) {
    setState(() => _currentStep = step);
  }

  continued() {
    switch (_currentStep) {
      case 0:
        setState(() {
          _validateGroupName = _groupName.text.isEmpty;
        });
        if (!_validateGroupName) {
          continueForButton();
        }
        break;
      default:
        continueForButton();
    }
  }

  continueForButton() {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    } else {
      _createGroup();
    }
  }

  cancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _createGroup() async {
    final name = _groupName.text;
    late String ppUrl;
    final id = Extensions.generateRandomString(15);
    if (imageFile == null) {
      ppUrl = SVConstants.groupImageLinkDefault;
    } else {
      ppUrl =
          await FirestoreService().downloadImage(imageFile!, "groups/$id") ??
              SVConstants.groupImageLinkDefault;
    }
    final bgUrl = SVConstants.backgroundLinkDefault;
    final description = _description.text;
    final adminId = AuthService().getUid();
    if (adminId == null) {
      return;
    }
    final group = Group(
            name: name,
            ppUrl: ppUrl,
            bgUrl: bgUrl,
            description: description,
            id: id,
            adminId: adminId)
        .toJson();
    final success =
        await FirestoreService().setData(CollectionPath().groups, id, group);
    if (success) {
      final success2 = await FirestoreService().setData(
          "${CollectionPath().groups}/$id/${CollectionPath().members}",
          adminId,
          {"id": adminId});
      if (success2) {
        showToast(s.gsCreated);
        finish(context);
        ShowGroupScreen(groupId: id).launch(context);
      }
    }
  }
}
