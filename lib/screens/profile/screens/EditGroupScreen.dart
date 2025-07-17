import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/Group.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../main.dart';
import '../../../utils/Extensions.dart';
import '../../../utils/SVCommon.dart';
import '../../../utils/SVConstants.dart';

class EditGroupScreen extends StatefulWidget {
  const EditGroupScreen({Key? key, this.group}) : super(key: key);
  final Group? group;

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState(group);
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  _EditGroupScreenState(this.group);
  final Group? group;

  final firestoreService = FirestoreService();

  @override
  void initState() {
    if (group != null) {
      _nameController.text = group!.name;
      _descriptionController.text = group!.description;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
            backgroundColor: svGetScaffoldColor(),
            title: Text(s.editGroup, style: boldTextStyle(size: 20)),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: context.iconColor)),
        body: bodyWidget(context),
      ),
    );
  }

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

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
                    controller: _nameController,
                    decoration: svInputDecoration(
                      context,
                      label: s.groupName,
                      labelStyle: secondaryTextStyle(
                          weight: FontWeight.w600, color: svGetBodyColor()),
                    )).paddingSymmetric(horizontal: 16),
                bioLayout(context),
                actionButtons(context)
              ],
            ).paddingBottom(32))));
  }

  Widget bioLayout(BuildContext context) {
    return AppTextField(
        textFieldType: TextFieldType.MULTILINE,
        controller: _descriptionController,
        decoration: svInputDecoration(
          context,
          label: s.groupDesc,
          labelStyle: secondaryTextStyle(
              weight: FontWeight.w600, color: svGetBodyColor()),
        )).paddingSymmetric(horizontal: 16).paddingTop(12);
  }

  File? bgImageFile;
  bool showFileForBgImage = false;
  File? imageFile;
  bool showFileForImage = false;

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
                    group?.bgUrl ?? SVConstants.backgroundLinkDefault,
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
                              : NetworkImage(group?.ppUrl ??
                                  SVConstants.groupImageLinkDefault)),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      color: Colors.redAccent,
                    ),
                  )))
        ],
      ),
    );
  }

  Widget actionButtons(BuildContext context) {
    return Column(
      children: [
        normalButton(
            text: s.deleteGroup,
            onPressed: () {
              _deleteGroup();
            },
            icon: Icons.delete),
        normalButton(
                text: s.save2,
                onPressed: () {
                  _saveInfos();
                },
                icon: Icons.save)
            .paddingTop(16)
      ],
    ).paddingTop(24);
  }

  final db = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance.ref();
  final s = Translations();

  void _deleteGroup() async {
    Extensions().showAlertDialog(
        context, s.deleteGroup, s.deleteGroupDet, s.yes, () async {
      if (group != null) {
        String groupId = group!.id;
        final a1 =
            await firestoreService.deleteData(CollectionPath().groups, groupId);
        if (!a1) {
          showToast(s.sthWentWrong);
          return;
        }
        final a2 = await firestoreService.firebaseExceptionHandler(() async {
          final ids = await firestoreService.getPostsWithQuery(groupId);
          for (String id in ids) {
            await firestoreService.deleteData(CollectionPath().posts, id);
          }
        });
        if (!a2) {
          showToast(s.sthWentWrong);
          return;
        }

        final a3 = await firestoreService.deleteData(
            CollectionPath().groups + "/" + groupId, groupId);

        if (!a3) {
          showToast(s.sthWentWrong);
          return;
        }

        final imageRef = storage.child("groups/$groupId");

        await imageRef.delete();

        final bgImageRef = storage.child("groupBgImages/$groupId");

        await bgImageRef.delete();

        finish(context);
        finish(context);
        showToast(s.groupDeleted);
      } else {
        showToast(s.sthWentWrong);
      }
    });
  }

  void _saveInfos() async {
    String? bgImageLink;
    String? imageLink;
    if (showFileForBgImage) {
      //download bg image to firestore
      await firestoreService
          .downloadImage(bgImageFile!, "groupBgImages/${group?.id}")
          .then((downloadUrl) => {
                if (downloadUrl != null) {bgImageLink = downloadUrl}
              });
    }

    if (showFileForImage) {
      //download image to firestore
      await firestoreService
          .downloadImage(imageFile!, "groups/${group?.id}")
          .then((downloadUrl) => {
                if (downloadUrl != null) {imageLink = downloadUrl}
              });
    }

    final success =
        await firestoreService.updateData(CollectionPath().groups, group?.id, {
      "name": _nameController.text,
      "description": _descriptionController.text,
      "ppUrl": imageLink ?? group?.ppUrl,
      "bgUrl": bgImageLink ?? group?.bgUrl
    });

    if (success) {
      finish(context);
      showToast(s.groupInfoSaved);
    }
  }
}
