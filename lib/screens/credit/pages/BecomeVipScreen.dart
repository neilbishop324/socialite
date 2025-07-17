import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/VipPackage.dart';
import 'package:prokit_socialv/screens/confession/widgets/Loading.dart';
import 'package:prokit_socialv/screens/credit/logic/in_app_service.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';

import '../../../main.dart';
import '../../../utils/SVCommon.dart';
import '../../../utils/Translations.dart';

class BecomeVipScreen extends StatefulWidget {
  const BecomeVipScreen({Key? key}) : super(key: key);

  @override
  State<BecomeVipScreen> createState() => _BecomeVipScreenState();
}

class _BecomeVipScreenState extends State<BecomeVipScreen> {
  final oppositeColor = (appStore.isDarkMode) ? white : black;
  final s = Translations();
  final InAppService inAppService = InAppService();
  List<Color> darkColors = [
    Color(0xff214559),
    Color(0xff00626f),
    Color(0xff00022e),
    Color(0xff11574a),
    Color(0xff033500),
    Color(0xff004953),
    Color(0xff11887b),
    Color(0xff696006),
  ];

  InAppPurchase _connection = InAppPurchase.instance;

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
      debugPrint(error);
      showToast(error.toString());
    });
    initStoreInfo();
  }

  bool purchasePending = false;

  _buyProduct(String id) {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: _products.firstWhere((element) => element.id == id),
      );
      _connection.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      FirestoreService().logData({"error": e.toString()});
    }
  }

  _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          purchasePending = true;
        });
      } else {
        setState(() {
          purchasePending = false;
        });
        if (purchaseDetails.status == PurchaseStatus.error) {
          showToast(s.purchaseError);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          showToast(s.purchaseSuccess);
          final package = packages
              .firstWhere((element) => element.id == purchaseDetails.productID);
          await inAppService.makeUserVip(package);
          setState(() {});
        }
      }
    });
  }

  List<VipPackage> packages = [];

  initStoreInfo() async {
    packages = await inAppService.getVipPackages();
    setState(() {});
    bool available = await _connection.isAvailable();
    if (available) {
      ProductDetailsResponse productDetailResponse;
      productDetailResponse = await _connection.queryProductDetails(
        packages.map((e) => e.id).toSet(),
      );
      if (productDetailResponse.error == null) {
        setState(() {
          _products = productDetailResponse.productDetails;
        });
        await FirestoreService().logData({
          "products": _products.map((e) => e.id).toList(),
          "notFoundIds": productDetailResponse.notFoundIDs,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.becomeVip,
          style: TextStyle(color: oppositeColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: oppositeColor),
      ),
      body: Column(
        children: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection(CollectionPath().users)
                .doc(AuthService().getUid())
                .collection(CollectionPath().additionalInfo)
                .doc(CollectionPath().additionalInfo + "2")
                .snapshots(),
            builder: (context,
                AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                    snapshot) {
              if (snapshot.data?.exists == true && snapshot.data?['isValid']) {
                return Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  color: appStore.isDarkMode
                      ? white
                      : Color.fromARGB(255, 104, 104, 104),
                  child: Text(
                    s.youAreVip,
                    style: TextStyle(
                        color: appStore.isDarkMode ? black : white,
                        fontSize: 16),
                  ).paddingSymmetric(horizontal: 8, vertical: 16),
                ).cornerRadiusWithClipRRect(10).paddingAll(16);
              }
              return SizedBox();
            },
          ),
          purchasePending
              ? Loading()
              : packages.isEmpty
                  ? Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            s.noPackages,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : MasonryGridView.builder(
                      shrinkWrap: true,
                      itemCount: packages.length,
                      gridDelegate:
                          SliverSimpleGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2),
                      itemBuilder: (context, index) {
                        return vip(context, packages[index]);
                      },
                    ).paddingAll(6),
        ],
      ),
    );
  }

  Widget vip(BuildContext context, VipPackage package) {
    return InkWell(
      onTap: () => _vipPurchase(package),
      child: Container(
        color: darkColors[(package.id.hashCode) % darkColors.length],
        child: Column(
          children: [
            Image.network(
              package.iconLink,
              height: 150,
            ).paddingSymmetric(vertical: 3, horizontal: 6),
            Text(
              package.name,
              style: TextStyle(
                color: white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ).paddingSymmetric(vertical: 3, horizontal: 6),
            Text(
              '₺${package.price}',
              style: TextStyle(color: white),
            ).paddingSymmetric(vertical: 3, horizontal: 6),
            Text(
              '${package.period} ${inAppService.translatePeriod(package.periodType)} ${s.period}',
              style: TextStyle(color: white),
            ).paddingSymmetric(vertical: 3, horizontal: 6),
          ],
        ).paddingSymmetric(vertical: 3),
      ),
    ).cornerRadiusWithClipRRect(12).paddingAll(8);
  }

  _vipPurchase(VipPackage package) {
    _buyProduct(package.id);
  }
}
