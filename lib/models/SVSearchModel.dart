class SVSearchModel {
  String? name;
  String? profileImage;
  String? subTitle;
  bool? isOfficialAccount;
  bool? doSend;
  String id;

  SVSearchModel(
      {this.name,
      this.profileImage,
      this.subTitle,
      this.isOfficialAccount,
      this.doSend, required this.id});
}
