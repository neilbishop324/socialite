import 'package:flutter/cupertino.dart';

class Translations {
  late bool tr;
  late String messages, members, uramNow;
  late String deletedAccount, addPost, leaveGroup;
  late String profile, join, dywtltg;
  late String followings, deletedGroup, youLeavedTheGroup;
  late String groups, group, pDeleted;
  late String savedPosts, groupMembers, yourGroups;
  late String shareApp, groupInfoSaved, createaGroup;
  late String logout, groupDeleted, joinGroups;
  late String today, deleteGroupDet, groupsYouManage;
  late String thisWeek, save2, others;
  late String thisMonth, deleteGroup, home;
  late String earlier, groupDesc;
  late String sMinute, editGroup;
  late String sHour, yourInfoChanged;
  late String sDay, ratherNotSay;
  late String recently, female;
  late String minutes, male;
  late String hours, yourLocation, viewers;
  late String days, yourBirthday;
  late String writeaComment, yourGender;
  late String searchHere, about;
  late String send, saveProfile;
  late String sharedaPost, yourBio;
  late String sthWentWrong, editYourProfile;
  late String welcomeBack, gsCreated;
  late String moreWelcome, uploadImage;
  late String show, coverPhoto;
  late String password, desc, descYourGroup;
  late String rememberMe, groupName;
  late String forgetPassword, previous;
  late String login, continue0;
  late String dontHaveAccount, followedYou;
  late String orContinueWith, likedYourPost;
  late String helloUser, photo, sharedanImage;
  late String name, typeYourMessage, youAreVip;
  late String username, comments2, nowYouAreVip, congrats;
  late String signUp, incompleteInfo;
  late String alreadyHaveAccount, yourName;
  late String forgetPassDetail, cantBeEmpty;
  late Function(String) doYouWantToSendGift;
  late String enterYourEmail, postFile;
  late String getMail, cancel, showLocInfo, sendYouGift, cantSendGiftToYourself;
  late String backToLogin, errorMes4;
  late String newPost, errorMes2, errorMes3, dontHaveEnoughCredit;
  late String newStory, ctrlInbox, loading, giftSentSuccess;
  late String postSuccSub, niInformation, purchaseCredit;
  late String selectPhoto, ymhbSent, imageFile, purchaseSuccess;
  late String writeaCaption, sharedaStory, like, period, purchaseError;
  late String notifications, sendMessage, becomeVip;
  late Function(String?, String?) giftFromSomeone;
  late String unblock, reply, ago, errorMes1;
  late String block, posts, report, giveGift, noStreams;
  late String usReported, pReported, psSaved, psUnsaved;
  late String usBlocked, person, people, descRequired, noPackages;
  late String usUnblocked, myPosts, sPosts, successConfess;
  late String followers, myFollowers, you, share, noComments;
  late String sFollowers, myFollowings, sFollowings, makeAConfession;
  late String birthday, gender, location, thereIsNoConfession;
  late String editProfile, comments, save, unsave, thereIsNoNotification;
  late String deleteAccount, deleteAccDetails, yes, anonim, thisDataDeleted;
  late String deleteDetailDialog, delete, usDeleted, sopyf, streamType;
  late String recent, users, popyf, explore, postType, live;
  late String error, and, yourStory, ypsSubmitted, confession;
  late String errorMes5, errorMes6, errorMes7, errorMes8, endStream, credit;
  late String selectLoc, country, state, city, sCountry, sState, sCity;
  late String liveStreams, goLive, selectThumb, title, titleRequired;
  late String imageRequired, liveStreamSuccess, alreadyStreaming, confessions;
  late String switchCamera, unmute, mute, stopScreensharing, startScreensharing;

