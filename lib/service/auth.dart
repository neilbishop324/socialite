import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../model/SVUser.dart';
import '../screens/auth/components/SVSignUpComponent.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../utils/SVCommon.dart';

const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  String? getUid() {
    return user?.uid;
  }

  Future<User?> signIn(String email, String password) async {
    try {
      var user = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return user.user;
    } on FirebaseAuthException catch (e) {
      String err = getMessageFromErrorCode(e);
      Fluttertoast.showToast(
          msg: err,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          fontSize: 16.0);
      return null;
    } catch (e) {
      showToast(e.toString());
      return null;
    }
  }

  signOut() async {
    return await _auth.signOut();
  }

  final s = Translations();

  sendResetLink(String? email) async {
    if (email == null) {
      showToast(s.niInformation);
    } else {
      try {
        await _auth.sendPasswordResetEmail(email: email);
        showToast(s.ctrlInbox);
      } on FirebaseAuthException catch (e) {
        showToast(getMessageFromErrorCode(e));
      } catch (e) {
        showToast(e.toString());
      }
    }
  }

  bool userLoggedIn() {
    return (user != null);
  }

  String generateId(int len) {
    var r = Random();
    return String.fromCharCodes(
        List.generate(len, (index) => r.nextInt(33) + 89));
  }

  String getMessageFromErrorCode(FirebaseAuthException errorCode) {
    switch (errorCode.code) {
      case "ERROR_EMAIL_ALREADY_IN_USE":
      case "account-exists-with-different-credential":
      case "email-already-in-use":
        return s.errorMes1;
      case "ERROR_WRONG_PASSWORD":
      case "wrong-password":
        return s.errorMes2;
      case "ERROR_USER_NOT_FOUND":
      case "user-not-found":
        return s.errorMes3;
      case "ERROR_USER_DISABLED":
      case "user-disabled":
        return s.errorMes4;
      case "ERROR_TOO_MANY_REQUESTS":
      case "operation-not-allowed":
        return s.errorMes5;
      case "ERROR_OPERATION_NOT_ALLOWED":
      case "operation-not-allowed":
        return s.errorMes6;
      case "ERROR_INVALID_EMAIL":
      case "invalid-email":
        return s.errorMes7;
      default:
        return s.errorMes8;
    }
  }

  Future<User?> signUp(UserAFD userAFD) async {
    try {
      var user = await _auth.createUserWithEmailAndPassword(
          email: userAFD.email, password: userAFD.password);

      final String defaultPpUrl = SVConstants.imageLinkDefault;
      var modelUser = getUserDetails(
          userAFD.name, userAFD.username, defaultPpUrl, user.user!.uid);

      final usersRef = _firestore
          .collection(CollectionPath().users)
          .withConverter<UserDetails>(
            fromFirestore: (snapshot, _) =>
                UserDetails.fromJson(snapshot.data()!),
            toFirestore: (user, _) => user.toJson(),
          );

      await usersRef.doc(user.user!.uid).set(modelUser);

      return user.user;
    } on FirebaseAuthException catch (e) {
      String err = getMessageFromErrorCode(e);
      showToast(err);
      return null;
    } catch (e) {
      showToast(e.toString());
      return null;
    }
  }

  Future<void> addCredentialToFirestore(UserCredential credential) async {
    final user = credential.user;
    if (user?.displayName != null &&
        user?.photoURL != null &&
        user?.email != null) {
      String email = user!.email!;
      String username = email.substring(0, email.indexOf("@"));
      var modelUser =
          getUserDetails(user.displayName!, username, user.photoURL!, user.uid);

      final usersRef = _firestore
          .collection(CollectionPath().users)
          .withConverter<UserDetails>(
            fromFirestore: (snapshot, _) =>
                UserDetails.fromJson(snapshot.data()!),
            toFirestore: (user, _) => user.toJson(),
          );
      return await usersRef.doc(credential.user!.uid).set(modelUser);
    }
  }

  UserDetails getUserDetails(
      String name, String username, String ppUrl, String id) {
    return UserDetails(
        name: name,
        username: username,
        ppUrl: ppUrl,
        bgUrl: SVConstants.backgroundLinkDefault,
        gender: "",
        birthDay: "",
        bio: "",
        active: true,
        location: UserLocation(city: "", state: "", country: ""),
        id: id);
  }

  Future<bool> deleteUserWithCredential(AuthCredential credentials) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        UserCredential result =
            await user.reauthenticateWithCredential(credentials);
        await result.user!.delete();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
    return false;
  }

  Future<bool> deleteUserWithEmail(String email, String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        AuthCredential credentials =
            EmailAuthProvider.credential(email: email, password: password);
        UserCredential result =
            await user.reauthenticateWithCredential(credentials);
        await result.user!.delete();
        return true;
      }
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
}
