import 'dart:io';
import 'dart:math';

import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/Chat.dart';
import 'package:prokit_socialv/model/Confession.dart';
import 'package:prokit_socialv/model/Group.dart';
import 'package:prokit_socialv/model/Message.dart';
import 'package:prokit_socialv/model/Notification.dart' as Notif;
import 'package:prokit_socialv/model/SVComment.dart';
import 'package:prokit_socialv/model/SVPost.dart';
import 'package:prokit_socialv/model/VipPackage.dart';
import 'package:prokit_socialv/models/SVPostModel.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';
import 'package:uuid/uuid.dart';

import '../model/SVUser.dart';
import '../model/Story.dart';
import '../utils/SVCommon.dart';
import '../model/LiveStream.dart' as liveStream;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _auth = AuthService();
  final CollectionPath _path = CollectionPath();

  Future<UserDetails?> getUser(String? uid) async {
    if (uid == null) {
      return null;
    }

    final usersRef =
        _firestore.collection(_path.users).withConverter<UserDetails>(
              fromFirestore: (snapshot, _) =>
                  UserDetails.fromJson(snapshot.data()!),
              toFirestore: (user, _) => user.toJson(),
            );

    final user = await usersRef.doc(uid).get().then((value) => value.data());

    return user;
  }

  Future<List<UserDetails>> filterUsers(
      List<UserDetails> users, String uid) async {
    final blockedUsersSnapshot = await _firestore
        .collection(_path.users)
        .doc(uid)
        .collection(_path.blockedUsers)
        .get();

    final docs =
        blockedUsersSnapshot.docs.map((doc) => doc["id"] as String).toList();

    docs.add(uid);

    return users.where((user) {
      return !docs.contains(user.id);
    }).toList();
  }

  Future<List<String>> getIds(String collRef) async {
    final ss = await _firestore.collection(collRef).get();
    return ss.docs.map((doc) => doc["id"] as String).toList();
  }

  Future<int> getUserFollowingSize(String? uid) async {
    if (uid == null) {
      return 0;
    } else {
      int size = 0;
      final users = await getUsers();
      final userIds = users.map((e) => e.id).toList();
      for (final id in userIds) {
        final ss = await _firestore
            .collection(_path.users)
            .doc(id)
            .collection(_path.followers)
            .get();
        final ids = ss.docs.map((doc) => doc["id"] as String).toList();
        if (ids.contains(uid)) {
          size++;
        }
      }
      return size;
    }
  }

  Future<List<String>> getUserFollowings(String uid) async {
    final list = <String>[];
    final users = await getUsers();
    final userIds = users.map((e) => e.id).toList();
    for (final id in userIds) {
      final ss = await _firestore
          .collection(_path.users)
          .doc(id)
          .collection(_path.followers)
          .get();
      final ids = ss.docs.map((doc) => doc["id"] as String).toList();
      if (ids.contains(uid)) {
        list.add(id);
      }
    }
    return list;
  }

  Future<List<UserDetails>> getUsers() async {
    final usersRef =
        _firestore.collection(_path.users).withConverter<UserDetails>(
              fromFirestore: (snapshot, _) =>
                  UserDetails.fromJson(snapshot.data()!),
              toFirestore: (user, _) => user.toJson(),
            );

    List<QueryDocumentSnapshot<UserDetails>> users =
        await usersRef.get().then((value) => value.docs);
    return users.map((e) => e.data()).toList();
  }

  Future<void> deleteuser(String uid) async {
    await _firestore.collection(_path.users).doc(uid).delete();
    final posts = await _firestore
        .collection(_path.posts)
        .where("posterName", isEqualTo: uid)
        .get();
    final postIds =
        posts.docs.map((e) => e.data()["postId"] as String?).toList();
    for (String? id in postIds) {
      await _firestore.collection(_path.posts).doc(id).delete();
    }
    final messages = await getChatRooms(uid);
    for (ChatRoom message in messages) {
      final ref = message.chatUserIsFirst
          ? message.chatUserId + "_" + uid
          : uid + "_" + message.chatUserId;
      await _firestore.collection(_path.chats).doc(ref).delete();
    }
    final groups = await getGroups();
    final manageGroupList = groups
        .where((element) => element.adminId == AuthService().getUid())
        .toList();
    for (Group group in manageGroupList) {
      await _firestore.collection(_path.groups).doc(group.id).delete();
    }
    return;
  }

  Future<String?> downloadImage(File imageFile, String imagePath) async {
    final storageRef = _storage.ref();
    final imageRef = storageRef.child(imagePath);
    try {
      await imageRef.putFile(imageFile);

      final downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print(e);
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> updateUserData(String uid, Map<String, Object?> data) async {
    try {
      await _firestore.collection(_path.users).doc(uid).update(data);
      return true;
    } on FirebaseException catch (e) {
      print(e);
      if (e.message != null) {
        showToast(e.message!);
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> updateData(
      String collRef, String? docRef, Map<String, Object?> data) async {
    try {
      await _firestore.collection(collRef).doc(docRef).update(data);
      return true;
    } on FirebaseException catch (e) {
      print(e);
      if (e.message != null) {
        showToast(e.message!);
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> setData(
      String collId, String? docId, Map<String, Object?> data) async {
    try {
      await _firestore.collection(collId).doc(docId).set(data);
      return true;
    } on FirebaseException catch (e) {
      print(e);
      if (e.message != null) {
        showToast(e.message!);
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> deleteData(String collId, String docId) async {
    try {
      await _firestore.collection(collId).doc(docId).delete();
      return true;
    } on FirebaseException catch (e) {
      print(e);
      if (e.message != null) {
        showToast(e.message!);
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<String>> getPostsWithQuery(String groupId) async {
    var postsRef = _firestore.collection(_path.posts);

    Query<Post> postsRefWithQuery =
        postsRef.where("postContextId", isEqualTo: groupId).withConverter<Post>(
              fromFirestore: (snapshot, _) => Post.fromJson(snapshot.data()!),
              toFirestore: (post, _) => post.toJson(),
            );

    List<QueryDocumentSnapshot<Post>> postsSnapshot =
        await postsRefWithQuery.get().then((value) => value.docs);

    List<String> posts = [];

    postsSnapshot.forEach((postSnapshot) {
      posts.add(postSnapshot.data().postId);
    });

    return posts;
  }

  Future<List<Post>> getSavedPosts(String userUid) async {
    final ss = await _firestore
        .collection(_path.users)
        .doc(userUid)
        .collection(_path.saved)
        .get();

    final ids = ss.docs
        .map((doc) => SavedPost(doc["id"] as String, doc["time"] as int))
        .toList();
    final ref = _firestore
        .collection(_path.posts)
        .where("postId", whereIn: ids.map((e) => e.id).toList())
        .withConverter<Post>(
          fromFirestore: (snapshot, _) => Post.fromJson(snapshot.data()!),
          toFirestore: (post, _) => post.toJson(),
        );

    List<QueryDocumentSnapshot<Post>> postsSnapshot =
        await ref.get().then((value) => value.docs);

    List<Post> posts = <Post>[];

    postsSnapshot.forEach((postSnapshot) {
      posts.add(postSnapshot.data());
    });

    try {
      if (posts.length <= ids.length) {
        posts.sort((a, b) => ids
            .where((element) => element.id == b.postId)
            .toList()[0]
            .time
            .compareTo(ids
                .where((element) => element.id == a.postId)
                .toList()[0]
                .time));
      }
    } catch (e) {
      print(e);
    }

    return posts;
  }

  Future<int> getCollSize(String path, {String? uid, String? queryName}) async {
    late QuerySnapshot snapshot;
    if (uid == null) {
      snapshot = await _firestore.collection(path).get();
    } else {
      snapshot = await _firestore
          .collection(path)
          .where(queryName!, isEqualTo: uid)
          .get();
    }
    return snapshot.size;
  }

  Future<bool> userLiked(String docId, String uid) async {
    DocumentSnapshot snapshot =
        await _firestore.collection("$docId/${_path.likes}").doc(uid).get();
    return snapshot.exists;
  }

  Future<void> likeEvent(bool liked, String path, String uid,
      {Post? post}) async {
    if (liked) {
      await _firestore
          .collection("$path/${_path.likes}")
          .doc(uid)
          .set({"id": uid});
      if (post != null && post.posterName != uid) {
        final id = Extensions.generateRandomString(10);
        final notification = Notif.Notification(
            userId: uid,
            type: 1,
            postId: post.postId,
            id: id,
            timeForMillis: DateTime.now().millisecondsSinceEpoch);
        await _firestore
            .collection(_path.users)
            .doc(post.posterName)
            .collection(_path.notifications)
            .doc(notification.id)
            .set(notification.toJson());
      }
    } else {
      await _firestore.collection("$path/${_path.likes}").doc(uid).delete();
    }
  }

  Future<List<Comment>> getComments(String postId, bool descending) async {
    final commentRef = _firestore
        .collection("${_path.posts}/$postId/${_path.comments}")
        .orderBy("timeForMillis", descending: descending)
        .withConverter<Comment>(
          fromFirestore: (snapshot, _) => Comment.fromJson(snapshot.data()!),
          toFirestore: (comment, _) => comment.toJson(),
        );

    List<QueryDocumentSnapshot<Comment>> commentsSnapshot =
        await commentRef.get().then((value) => value.docs);

    List<Comment> comments = <Comment>[];

    commentsSnapshot.forEach((commentSnapshot) {
      comments.add(commentSnapshot.data());
    });

    return comments;
  }

  Future<int> ctrlChatType(String fId, String sId) async {
    final firstTry =
        await _firestore.collection(_path.chats).doc(fId + "_" + sId).get();
    if (firstTry.exists) {
      return 1;
    }
    final secondTry =
        await _firestore.collection(_path.chats).doc(sId + "_" + fId).get();
    if (secondTry.exists) {
      return 2;
    }
    return 0;
  }

  Future<List<Message>> getMessages(String fId, String sId) async {
    final messagesRef = _firestore
        .collection("${_path.chats}/${fId + "_" + sId}/${_path.messages}")
        .orderBy("timeForMillis")
        .withConverter<Message>(
          fromFirestore: (snapshot, _) => Message.fromJson(snapshot.data()!),
          toFirestore: (message, _) => message.toJson(),
        );

    List<QueryDocumentSnapshot<Message>> messagesSnapshot =
        await messagesRef.get().then((value) => value.docs);

    List<Message> messages = <Message>[];

    messagesSnapshot.forEach((messagesSnapshot) {
      messages.add(messagesSnapshot.data());
    });

    return messages;
  }

  Future<bool> sendMessage(Message message, String fId, String sId) async {
    try {
      await _firestore
          .collection(_path.chats)
          .doc(fId + "_" + sId)
          .collection(_path.messages)
          .doc(message.id)
          .set(message.toJson());
      await _firestore
          .collection(_path.chats)
          .doc(fId + "_" + sId)
          .set({"fId": fId, "sId": sId});
      return true;
    } on FirebaseException catch (e) {
      showToast(e.message!);
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<ChatRoom>> getChatRooms(String uid) async {
    final chatsSS1 = await _firestore
        .collection(_path.chats)
        .where("fId", isEqualTo: uid)
        .get();
    final chatsSS2 = await _firestore
        .collection(_path.chats)
        .where("sId", isEqualTo: uid)
        .get();
    final firstList =
        chatsSS1.docs.map((doc) => ChatRoom(doc["sId"], false)).toList();
    final secondList =
        chatsSS2.docs.map((doc) => ChatRoom(doc["fId"], true)).toList();
    return firstList + secondList;
  }

  Future<List<Chat>> getChats(String uid) async {
    final chatRooms = await getChatRooms(uid);
    final chatList = <Chat>[];
    for (ChatRoom chatRoom in chatRooms) {
      final user = await getUser(chatRoom.chatUserId);
      var messages = await getMessages(
          (chatRoom.chatUserIsFirst) ? chatRoom.chatUserId : uid,
          (chatRoom.chatUserIsFirst) ? uid : chatRoom.chatUserId);
      messages = List.from(messages.reversed);
      final lastMessage = messages.first;
      int newMessageSize = 0;
      for (Message message in messages) {
        if (message.from == uid || message.hasSeen) {
          break;
        }
        newMessageSize++;
      }
      if (user != null) {
        final chat = Chat(
            user.ppUrl,
            user.name,
            (lastMessage.type == 1)
                ? lastMessage.messageText
                : lastMessage.messageMediaUrl,
            getTimeDifference(lastMessage.timeForMillis, shortly: true),
            (lastMessage.from == uid) ? false : !lastMessage.hasSeen,
            newMessageSize,
            lastMessage.type,
            lastMessage.timeForMillis,
            user.id,
            lastMessage.from == uid);
        chatList.add(chat);
      }
    }
    return chatList;
  }

  seeMessages(
      List<Message> messages, String uid, String fId, String sId) async {
    messages = List.from(messages.reversed);
    for (Message message in messages) {
      if (message.from == uid || message.hasSeen) {
        break;
      }
      await _firestore
          .collection(_path.chats)
          .doc(fId + "_" + sId)
          .collection(_path.messages)
          .doc(message.id)
          .update({"hasSeen": true});
    }
  }

  Future<bool> reportPost(String id) async {
    return await firebaseExceptionHandler(() =>
        _firestore.collection(_path.reportedPosts).doc(id).set({"id": id}));
  }

  Future<bool> firebaseExceptionHandler(Function() initFunction) async {
    try {
      await initFunction();
      return true;
    } on FirebaseException catch (e) {
      print(e.message);
      showToast(e.message ?? Translations().sthWentWrong);
      return false;
    } catch (e) {
      print(e);
      showToast(Translations().sthWentWrong);
      return false;
    }
  }

  Future<bool> savePost(String uid, String id, bool saved) async {
    if (saved) {
      return await firebaseExceptionHandler(() => _firestore
          .collection(_path.users)
          .doc(uid)
          .collection(_path.saved)
          .doc(id)
          .delete());
    } else {
      return await firebaseExceptionHandler(() => _firestore
          .collection(_path.users)
          .doc(uid)
          .collection(_path.saved)
          .doc(id)
          .set({"id": id, "time": DateTime.now().millisecondsSinceEpoch}));
    }
  }

  Future<Group?> getGroup(String? uid) async {
    if (uid == null) {
      return null;
    }

    final groupsRef = _firestore.collection(_path.groups).withConverter<Group>(
          fromFirestore: (snapshot, _) => Group.fromJson(snapshot.data()!),
          toFirestore: (group, _) => group.toJson(),
        );

    final group = await groupsRef.doc(uid).get().then((value) => value.data()!);

    return group;
  }

  Future<List<Group>> getGroups() async {
    final groupsRef = _firestore.collection(_path.groups).withConverter<Group>(
          fromFirestore: (snapshot, _) => Group.fromJson(snapshot.data()!),
          toFirestore: (group, _) => group.toJson(),
        );

    List<QueryDocumentSnapshot<Group>> groups =
        await groupsRef.get().then((value) => value.docs);
    return groups.map((e) => e.data()).toList();
  }

  Future<List<Group>> getParticipatedGroups(
      List<Group> groups, String userId) async {
    final ids = groups.map((e) => e.id).toList();
    final participatedGroups = <Group>[];
    for (String id in ids) {
      final pSS = await _firestore
          .collection(_path.groups)
          .doc(id)
          .collection(_path.members)
          .doc(userId)
          .get();
      if (pSS.exists) {
        participatedGroups
            .add(groups.where((element) => element.id == id).toList()[0]);
      }
    }
    return participatedGroups;
  }

  Future<String?> getUserToken(String uid) async {
    final ss = await _firestore.collection(_path.tokens).doc(uid).get();
    return ss.data()?['token'];
  }

  Future<List<Notif.Notification>> getSavedNotifications(String? uid) async {
    if (uid == null) {
      return [];
    }

    final listSS = await _firestore
        .collection(_path.users)
        .doc(uid)
        .collection(_path.notifications)
        .withConverter<Notif.Notification>(
          fromFirestore: (snapshot, _) =>
              Notif.Notification.fromJson(snapshot.data()!),
          toFirestore: (notification, _) => notification.toJson(),
        )
        .get();

    return listSS.docs.map((e) => e.data()).toList();
  }

  Future<void> deleteStories() async {
    final listSS = await getStories();
    for (Story story in listSS) {
      int timeMillis = story.timeForMillis;
      int dayDifference = getDayDifference(timeMillis);
      if (dayDifference >= 1) {
        String storyId = story.userId;
        QuerySnapshot snap = await _firestore
            .collection(_path.stories)
            .doc(storyId)
            .collection(_path.likes)
            .get();
        for (int i = 0; i < snap.docs.length; i++) {
          await _firestore
              .collection(_path.liveStream)
              .doc(storyId)
              .collection(_path.comments)
              .doc((snap.docs[i].data()! as dynamic)['id'])
              .delete();
        }
        await _firestore.collection(_path.stories).doc(storyId).delete();
      }
    }
  }

  Future<void> controlIfVip() async {
    final userId = AuthService().getUid();
    try {
      final snapshot = await _firestore
          .collection(_path.users)
          .doc(userId)
          .collection(_path.additionalInfo)
          .doc(_path.additionalInfo + "2")
          .get();
      if (snapshot.exists) {
        final Timestamp? startedAt = snapshot['startedAt'];
        final Map<String, dynamic>? packageData = snapshot['package'];
        final VipPackage? package = packageData != null
            ? VipPackage(
                id: packageData['id'],
                name: packageData['name'],
                period: packageData['period'],
                periodType: packageData['periodType'],
                iconLink: packageData['iconLink'],
                price: packageData['price'],
                status: packageData['status'],
              )
            : null;
        final bool? isValid = snapshot['isValid'];
        if (isValid == true && startedAt != null && package != null) {
          final nowIsValid =
              await _vipIsValid(startedAt, package.period, package.periodType);
          if (!nowIsValid) {
            await _firestore
                .collection(_path.users)
                .doc(userId)
                .collection(_path.additionalInfo)
                .doc(_path.additionalInfo + "2")
                .update({'isValid': false});
          }
        }
      }
    } catch (e) {
      print(e);
      await _firestore
          .collection(_path.users)
          .doc(userId)
          .collection(_path.additionalInfo)
          .doc(_path.additionalInfo + "2")
          .update({'isValid': false});
    }
  }

  Future<List<Story>> getStories() async {
    final listSS = await _firestore
        .collection(_path.stories)
        .orderBy("timeForMillis", descending: true)
        .withConverter<Story>(
          fromFirestore: (snapshot, _) => Story.fromJson(snapshot.data()!),
          toFirestore: (story, _) => story.toJson(),
        )
        .get();

    return listSS.docs.map((e) => e.data()).toList();
  }

  Future<Story?> getStory(String uid) async {
    final listSS = await _firestore
        .collection(_path.stories)
        .doc(uid)
        .withConverter<Story>(
          fromFirestore: (snapshot, _) => Story.fromJson(snapshot.data()!),
          toFirestore: (story, _) => story.toJson(),
        )
        .get();

    return listSS.data();
  }

  Future<String> startLiveStream(
    BuildContext context,
    String title,
    String imageFilePath,
  ) async {
    String channelId = '';
    final userUid = AuthService().getUid();
    final user = await getUser(userUid);
    if (user != null) {
      final streamSS = await _firestore
          .collection(_path.liveStream)
          .doc('${userUid}${user.username}')
          .get();
      if (!streamSS.exists) {
        try {
          final image =
              await downloadImage(File(imageFilePath), "streams/${userUid}");
          channelId = '${userUid}${user.username}';
          if (image != null) {
            liveStream.LiveStream _liveStream = liveStream.LiveStream(
                title: title,
                image: image,
                uid: userUid!,
                username: user.username,
                viewers: 0,
                channelId: channelId,
                startedAt: DateTime.now());

            await _firestore
                .collection(_path.liveStream)
                .doc(channelId)
                .set(_liveStream.toMap());
          }
        } on FirebaseException catch (e) {
          showToast(e.message!);
          print(e.message);
        } catch (e) {
          print(e);
        }
      } else {
        showToast(Translations().alreadyStreaming);
      }
    }
    return channelId;
  }

  Future<void> endLiveStream(String channelId) async {
    try {
      QuerySnapshot snap = await _firestore
          .collection(_path.liveStream)
          .doc(channelId)
          .collection(_path.comments)
          .get();

      QuerySnapshot snap2 = await _firestore
          .collection(_path.liveStream)
          .doc(channelId)
          .collection(_path.likes)
          .get();
      for (int i = 0; i < snap.docs.length; i++) {
        await _firestore
            .collection(_path.liveStream)
            .doc(channelId)
            .collection(_path.comments)
            .doc((snap.docs[i].data()! as dynamic)['commentId'])
            .delete();
      }
      for (int i = 0; i < snap2.docs.length; i++) {
        await _firestore
            .collection(_path.liveStream)
            .doc(channelId)
            .collection(_path.likes)
            .doc((snap.docs[i].data()! as dynamic)['id'])
            .delete();
      }
      await _firestore.collection(_path.liveStream).doc(channelId).delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateViewCount(String id, bool isIncrease) async {
    try {
      await _firestore.collection(_path.liveStream).doc(id).update({
        'viewers': FieldValue.increment(isIncrease ? 1 : -1),
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> addCommentToLivestream(
    String text,
    String id,
    BuildContext context,
    UserDetails? user, {
    bool? isGift,
  }) async {
    try {
      String commentId = const Uuid().v1();
      bool isVip = await userIsVip(user?.id);
      await _firestore
          .collection(_path.liveStream)
          .doc(id)
          .collection(_path.comments)
          .doc(commentId)
          .set({
        'username': user?.username,
        'message': text,
        'uid': user?.id,
        'createdAt': DateTime.now(),
        'commentId': commentId,
        'type': (isGift == true)
            ? isVip
                ? 4 // vip gift
                : 3 // not vip gift
            : isVip
                ? 2 // vip text
                : 1, // not vip text
      });
    } on FirebaseException catch (e) {
      showToast(e.message!);
    }
  }

  Future<bool> userIsVip(String? uid) async {
    if (uid == null) return false;
    final snapshot = await _firestore
        .collection(_path.users)
        .doc(uid)
        .collection(_path.additionalInfo)
        .doc(_path.additionalInfo + "2")
        .get();
    return snapshot.exists &&
        snapshot['isValid'] != null &&
        snapshot['isValid'] as bool;
  }

  Future<bool> shareConfession(
    String title,
    String description,
    bool isAnonym,
    String userId,
  ) async {
    try {
      final confessionId = Extensions.generateRandomString(12);
      final confession = Confession(title, description, isAnonym, 0, 0, 0,
          confessionId, userId, DateTime.now());
      await _firestore
          .collection(_path.confessions)
          .doc(confessionId)
          .set(confession.toMap());
      return true;
    } on FirebaseException catch (e) {
      showToast(e.message!);
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<Confession?> getConfession(String confession) async {
    final confessionRef = _firestore
        .collection(_path.confessions)
        .withConverter<Confession>(
          fromFirestore: (snapshot, _) => Confession.fromMap(snapshot.data()!),
          toFirestore: (user, _) => user.toMap(),
        );

    return await confessionRef
        .doc(confession)
        .get()
        .then((value) => value.data());
  }

  Future<List<Comment>> getConfessionComments(String confessionId) async {
    final commentRef = _firestore
        .collection("${_path.confessions}/$confessionId/${_path.comments}")
        .orderBy("timeForMillis", descending: true)
        .withConverter<Comment>(
          fromFirestore: (snapshot, _) => Comment.fromJson(snapshot.data()!),
          toFirestore: (comment, _) => comment.toJson(),
        );

    List<QueryDocumentSnapshot<Comment>> commentsSnapshot =
        await commentRef.get().then((value) => value.docs);

    List<Comment> comments = <Comment>[];

    commentsSnapshot.forEach((commentSnapshot) {
      comments.add(commentSnapshot.data());
    });

    return comments;
  }

  Future<void> logData(Map<String, dynamic> data) async {
    final userId = _auth.getUid();
    if (userId != null && SVConstants.testAccounts.contains(userId)) {
      await _firestore.collection(_path.logs).doc().set(data);
    } else {
      await _firestore
          .collection(_path.logs)
          .doc("error")
          .set({"hasError": true});
    }
  }
}

class ChatRoom {
  final String chatUserId;
  final bool chatUserIsFirst;

  ChatRoom(this.chatUserId, this.chatUserIsFirst);
}

class SavedPost {
  final String id;
  final int time;

  SavedPost(this.id, this.time);
}

Future<bool> _vipIsValid(
    Timestamp startedAt, int period, String periodType) async {
  final startedDate = startedAt.toDate();
  DateTime endDate;
  switch (periodType) {
    case 'day':
      endDate = startedDate.add(Duration(days: period));
      break;
    case 'week':
      endDate = startedDate.add(Duration(days: period * 7));
      break;
    case 'month':
      endDate = DateTime(
        startedDate.year,
        startedDate.month + period,
        startedDate.day,
        startedDate.hour,
        startedDate.minute,
        startedDate.second,
      );
      break;
    case 'year':
      endDate = DateTime(
        startedDate.year + period,
        startedDate.month,
        startedDate.day,
        startedDate.hour,
        startedDate.minute,
        startedDate.second,
      );
      break;
    default:
      endDate = startedDate.add(Duration(days: period));
      break;
  }
  final dateNow = DateTime.now();
  await FirestoreService().logData({
    "startedAt": startedDate,
    "endDate": endDate,
    "now": dateNow,
  });
  return endDate.isAfter(dateNow);
}