  Translations() {
    tr = WidgetsBinding.instance.window.locale.countryCode
            .toString()
            .toLowerCase() ==
        'tr';

    goLive = tr ? "Canlı Yayın Aç" : "Go Live";
    switchCamera = tr ? "Kamera Değiştir" : "Switch Camera";
    cantSendGiftToYourself = tr
        ? "Kendine hediye yollayamazsın!"
        : "You can't send gift to yourself!";
    thisDataDeleted = tr ? "Bu bilgi silindi" : "This data has been deleted";
    unmute = tr ? "Sesini Aç" : "Unmute";
    makeAConfession = tr ? "İtiraf Et" : "Make A Confession";
    share = tr ? "Paylaş" : "Share";
    becomeVip = tr ? "Vip Paket Al" : "Purchase Vip Package";
    sendYouGift = tr ? "sana hediye gönderdi" : "send you a gift";
    congrats = tr ? "Tebrikler!" : "Congratulation!";
    nowYouAreVip = tr ? "Artık Vip'sin" : "Now you are a Vip";
    mute = tr ? "Sessize Al" : "Mute";
    youAreVip = tr ? "Sen Vip sahibisin" : "You are a Vip";
    giftSentSuccess = tr
        ? "Hediye başarılı bir şekilde gönderildi!"
        : "Gift sent successfully!";
    dontHaveEnoughCredit =
        tr ? "Yeteri kadar kredin yok!" : "You don't have enough credit!";
    doYouWantToSendGift = (gift) => tr
        ? "Bu kişiye $gift göndermek istiyor musun"
        : "Do you want to send $gift to this person?";
    giftFromSomeone = (name, gift) {
      String article = 'a';
      if (gift?[0].toLowerCase() == 'a' ||
          gift?[0].toLowerCase() == 'e' ||
          gift?[0].toLowerCase() == 'i' ||
          gift?[0].toLowerCase() == 'o' ||
          gift?[0].toLowerCase() == 'u') {
        article = 'an';
      }
      return tr ? "$name'den bir $gift" : "$article $gift from $name";
    };
    purchaseError = tr
        ? "Ödemede bir sorunla karşılaştık.. Sonra tekrar deneyin"
        : "Something went wrong in purchase.. Please try again later";
    purchaseSuccess = tr
        ? "Ödeme başarıyla gerçekleşti"
        : "Payment has been made successfully";
    period = tr ? "kadar süreli" : "period";
    credit = tr ? "Kredi" : "Credit";
    noPackages = tr ? "Paket yok" : "No packages to display";
    noStreams = tr ? "Canlı yayın yok" : "No livestreams to display";
    live = tr ? "Canlı" : "Live";
    descRequired = tr ? "Açıklama gerekli!" : "Description is required";
    anonim = tr ? "Anonim" : "Anonymous";
    purchaseCredit = tr ? "Kredi Al" : "Purchase Credit";
    giveGift = tr ? "Hediye Ver" : "Give Gift";
    viewers = tr ? "İzleyici" : "Viewers";
    confession = tr ? "İtiraf" : "Confession";
    like = tr ? "Beğen" : "Like";
    noComments = tr ? "Yorum yok" : "No comments to display";
    successConfess = tr
        ? "İtirafın başarıyla yayınlandı"
        : "Your confession successfully submitted";
    confessions = tr ? "İtiraf Köşesi" : "Confessions";
    thereIsNoConfession = tr ? "İtiraf yok" : "No confession to display";
    thereIsNoNotification = tr ? "Bildirim yok" : "No notification to display";
    sopyf = tr
        ? "Takip ettiğin kişilerin yayınları"
        : "Streams of people you follow";
    streamType = tr ? "Yayın Türü" : "Stream Type";
    endStream = tr ? "Yayını Bitir" : "End Stream";
    stopScreensharing = tr ? "Ekran Paylaşımını Durdur" : "Stop Screen Sharing";
    startScreensharing =
        tr ? "Ekran Paylaşımını Başlat" : "Start Screen Sharing";
    alreadyStreaming =
        tr ? "Şuan zaten yayındasın" : "You are already streaming";
    title = tr ? "Başlık" : "Title";
    liveStreamSuccess = tr
        ? "Canlı yayın başarıyla başlatıldı"
        : "Livestream has started successfully";
    titleRequired = tr ? "Başlık gerekli" : "Title is required";
    imageRequired = tr ? "Küçük resim gerekli" : "Thumbnail is required";
    selectThumb = tr ? "Küçük resminizi seçin" : "Select your thumbnail";
    liveStreams = tr ? "Canlı yayınlar" : "Live Streams";
    messages = tr ? "Sohbetler" : "Messages";
    deletedAccount = tr ? "Silinmiş Hesap" : "DeletedAccount";
    profile = tr ? "Profil" : "Profile";
    followings = tr ? "Takip edilenler" : "Followings";
    groups = tr ? "Gruplar" : 'Groups';
    savedPosts = tr ? "Kaydedilen Postlar" : 'Saved Posts';
    shareApp = tr ? "Uygulamayı paylaş" : 'Share App';
    logout = tr ? "Çıkış yap" : 'Log Out';
    today = tr ? "BUGÜN" : 'TODAY';
    thisWeek = tr ? "BU HAFTA" : "THIS WEEK";
    thisMonth = tr ? "BU AY" : "THIS MONTH";
    earlier = tr ? "Daha Öncesi" : "Earlier";
    sMinute = tr ? "d" : "m";
    sHour = tr ? "sa" : "h";
    sDay = tr ? "g" : "d";
    recently = tr ? "yakın zamanda" : "recently";
    minutes = tr ? "dakika" : "minutes";
    hours = tr ? "saat" : "hours";
    days = tr ? "gün" : "days";
    writeaComment = tr ? "Bir yorum yaz" : 'Write A Comment';
    searchHere = tr ? "Ara" : 'Search Here';
    send = tr ? "Gönder" : 'Send';
    sharedaPost = tr ? "Bir post paylaştı" : "Shared a post";
    sthWentWrong = tr ? "Bir şeyler ters gitti.." : "Something went wrong..";
    welcomeBack = tr ? "Hoşgeldin!" : 'Welcome back!';
    moreWelcome = tr
        ? "Uzun zamandır özleniyorsunuz"
        : 'You Have Been Missed For Long Time';
    show = tr ? "Göster" : 'Show';
    password = tr ? "Şifre" : 'Password';
    rememberMe = tr ? "Beni Hatırla" : 'Remember Me';
    forgetPassword = tr ? "Şifremi unuttum" : 'Forget Password?';
    login = tr ? "GİRİŞ YAP" : 'LOGIN';
    dontHaveAccount = tr ? "Hesabın mı yok?" : 'Don’t Have An Account?';
    orContinueWith = tr ? "Veya ile devam et" : 'Or Continue With';
    helloUser = tr ? "Merhaba" : 'Hello User';
    name = tr ? "İsim" : 'Name';
    username = tr ? "Kullanıcı adı" : 'Username';
    signUp = tr ? "Üye Ol" : 'Sign Up';
    alreadyHaveAccount =
        tr ? "Zaten hesabın var mı?" : 'Already Have An Account?';
    forgetPassDetail = tr
        ? "Şifreni Sıfırlama Emaili Almak İçin \n Hesabınla Uyuşan Emaili Gir"
        : 'Enter The email Associated With Your \n Account To Receive A Reset Password Mail';
    enterYourEmail = tr ? "Email'ini gir" : 'Enter Your Email';
    getMail = tr ? "SIFIRLAMA EMAİLİ AL" : 'GET MAIL';
    backToLogin = tr ? "Giriş Ekranına Dön" : 'Back To Login';
    newPost = tr ? "Yeni Post" : 'New Post';
    newStory = tr ? "Yeni Hikaye" : 'New Story';
    postSuccSub = tr
        ? "Postun başarılı bir şekilde paylaşıldı."
        : "Your post successfully submitted.";
    selectPhoto = tr ? "Fotoğraf Seç" : "Select Image";
    writeaCaption = tr ? "Başlık yaz..." : "Write a caption...";
    notifications = tr ? "Bildirimler" : 'Notifications';
    unblock = tr ? "Engeli Kaldır" : 'Unblock';
    block = tr ? "Engelle" : "Block";
    report = tr ? "Şikayet et" : "Report";
    usReported =
        tr ? "Kullanıcı şikayet edildi" : "User successfully reported!";
    usBlocked = tr ? "Kullanıcı engellendi" : "User successfully blocked!";
    usUnblocked =
        tr ? "Kullanıcı engeli kaldırıldı" : "User successfully unblocked!";
    posts = tr ? "Postlar" : "Posts";
    followers = tr ? "Takipçiler" : "Followers";
    myFollowers = tr ? "Benim Takipçilerim" : "My Followers";
    sFollowers = tr ? "Takipçileri" : "'s Followers";
    myFollowings = tr ? "Takip Ettiklerim" : "My Followings";
    sFollowings = tr ? "Takip Ettikleri" : "'s Followings";
    birthday = tr ? "Doğum Günü" : "Birthday";
    gender = tr ? "Cinsiyet" : "Gender";
    location = tr ? "Konum" : "Location";
    editProfile = tr ? "Profili Düzenle" : "Edit Profile";
    editYourProfile = tr ? "Profilini Düzenle" : 'Edit Your Profile';
    deleteAccount = tr ? "Hesabını Sil" : "Delete your account";
    deleteAccDetails = tr
        ? "Hesabını silmek istiyor musun? \nBu işlem geri alınamaz"
        : "Do you want to delete your account? \nThis action can not be undone";
    yes = tr ? "Evet" : "Yes";
    deleteDetailDialog =
        tr ? "Doğrulamak için bilgilerini gir" : "Type your info to confirm";
    delete = tr ? "Sil" : "Delete";
    usDeleted = tr ? "Kullanıcı silindi!" : "User successfully deleted!";
    recent = tr ? "YAKIN ARAMALAR" : 'RECENT';
    users = tr ? "KULLANICILAR" : "USERS";
    popyf =
        tr ? "Takip ettiğin kişilerin postları" : "Posts of people you follow";
    explore = tr ? "Keşfet" : "Explore";
    postType = tr ? "Post Türü" : "Post Type";
    error = tr ? "Hata" : "Error";
    comments = tr ? "yorum" : "comments";
    save = tr ? "Postu Kaydet" : 'Save Post';
    unsave = tr ? "Kaydedilenlerden Kaldır" : 'Unsave Post';
    pReported = tr ? "Post şikayet edildi" : "Post reported";
    psSaved = tr ? "Post kaydedildi" : "Post successfully saved";
    psUnsaved =
        tr ? "Post kaydedilenlerden çıkarıldı" : "Post successfully unsaved";
    person = tr ? "Kişi" : "Person";
    people = tr ? "Kişi" : "People";
    and = tr ? "ve" : "And";
    yourStory = tr ? "Senin Hikayen" : 'Your Story';
    ypsSubmitted = tr
        ? "Postun başarılı bir şekilde paylaşıldı"
        : "Your story successfully submitted.";
    myPosts = tr ? "Benim Postlarım" : 'My Posts';
    sPosts = tr ? "'ın Postları" : "'s Posts";
    reply = tr ? "Cevapla" : "Reply";
    ago = tr ? "önce" : "ago";
    sendMessage = tr ? "Mesaj Gönder" : 'Send Message';
    sharedaStory = tr ? "Bir hikaye paylaştı" : "Shared a story";
    ymhbSent = tr ? "Mesajın yollandı" : "Your message has been sent";
    niInformation = tr ? "Yetersiz bilgi" : "Not enough information!";
    ctrlInbox = tr ? "Emailini kontrol et" : "Control your inbox!";
    errorMes1 = tr
        ? "Email zaten kullanılıyor. Giriş sayfasına dön."
        : "Email already used. Go to login page.";
    errorMes2 = tr
        ? "Email/şifre kombinasyonu yanlış"
        : "Wrong email/password combination.";
    errorMes3 = tr
        ? "Bu emaile sahip hesap bulunamadı."
        : "No user found with this email.";
    errorMes4 = tr ? "Kullanıcı hesabı donduruldu." : "User disabled.";
    errorMes5 = tr
        ? "Bu hesaba girmek için istek kotası aşıldı."
        : "Too many requests to log into this account.";
    errorMes6 = tr
        ? "Sunucu hatası, lütfen sonra tekrar deneyiniz."
        : "Server error, please try again later.";
    errorMes7 = tr ? "Bu email kullanılamıyor." : "Email address is invalid.";
    errorMes8 = tr
        ? "Giriş başarısız. Lütfen sonra tekrar deneyiniz."
        : "Login failed. Please try again.";
    cancel = tr ? "İptal" : "Cancel";
    incompleteInfo = tr ? "Eksik Bilgi" : "Incomplete Info";
    showLocInfo = tr ? "Konum Bilgisini Göster" : "Show Location Info";
    selectLoc = tr ? "Konumunu Seç" : "Select your location";
    country = tr ? "Ülke" : "Country";
    state = tr ? "İl" : "State";
    city = tr ? "Semt" : "City";
    sCountry = tr ? "Ülke Ara" : "Search Country";
    sState = tr ? "İl Ara" : "Search State";
    sCity = tr ? "Semt Ara" : "Search City";
    comments2 = tr ? "Yorumlar" : "Comments";
    loading = tr ? "Yükleniyor" : "Loading";
    you = tr ? "Sen" : "You";
    imageFile = tr ? "Görsel Paylaşımı" : "Image File";
    postFile = tr ? "Post Paylaşımı" : "Shared Post";
    typeYourMessage = tr ? "Mesaj" : 'Type your message...';
    photo = tr ? "Fotoğraf" : "Photo";
    sharedanImage = tr ? "Bir fotoğraf paylaştı" : "Shared an image";
    likedYourPost = tr ? "postunu beğendi" : "liked your post";
    followedYou = tr ? "seni takip etti" : "followed you";
    continue0 = tr ? "Devam Et" : "Continue";
    previous = tr ? "Geri Dön" : "Previous";
    groupName = tr ? "Grup İsmi" : 'Group Name';
    cantBeEmpty = tr ? "Boş Olamaz" : 'Can\'t Be Empty';
    desc = tr ? "Açıklama" : 'Description';
    descYourGroup =
        tr ? "Grubun hakkında bir açıklama yaz" : 'Describe your group';
    coverPhoto = tr ? "Grup Fotoğrafı" : 'Cover Photo';
    uploadImage = tr ? "Görsel Yükle" : "Upload Image";
    gsCreated =
        tr ? "Grup başarıyla oluşturuldu!" : "Group successfully created!";
    yourName = tr ? "İsmin" : "Your Name";
    yourBio = tr ? "Biyografin" : "Your Bio";
    saveProfile = tr ? "Bilgilerini Kaydet" : "Save Profile";
    about = tr ? "Hakkında" : "About";
    yourGender = tr ? "Cinsiyetin" : "Your Gender";
    yourBirthday = tr ? "Doğum Günün" : "Your Birthday";
    yourLocation = tr ? "Konumun" : "Your Gender";
    male = tr ? "Erkek" : "Male";
    female = tr ? "Kadın" : "Female";
    ratherNotSay = tr ? "Söylememeyi tercih ederim" : "Rather not say";
    yourInfoChanged = tr
        ? "Bilgilerin başarıyla kaydedildi!"
        : "Your information successfully updated!";
    editGroup = tr ? "Grubu Düzenle" : 'Edit Group';
    groupDesc = tr ? "Grup Açıklaması" : 'Group Description';
    deleteGroup = tr ? "Grubu Sil" : "Delete Group";
    save2 = tr ? "Kaydet" : "Save";
    deleteGroupDet = tr
        ? "Grubu silmek istiyor musun? \nBu işlem geri alınamaz."
        : "Do you want to delete this group?\nThis action can not be undone.";
    groupDeleted = tr ? "Grup Silindi!" : "Group deleted!";
    groupInfoSaved = tr
        ? "Grup bilgileri başarıyla kaydedildi"
        : "Group information successfully updated!";
    groupMembers = tr ? "Grup Üyeleri" : 'Group Members';
    group = tr ? "Grup" : "Group";
    deletedGroup = tr ? "Silinmiş Grup" : "Deleted Group";
    join = tr ? "Katıl" : "Join";
    addPost = tr ? "Post Paylaş" : "New Post";
    members = tr ? "Üyeler" : "Members";
    uramNow =
        tr ? "Artık bu grubun üyesisin." : "You are a member of this group now";
    leaveGroup = tr ? "Gruptan Ayrıl" : "Leave group";
    dywtltg =
        tr ? "Gruptan ayrılmak istiyor musun?" : "Do you want to leave group?";
    youLeavedTheGroup = tr ? "Gruptan ayrıldın!" : "You leaved the group!";
    pDeleted = tr ? "Post silindi!" : "Post deleted!";
    yourGroups = tr ? "Grupların" : 'Your Groups';
    createaGroup = tr ? "Bir Grup Oluştur" : "Create a Group";
    joinGroups = tr ? "Gruplara Katıl" : "Join Groups";
    groupsYouManage = tr ? "Yönettiğin Gruplar" : 'Groups you manage';
    others = tr ? "Diğerleri" : "Others";
    home = tr ? "Keşfet" : 'Home';
  }
}
