import 'package:google_fonts/google_fonts.dart';

const double SVAppContainerRadius = 32;
const double SVAppCommonRadius = 12;
const svAppName = "Socialite";

class CollectionPath {
  String users = "Users";
  String posts = "Posts";
  String comments = "Comments";
  String likes = "Likes";
  String blockedUsers = "BlockedUsers";
  String reportedUsers = "ReportedUsers";
  String followers = "Followers";
  String chats = "Chats";
  String messages = "Messages";
  String saved = "Saved";
  String reportedPosts = "ReportedPosts";
  String search = "Search";
  String groups = "Groups";
  String members = "Members";
  String tokens = "Tokens";
  String notifications = "Notifications";
  String stories = "Stories";
  String liveStream = "LiveStream";
  String confessions = "Confessions";
  String vipPackages = "VipPackages";
  String creditPackages = "CreditPackages";
  String additionalInfo = "AdditionalInfo";
  String gifts = "Gifts";
  String logs = "flutter_log";
}

class SVConstants {
  static String imageLinkDefault =
      "https://firebasestorage.googleapis.com/v0/b/socialmedia-7c054.appspot.com/o/DALL%C2%B7E%202022-12-25%2014.04.14%20-%20a%20user%20icon%20for%20a%20social%20media%20app.png?alt=media&token=f2c2dbf7-9136-408a-868f-7a68d817d6d6";
  static String backgroundLinkDefault =
      "https://firebasestorage.googleapis.com/v0/b/socialmedia-7c054.appspot.com/o/backgroundImage.png?alt=media&token=7576f1b7-1ef2-4b33-b844-589c8b72b76b";
  static String groupImageLinkDefault =
      "https://firebasestorage.googleapis.com/v0/b/socialmedia-7c054.appspot.com/o/DALL%C2%B7E%202023-01-22%2014.34.18%20-%20simple%20group%20icon.png?alt=media&token=d8c7b4b6-7c75-4cd9-abe9-3f556cd2b7ad";
  static String fcmServerKey =
      "AAAAzhB1w6Q:APA91bGGEcr_zRc0AExM8HeUNqlg-r_Kn-VDzl8JtKgWoL1V6nwMUgM3bX2c51VxgZavUS3-VFZ14nDhdfPZm6X7M5KQAs7T2nS8S58KXcohGxAp6TkcreMQbFp4Unh_ms6cxOP3G7W6";
  static List<String> testAccounts = [
    "8LDeuDCgWKWvpz9oi7jvaSdjeMw1",
  ];
}

var svFontRoboto = GoogleFonts.roboto().fontFamily;
