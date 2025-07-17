import 'package:prokit_socialv/utils/Translations.dart';

class SVDrawerModel {
  String? title;
  String? image;

  SVDrawerModel({this.image, this.title});
}

List<SVDrawerModel> getDrawerOptions() {
  List<SVDrawerModel> list = [];
  final s = Translations();

  list.add(SVDrawerModel(
      image: 'images/socialv/icons/ic_Profile.png', title: s.profile));
  list.add(SVDrawerModel(
      image: 'images/socialv/icons/ic_2User.png', title: s.followings));
  list.add(SVDrawerModel(
      image: 'images/socialv/icons/ic_3User.png', title: s.groups));
  list.add(SVDrawerModel(
      image: 'images/socialv/icons/youtube-tv-svgrepo-com.png',
      title: s.liveStreams));
  list.add(SVDrawerModel(
      image: 'images/socialv/icons/ic_Document.png', title: s.savedPosts));
  list.add(SVDrawerModel(
      image: 'images/socialv/icons/vip-pngrepo-com.png', title: s.becomeVip));
  list.add(SVDrawerModel(
      image: 'images/socialv/icons/credit-pngrepo-com.png',
      title: s.purchaseCredit));
  list.add(SVDrawerModel(
      image: 'images/socialv/icons/ic_Send.png', title: s.shareApp));
  list.add(SVDrawerModel(
      image: 'images/socialv/icons/ic_Logout.png', title: s.logout));

  return list;
}
