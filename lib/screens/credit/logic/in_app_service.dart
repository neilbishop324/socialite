import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/CreditPackage.dart';
import 'package:prokit_socialv/model/Gift.dart';
import 'package:prokit_socialv/model/VipPackage.dart';
import 'package:prokit_socialv/screens/confession/widgets/Loading.dart';
import 'package:prokit_socialv/screens/credit/pages/PurchasePackageScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../main.dart';
import '../../../service/message_service.dart';
import '../../../utils/SVConstants.dart';

class InAppService {
  final _firestore = FirebaseFirestore.instance;
  final s = Translations();

  Future<List<VipPackage>> getVipPackages() async {
    try {
      final packagesRef = _firestore
          .collection(CollectionPath().vipPackages)
          .withConverter<VipPackage>(
            fromFirestore: (snapshot, _) =>
                VipPackage.fromMap(snapshot.data()!),
            toFirestore: (vipPackage, _) => vipPackage.toMap(),
          );

      List<QueryDocumentSnapshot<VipPackage>> vipPackages =
          await packagesRef.get().then((value) => value.docs);
      return vipPackages.map((e) => e.data()).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<CreditPackage>> getCreditPackages() async {
    try {
      final packagesRef = _firestore
          .collection(CollectionPath().creditPackages)
          .orderBy('id')
          .withConverter<CreditPackage>(
            fromFirestore: (snapshot, _) =>
                CreditPackage.fromMap(snapshot.data()!),
            toFirestore: (creditPackage, _) => creditPackage.toMap(),
          );

      List<QueryDocumentSnapshot<CreditPackage>> creditPackages =
          await packagesRef.get().then((value) => value.docs);
      return creditPackages.map((e) => e.data()).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<int> getCurrentUserCreditCount() async {
    try {
      final userId = AuthService().getUid();
      final snaphot = await _firestore
          .collection(CollectionPath().users)
          .doc(userId)
          .collection(CollectionPath().additionalInfo)
          .doc(CollectionPath().additionalInfo)
          .get();
      if (snaphot.exists && snaphot.data()?['creditCount'] != null) {
        return snaphot.data()!['creditCount'] as int;
      }
      await _firestore
          .collection(CollectionPath().users)
          .doc(userId)
          .collection(CollectionPath().additionalInfo)
          .doc(CollectionPath().additionalInfo)
          .set({'creditCount': 0});
    } catch (e) {
      print(e);
    }
    return 0;
  }

  Future<void> setCurrentUserCreditCount(int add) async {
    try {
      final userId = AuthService().getUid();
      final snaphot = await _firestore
          .collection(CollectionPath().users)
          .doc(userId)
          .collection(CollectionPath().additionalInfo)
          .doc(CollectionPath().additionalInfo)
          .get();
      if (snaphot.exists && snaphot.data()?['creditCount'] != null) {
        await _firestore
            .collection(CollectionPath().users)
            .doc(userId)
            .collection(CollectionPath().additionalInfo)
            .doc(CollectionPath().additionalInfo)
            .update({"creditCount": FieldValue.increment(add)});
      } else {
        await _firestore
            .collection(CollectionPath().users)
            .doc(userId)
            .collection(CollectionPath().additionalInfo)
            .doc(CollectionPath().additionalInfo)
            .set({'creditCount': add});
      }
    } catch (e) {
      print(e);
    }
  }

  String translatePeriod(String period) {
    bool tr = WidgetsBinding.instance.window.locale.countryCode
            .toString()
            .toLowerCase() ==
        'tr';
    if (!tr) return period;
    switch (period) {
      case 'day':
        return 'gün';
      case 'week':
        return 'hafta';
      case 'month':
        return 'ay';
      case 'year':
        return 'yıl';
      default:
        return 'kadar zaman';
    }
  }

  showSendGiftDialog(
    BuildContext context,
    String userId, {
    String? confessionId,
    String? channelId,
  }) async {
    final oppositeColor = (appStore.isDarkMode) ? white : black;
    var creditCount = 0;
    Dialog giftDialog = Dialog(
      backgroundColor: svGetScaffoldColor().withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        height: 500.0,
        width: MediaQuery.of(context).size.width * 9 / 10,
        padding: EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            Stack(
              children: [
                Container(
                    alignment: Alignment.center,
                    child: Text(
                      s.giveGift,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )),
                Container(
                  child: FutureBuilder(
                    future: getCurrentUserCreditCount(),
                    builder: (context, AsyncSnapshot<int> snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Container();
                      }
                      creditCount = snapshot.data!;
                      return Container(
                        child: Row(
                          children: [
                            Container(
                              color: gold,
                              height: 18,
                              width: 18,
                            ).cornerRadiusWithClipRRect(20).paddingAll(4),
                            Text(
                              creditCount.toString(),
                              style: TextStyle(color: oppositeColor),
                            ).paddingOnly(right: 12, top: 4, bottom: 4)
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => finish(context),
                    child: Icon(
                      Icons.close,
                      color: white,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder(
                future: getGifts(),
                builder: (context, AsyncSnapshot<List<Gift>> snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Loading();
                  }
                  return MasonryGridView.builder(
                    itemCount: snapshot.data!.length,
                    gridDelegate:
                        SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsetsDirectional.all(3),
                        child: InkWell(
                          onTap: () async {
                            await sendGift(
                                context, snapshot.data![index], userId,
                                channelId: channelId,
                                confessionId: confessionId);
                          },
                          child: Column(
                            children: [
                              Image.network(
                                snapshot.data![index].mediaFileLink,
                              ),
                              Row(
                                children: [
                                  Container(
                                    color: gold,
                                    height: 18,
                                    width: 18,
                                  ).cornerRadiusWithClipRRect(20).paddingAll(4),
                                  Text(
                                    snapshot.data![index].creditCount
                                        .toString(),
                                    style: TextStyle(color: oppositeColor),
                                  ).paddingOnly(right: 12, top: 4, bottom: 4)
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            normalButton(
                icon: Icons.add,
                fontSize: 13,
                text: s.purchaseCredit,
                onPressed: () => PurchasePackageScreen().launch(context)),
          ],
        ),
      ),
    );
    showDialog(context: context, builder: (BuildContext context) => giftDialog);
  }

  Future<List<Gift>> getGifts() async {
    try {
      final giftsRef = _firestore
          .collection(CollectionPath().gifts)
          .orderBy('creditCount')
          .withConverter<Gift>(
            fromFirestore: (snapshot, _) => Gift.fromMap(snapshot.data()!),
            toFirestore: (gift, _) => gift.toMap(),
          );

      List<QueryDocumentSnapshot<Gift>> gifts =
          await giftsRef.get().then((value) => value.docs);
      return gifts.map((e) => e.data()).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  makeUserVip(VipPackage package) async {
    final userId = AuthService().getUid();
    await _firestore
        .collection(CollectionPath().users)
        .doc(userId)
        .collection(CollectionPath().additionalInfo)
        .doc(CollectionPath().additionalInfo + "2")
        .set({
      "startedAt": DateTime.now(),
      "package": package.toMap(),
      "isValid": true
    });
    String? chatUserToken =
        (userId == null) ? null : await FirestoreService().getUserToken(userId);
    if (chatUserToken != null) {
      sendPushMessage(chatUserToken, s.nowYouAreVip, s.congrats);
    }
  }

  Future<void> sendGift(BuildContext context, Gift gift, String receiverId,
      {String? channelId, String? confessionId}) async {
    showConfirmDialog(context, s.doYouWantToSendGift(gift.name),
        onAccept: () async {
      try {
        final senderId = AuthService().getUid();
        final snapshot = await _firestore
            .collection(CollectionPath().users)
            .doc(senderId)
            .collection(CollectionPath().additionalInfo)
            .doc(CollectionPath().additionalInfo)
            .get();
        if (!snapshot.exists ||
            snapshot.data() == null ||
            (snapshot.data()!['creditCount'] as int) < gift.creditCount) {
          showToast(s.dontHaveEnoughCredit);
          return;
        }
        if (senderId == receiverId) {
          showToast(s.cantSendGiftToYourself);
        }
        await _firestore
            .collection(CollectionPath().users)
            .doc(senderId)
            .collection(CollectionPath().additionalInfo)
            .doc(CollectionPath().additionalInfo)
            .update(
                {'creditCount': FieldValue.increment(-1 * gift.creditCount)});
        await _firestore
            .collection(CollectionPath().users)
            .doc(receiverId)
            .collection(CollectionPath().additionalInfo)
            .doc(CollectionPath().additionalInfo)
            .update({'creditCount': FieldValue.increment(gift.creditCount)});
        final currentUser = await FirestoreService().getUser(senderId);
        String? chatUserToken =
            await FirestoreService().getUserToken(receiverId);
        if (chatUserToken != null) {
          sendPushMessage(
              chatUserToken,
              "${currentUser?.name} ${s.sendYouGift}",
              s.giftFromSomeone(currentUser?.name, gift.name));
        }
        if (confessionId != null) {
          await _firestore
              .collection(CollectionPath().confessions)
              .doc(confessionId)
              .update({'giftCount': FieldValue.increment(1)});
        }
        if (channelId != null) {
          await FirestoreService().addCommentToLivestream(
              s.giftFromSomeone(currentUser?.name, gift.name),
              channelId,
              context,
              currentUser,
              isGift: true);
        }
        showToast(s.giftSentSuccess);
      } on FirebaseException catch (e) {
        print(e);
        showToast(e.message!);
      }
    });
  }
}
