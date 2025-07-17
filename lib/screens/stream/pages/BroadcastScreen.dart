import 'dart:async';
import 'dart:convert';
import 'dart:io'; // For File operations and Platform check
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart'; // Assuming this provides .validate(), .cornerRadiusWithClipRRect(), .padding*()
import 'package:permission_handler/permission_handler.dart';
import 'package:prokit_socialv/model/SVUser.dart'; // Assuming this defines UserDetails
import 'package:prokit_socialv/models/SVPostModel.dart'; // Assuming this is not directly used for stream but might be part of your project
import 'package:prokit_socialv/screens/confession/widgets/Loading.dart'; // Assuming this provides Loading widget
import 'package:prokit_socialv/screens/stream/components/Chat.dart'; // Assuming this provides Chat widget
import 'package:prokit_socialv/service/auth.dart'
    as auth; // Assuming this provides AuthService
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:prokit_socialv/service/firestore_service.dart'; // Assuming this provides FirestoreService and CollectionPath
import 'package:prokit_socialv/utils/SVCommon.dart'; // Assuming this provides getTimeDifference
import 'package:prokit_socialv/utils/SVConstants.dart'; // Assuming this provides constants like pink, black
import 'package:prokit_socialv/utils/Translations.dart'; // Assuming this provides Translations
import 'package:http/http.dart' as http;
import 'package:prokit_socialv/model/LiveStream.dart'
    as live; // Assuming this defines LiveStream model

import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;

const appId = "1a971a07fe1a49669c2c8dd088309979"; // Your Agora App ID

class BroadcastScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String channelId;
  const BroadcastScreen(
      {Key? key, required this.isBroadcaster, required this.channelId})
      : super(key: key);

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  RtcEngine? _engine;
  UserDetails? currentUser; // Current logged-in user details
  Translations s = Translations(); // For localization
  String baseUrl =
      "https://socialite-backend-0zue.onrender.com"; // Your backend URL
  String? token;
  List<int> remoteUids = []; // List of UIDs of remote users in the channel
  UserDetails?
      broadcasterUser; // Details of the user who is broadcasting (the host)

  final ScreenshotController _screenshotController = ScreenshotController();
  Color dynamicTextColor =
      Colors.white; // For dynamic text color based on background brightness

  Timer? _brightnessAnalysisTimer; // Timer for brightness analysis

  // File logging variables
  File? _logFile;

  @override
  void initState() {
    super.initState();
    _initializeFileLogger(); // Initialize the file logger first
    _initializeEverything();

    // Start periodic brightness analysis only if it's an audience member
    if (!widget.isBroadcaster) {
      _brightnessAnalysisTimer =
          Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          analyzeBrightness();
        } else {
          timer.cancel(); // Cancel timer if widget is no longer mounted
        }
      });
    }
  }

  @override
  void dispose() {
    _brightnessAnalysisTimer?.cancel(); // Cancel timer when widget is disposed
    _leaveChannel(context,
        dispose: true); // Ensure channel is left and engine destroyed
    super.dispose();
  }

  /// Initializes the logging mechanism to write to a file named 'logs.txt'.
  /// The file will be located in the application's sandboxed root directory.
  Future<void> _initializeFileLogger() async {
    try {
      _logFile = File('logs.txt'); // Create File instance directly

      // Clear the log file on each app start for fresh debugging sessions
      if (await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }

      final timestamp =
          DateTime.now().toIso8601String(); // Simple timestamp format
      await _logFile!.writeAsString('--- App Log Started: $timestamp ---\n\n',
          mode: FileMode.append);

      if (kDebugMode) {
        print(
            "File logger initialized. Logs will be saved to: ${_logFile!.path}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("FATAL: Failed to initialize file logger: $e");
      }
      _logFile = null; // Indicate logger failed
    }
  }

  /// Writes a log message to the file with the specified level.
  Future<void> _logToFile(String level, dynamic message,
      [dynamic error, StackTrace? stackTrace]) async {
    if (_logFile == null) {
      // Fallback to console if file logger failed to initialize
      if (kDebugMode) {
        print("[$level] $message");
        if (error != null) print("Error: $error");
        if (stackTrace != null) print("StackTrace: $stackTrace");
      }
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final StringBuffer logEntry = StringBuffer();
    logEntry.write('[$timestamp] [$level] $message');

    if (error != null) {
      logEntry.write('\n  Error: $error');
    }
    if (stackTrace != null) {
      logEntry.write('\n  StackTrace:\n$stackTrace');
    }
    logEntry.write('\n');

    try {
      await _logFile!.writeAsString(logEntry.toString(), mode: FileMode.append);
    } catch (e) {
      // If writing to file fails, print to console as a last resort
      if (kDebugMode) {
        print("FATAL: Could not write to log file: $e");
        print(
            logEntry.toString()); // Also print the message that failed to write
      }
    }
  }

  /// Analyzes the brightness of the captured screenshot and adjusts text color.
  void analyzeBrightness() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        _logToFile("DEBUG", "Screenshot capture returned null.");
        return;
      }

      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        _logToFile("DEBUG", "Failed to decode image from bytes.");
        return;
      }

      int totalBrightness = 0;
      int count = 0;

      // Sample pixels at intervals to optimize performance
      for (int y = 0; y < image.height; y += 10) {
        for (int x = 0; x < image.width; x += 10) {
          final pixel = image.getPixel(x, y) as int;
          int r = (pixel >> 16) & 0xFF;
          int g = (pixel >> 8) & 0xFF;
          int b = pixel & 0xFF;

          final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
          totalBrightness += brightness.toInt();
          count++;
        }
      }

      if (count == 0) {
        _logToFile("DEBUG", "No pixels sampled for brightness analysis.");
        return;
      }

      final avgBrightness = totalBrightness / count;
      setState(() {
        // If average brightness is high (light background), use black text, else white
        dynamicTextColor = avgBrightness > 128 ? Colors.black : Colors.white;
        _logToFile("DEBUG",
            "Average brightness: $avgBrightness, Text color set to: $dynamicTextColor");
      });
    } catch (e, st) {
      _logToFile("ERROR", "Brightness detection failed", e, st);
    }
  }

  /// Initializes user data and Agora engine.
  Future<void> _initializeEverything() async {
    try {
      final userUid = auth.AuthService().getUid();
      currentUser = await FirestoreService().getUser(userUid);
      broadcasterUser =
          await getBroadcasterUser(); // Get details of the broadcaster

      setState(() {}); // Update UI after fetching user data
      await _initEngine();
    } catch (e, st) {
      _logToFile("ERROR", "Failed to initialize everything", e, st);
    }
  }

  /// Fetches an Agora RTC token from your backend.
  Future<void> getToken() async {
    if (currentUser == null || currentUser!.id.isEmpty) {
      _logToFile("WARNING",
          "currentUser or currentUser.id is null/empty. Cannot fetch token.");
      return;
    }

    try {
      // IMPORTANT FIX: Request token for integer UID (hashCode)
      // The backend expects "uid" tokentype and the integer value.
      final String tokenUrl =
          '$baseUrl/rtc/${widget.channelId}/publisher/uid/${currentUser!.id.hashCode}/';
      _logToFile("DEBUG", "Fetching token from: $tokenUrl");

      final res = await http.get(Uri.parse(tokenUrl));
      if (res.statusCode == 200) {
        setState(() {
          token = jsonDecode(res.body)['rtcToken'];
          _logToFile("INFO", "RTC Token fetched successfully.");
        });
      } else {
        _logToFile(
            "ERROR", 'Fetch token failed: ${res.statusCode} - ${res.body}');
      }
    } catch (e, st) {
      _logToFile("ERROR", 'Token fetch error', e, st);
    }
  }

  /// Initializes the Agora RTC engine and sets up event handlers.
  Future<void> _initEngine() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine?.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      _logToFile("INFO", "Agora engine initialized.");

      _addListeners();
      await _engine?.enableVideo();
      await _engine
          ?.startPreview(); // Start local video preview for broadcaster
      await _engine?.setClientRole(
        role: widget.isBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );
      _logToFile("INFO",
          "Client role set to: ${widget.isBroadcaster ? 'Broadcaster' : 'Audience'}");

      // For audience, listen for stream ending
      if (!widget.isBroadcaster) {
        FirebaseFirestore.instance
            .collection(CollectionPath().liveStream)
            .doc(widget.channelId)
            .snapshots()
            .listen((snapshot) {
          if (!snapshot.exists && mounted) {
            _logToFile("INFO", "Live stream ended by host. Leaving channel.");
            finish(context); // Assuming finish() navigates back
          }
        });
      }

      await _joinChannel();
    } catch (e, st) {
      _logToFile("ERROR", "Engine initialization failed", e, st);
    }
  }

  /// Registers Agora SDK event handlers.
  void _addListeners() {
    _engine?.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        _logToFile("INFO",
            'joinChannelSuccess: ${connection.channelId} Local UID: ${connection.localUid}');
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        _logToFile(
            "INFO", 'onUserJoined: Remote UID: $remoteUid joined the channel.');
        // showToast("User $remoteUid joined"); // Consider removing toast for production
        setState(() {
          remoteUids.add(remoteUid);
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        _logToFile("INFO",
            'onUserOffline: Remote UID: $remoteUid left. Reason: $reason');
        // showToast("User $remoteUid left"); // Consider removing toast for production
        setState(() {
          remoteUids.remove(remoteUid);
        });
      },
      onLeaveChannel: (connection, stats) {
        _logToFile(
            "INFO", 'leaveChannel: Channel left. Stats: ${stats.toJson()}');
        setState(() {
          remoteUids.clear();
        });
      },
      onTokenPrivilegeWillExpire: (connection, tkn) async {
        _logToFile("WARNING", "Token privilege will expire. Renewing token...");
        await getToken(); // Fetch a new token
        if (token != null) {
          await _engine?.renewToken(token!);
          _logToFile("INFO", "Token renewed successfully.");
        } else {
          _logToFile("ERROR", "Failed to renew token: new token is null.");
        }
      },
      onError: (err, msg) {
        _logToFile("ERROR", "Agora Error: $err, Message: $msg");
      },
    ));
  }

  /// Joins the Agora channel.
  Future<void> _joinChannel() async {
    await getToken(); // Ensure token is fetched before joining

    if (token == null || currentUser?.id == null) {
      _logToFile(
          "ERROR", "Token or currentUser.id is null. Cannot join channel.");
      showToast("Error: Could not join stream (token/user missing).");
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      // Request permissions for microphone and camera
      await [Permission.microphone, Permission.camera].request();
    }

    try {
      await _engine?.joinChannel(
        token: token!,
        channelId: widget.channelId,
        uid: currentUser!.id.hashCode, // Use the integer hash code as UID
        options: const ChannelMediaOptions(),
      );
      _logToFile("INFO",
          "Joined channel ${widget.channelId} with UID ${currentUser!.id.hashCode}");

      if (widget.isBroadcaster) {
        // Broadcaster can switch camera, audience doesn't need this initially
        // _switchCamera(); // You might want to call this based on a UI action
      }
      if (!widget.isBroadcaster) {
        await FirestoreService().updateViewCount(widget.channelId, true);
        _logToFile("INFO",
            "Audience: View count increased for channel ${widget.channelId}");
      }
    } catch (e, st) {
      _logToFile("ERROR", "Failed to join channel", e, st);
      showToast("Error joining stream: $e");
    }
  }

  /// Switches the camera (front/back). Only relevant for broadcasters.
  void _switchCamera() {
    _engine?.switchCamera().catchError((err) {
      _logToFile("ERROR", 'switchCamera error', err);
    });
  }

  /// Leaves the Agora channel and performs cleanup.
  Future<void> _leaveChannel(BuildContext context,
      {bool dispose = false}) async {
    _logToFile("INFO", "Attempting to leave channel...");
    try {
      await _engine?.leaveChannel();
      _logToFile("INFO", "Channel left successfully.");

      if (widget.isBroadcaster) {
        // Only the broadcaster ends the live stream in Firestore
        if ("${currentUser?.id}${currentUser?.username}" == widget.channelId) {
          await FirestoreService().endLiveStream(widget.channelId);
          _logToFile("INFO", "Broadcaster: Live stream ended in Firestore.");
        }
      } else {
        // Audience updates view count
        await FirestoreService().updateViewCount(widget.channelId, false);
        _logToFile("INFO",
            "Audience: View count decreased for channel ${widget.channelId}");
      }
    } catch (e, st) {
      _logToFile(
          "ERROR", "Error leaving channel or cleaning up Firestore", e, st);
    } finally {
      if (dispose) {
        await _engine?.release(); // Release engine resources when disposing
        _logToFile("INFO", "Agora engine released.");
      }
      if (mounted && !dispose) {
        // Only navigate back if not called from dispose
        finish(context); // Assumes finish() navigates back
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveChannel(context);
        return true;
      },
      child: Scaffold(
        bottomNavigationBar: widget.isBroadcaster
            ? Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 16.0),
                child: normalButton(
                  text:
                      s.endStream, // Assuming s.endStream provides "End Stream"
                  onPressed: () => _leaveChannel(context),
                ),
              )
            : null,
        body: Stack(
          children: [
            // Video rendering layer (background)
            _renderVideo(),

            // Chat and other overlays (foreground)
            Column(
              children: [
                Expanded(
                  child: Chat(
                    channelId: widget.channelId,
                    user: currentUser,
                    engine: _engine,
                  ),
                ),
              ],
            ),

            // App bar (top-most layer)
            appBar(context),
          ],
        ),
      ),
    );
  }

  /// Renders the local or remote video stream.
  Widget _renderVideo() {
    if (_engine == null) {
      _logToFile("WARNING", "_renderVideo: Agora engine is null.");
      return Container(
        color: Colors.black,
        child: const Center(
            child: Text("Initializing video engine...",
                style: TextStyle(color: Colors.white))),
      );
    }

    if (widget.isBroadcaster) {
      // Broadcaster's local video view (UID 0)
      _logToFile(
          "DEBUG", "_renderVideo: Rendering local broadcaster video (UID 0).");
      return Screenshot(
        controller: _screenshotController,
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine!,
            canvas:
                const VideoCanvas(uid: 0), // Local user has UID 0 by convention
          ),
        ),
      );
    } else {
      // Audience's remote video view
      if (remoteUids.isNotEmpty) {
        // Display the first remote user's video (assuming one main broadcaster)
        final remoteUidToDisplay = remoteUids.first;
        _logToFile("INFO",
            "_renderVideo: Audience rendering remote video for UID: $remoteUidToDisplay");
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine!,
            canvas: VideoCanvas(uid: remoteUidToDisplay),
            connection: RtcConnection(channelId: widget.channelId),
          ),
        );
      } else {
        _logToFile("DEBUG",
            "_renderVideo: Audience waiting for remote user to join or publish stream.");
        // Placeholder when no remote stream is available yet for audience
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                16.height,
                Text(
                  "Waiting for broadcaster...",
                  style: boldTextStyle(color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  /// Builds the app bar for the stream screen.
  Widget appBar(BuildContext context) {
    return FutureBuilder<UserDetails?>(
      future: getBroadcasterUser(), // Fetch broadcaster's details
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          _logToFile(
              "DEBUG", "appBar: Broadcaster user data not yet available.");
          return const SizedBox(); // Return empty if data not available
        }
        final UserDetails broadcasterDetails = snapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(CollectionPath().liveStream)
              .doc(widget.channelId)
              .snapshots(),
          builder: (context, streamSnapshot) {
            if (!streamSnapshot.hasData || !streamSnapshot.data!.exists) {
              _logToFile("DEBUG",
                  "appBar: Live stream data not yet available or stream ended.");
              return Container(); // Return empty if stream data isn't there
            }
            final liveStreamData = streamSnapshot.data!;
            final live.LiveStream liveStream = live.LiveStream(
              title: liveStreamData['title'],
              image: liveStreamData['image'],
              uid: liveStreamData['uid'],
              username: liveStreamData['username'],
              viewers: liveStreamData['viewers'],
              channelId: liveStreamData['channelId'],
              startedAt: (liveStreamData['startedAt'] as Timestamp)
                  .toDate(), // Convert Timestamp to DateTime
            );

            return Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  right: 10),
              child: Row(
                children: [
                  // Broadcaster's Profile Picture
                  Image.network(
                    broadcasterDetails.ppUrl.validate(),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.grey, size: 40),
                  ).cornerRadiusWithClipRRect(20),

                  // Broadcaster's Username
                  Text(
                    broadcasterDetails.username.validate(),
                    style: boldTextStyle(size: 15, color: dynamicTextColor),
                  ).paddingLeft(10),

                  // Stream Duration
                  Text(
                    getTimeDifference(
                      liveStream.startedAt.millisecondsSinceEpoch,
                      shortly: true,
                    ),
                    style: secondaryTextStyle(color: dynamicTextColor),
                  ).paddingLeft(10),

                  const Spacer(),

                  // "LIVE" indicator
                  Container(
                    color: const Color(0xffefc5b5).withOpacity(0.8),
                    child: Text(s.live,
                            style: const TextStyle(color: Colors.black))
                        .paddingAll(4),
                  ).cornerRadiusWithClipRRect(4),

                  // Likes Count
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(CollectionPath().liveStream)
                        .doc(widget.channelId)
                        .collection(CollectionPath().likes)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return Container(
                        color: pink.withOpacity(0.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 20,
                              color: dynamicTextColor,
                            ),
                            Text(
                              snapshot.data!.docs.length.toString(),
                              style: TextStyle(color: dynamicTextColor),
                            ),
                          ],
                        ).paddingSymmetric(horizontal: 4, vertical: 2),
                      ).cornerRadiusWithClipRRect(4).paddingOnly(left: 8);
                    },
                  ),

                  // Viewers Count
                  Container(
                    color: black.withOpacity(0.5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_red_eye,
                            size: 20, color: dynamicTextColor),
                        Text(liveStream.viewers.toString(),
                            style: TextStyle(color: dynamicTextColor)),
                      ],
                    ).paddingSymmetric(horizontal: 4, vertical: 2),
                  )
                      .cornerRadiusWithClipRRect(4)
                      .paddingSymmetric(horizontal: 8),

                  // Close Button
                  IconButton(
                    onPressed: () => _leaveChannel(context),
                    icon: Icon(
                      Icons.close,
                      color: dynamicTextColor,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Fetches the UserDetails of the broadcaster for the current channel.
  Future<UserDetails?> getBroadcasterUser() async {
    if (broadcasterUser != null) {
      return broadcasterUser; // Return cached if already fetched
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(CollectionPath().liveStream)
          .doc(widget.channelId)
          .get();
      if (snapshot.exists) {
        final userId = snapshot['uid'] as String?;
        if (userId != null) {
          final user = await FirestoreService().getUser(userId);
          _logToFile("DEBUG", "Fetched broadcaster user: ${user?.username}");
          return user;
        }
      }
      _logToFile("WARNING",
          "Broadcaster user not found for channel: ${widget.channelId}");
      return null;
    } catch (e, st) {
      _logToFile("ERROR", "Error fetching broadcaster user", e, st);
      return null;
    }
  }
}
