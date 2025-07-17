import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/CreditPackage.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';

import '../../../main.dart';
import '../../../utils/Translations.dart';
import '../../confession/widgets/Loading.dart';
import '../logic/in_app_service.dart';

class PurchasePackageScreen extends StatefulWidget {
  const PurchasePackageScreen({Key? key}) : super(key: key);

  @override
  State<PurchasePackageScreen> createState() => PurchasePackageScreenState();
}

class PurchasePackageScreenState extends State<PurchasePackageScreen> {
  final oppositeColor = (appStore.isDarkMode) ? white : black;
  final s = Translations();
  final InAppService inAppService = InAppService();

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
    final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: _products.firstWhere((element) => element.id == id));
    _connection.buyConsumable(purchaseParam: purchaseParam);
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
          await inAppService.setCurrentUserCreditCount(package.creditCount);
          setState(() {});
        }
      }
    });
  }

  List<CreditPackage> packages = [];

  initStoreInfo() async {
    packages = await inAppService.getCreditPackages();
    setState(() {});
    ProductDetailsResponse productDetailResponse = await _connection
        .queryProductDetails(packages.map((e) => e.id).toSet());
    if (productDetailResponse.error == null) {
      setState(() {
        _products = productDetailResponse.productDetails;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.purchaseCredit,
          style: TextStyle(color: oppositeColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: oppositeColor),
        actions: [
          FutureBuilder(
            future: inAppService.getCurrentUserCreditCount(),
            builder: (context, AsyncSnapshot<int> snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return Container();
              }
              return Container(
                child: Row(
                  children: [
                    Container(
                      color: gold,
                      height: 18,
                      width: 18,
                    ).cornerRadiusWithClipRRect(20).paddingAll(4),
                    Text(
                      snapshot.data!.toString(),
                      style: TextStyle(color: oppositeColor),
                    ).paddingOnly(right: 12, top: 4, bottom: 4)
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: purchasePending
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
              : ListView.builder(
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    return creditPackage(context, packages[index]);
                  },
                ).paddingAll(6),
    );
  }

  Widget creditPackage(BuildContext context, CreditPackage package) {
    Color bgColor = appStore.isDarkMode
        ? Color(0xff212121)
        : Color.fromARGB(255, 219, 217, 217);
    return InkWell(
      onTap: () => _buyProduct(package.id),
      child: Container(
        color: bgColor,
        child: Row(
          children: [
            Text(
              '${package.creditCount} ${s.credit}',
              style: TextStyle(fontSize: 17),
            ).paddingAll(30),
            Spacer(),
            Text(
              '₺${package.price}',
              style: TextStyle(fontSize: 15),
            ).paddingAll(30)
          ],
        ),
      ),
    ).cornerRadiusWithClipRRect(20).paddingAll(12);
  }
}
