import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _isFirebaseInitialized = false;

Future<void> _initFirebaseSafely() async {
  try {
    // Attempt dynamic/default initialization
    await Firebase.initializeApp();
    _isFirebaseInitialized = true;
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization failed, using local caching mode: $e");
  }
}

// Fetch high scores
Future<List<Map<String, dynamic>>> _getScores() async {
  if (_isFirebaseInitialized) {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .limit(10)
          .get();
      
      final List<Map<String, dynamic>> firebaseScores = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        firebaseScores.add({
          'name': data['name'] ?? 'Anonymous',
          'score': data['score'] ?? 0,
        });
      }
      
      // Cache the list to SharedPreferences for offline capability
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_leaderboard', json.encode(firebaseScores));
      
      return firebaseScores;
    } catch (e) {
      debugPrint("Failed to fetch from Firebase, using cache: $e");
    }
  }

  // Local fallback
  final prefs = await SharedPreferences.getInstance();
  final cachedStr = prefs.getString('cached_leaderboard');
  if (cachedStr != null) {
    try {
      final List<dynamic> decoded = json.decode(cachedStr);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint("Failed to parse cached scores: $e");
    }
  }

  // Pre-seed defaults if no cache or Firebase database connection
  return [
    { 'name': "Sven The Great", 'score': 15000 },
    { 'name': "Björn Ironfist", 'score': 12400 },
    { 'name': "Linus Torvalds", 'score': 9800 },
    { 'name': "Freja Bloom", 'score': 7500 },
    { 'name': "Surströmming Fan", 'score': 4500 }
  ];
}

// Save high score
Future<void> _saveScore(String name, int score) async {
  if (_isFirebaseInitialized) {
    try {
      await FirebaseFirestore.instance.collection('leaderboard').add({
        'name': name,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("Score saved to Firebase successfully");
      return;
    } catch (e) {
      debugPrint("Failed to save to Firebase, saving to local cache instead: $e");
    }
  }

  // Cache locally
  final prefs = await SharedPreferences.getInstance();
  final cachedStr = prefs.getString('cached_leaderboard');
  List<Map<String, dynamic>> scores = [];
  if (cachedStr != null) {
    try {
      final List<dynamic> decoded = json.decode(cachedStr);
      scores = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {}
  }
  
  scores.add({'name': name, 'score': score});
  scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  if (scores.length > 10) {
    scores = scores.sublist(0, 10);
  }
  
  await prefs.setString('cached_leaderboard', json.encode(scores));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebaseSafely();
  
  // Set preferred orientations to landscape only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Midsommer Madness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Set fullscreen sticky immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Set up creation parameters for iOS WebKit to allow autoplay
    final PlatformWebViewControllerCreationParams params =
        WebViewPlatform.instance is WebKitWebViewPlatform
            ? WebKitWebViewControllerCreationParams(
                allowsInlineMediaPlayback: true,
                mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
              )
            : const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'LeaderboardChannel',
        onMessageReceived: (JavaScriptMessage message) async {
          debugPrint('Received message from game: ${message.message}');
          try {
            final Map<String, dynamic> data = json.decode(message.message);
            final String type = data['type'] ?? '';
            
            if (type == 'getScores') {
              final scores = await _getScores();
              final scoresJson = json.encode(scores);
              _controller.runJavaScript("if (window.onScoresLoaded) { window.onScoresLoaded($scoresJson); }");
            } else if (type == 'saveScore') {
              final String name = data['name'] ?? 'Player Sven';
              final int score = data['score'] ?? 0;
              await _saveScore(name, score);
              
              // Load updated scores and send back to refresh UI
              final scores = await _getScores();
              final scoresJson = json.encode(scores);
              _controller.runJavaScript("if (window.onScoresLoaded) { window.onScoresLoaded($scoresJson); }");
            }
          } catch (e) {
            debugPrint('Error processing message from WebView: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            // Inject the 'android-app' class to configure mobile styling and behavior
            _controller.runJavaScript("document.documentElement.classList.add('android-app');");
            // Signal to web page that the bridge is fully functional
            _controller.runJavaScript("if (window.onFlutterBridgeReady) { window.onFlutterBridgeReady(); }");
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
        ),
      );

    // Platform-specific configuration
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      // Allow media playback without user gestures to enable game music/sfx autoplay
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    // Load local game asset
    _controller.loadFlutterAsset('assets/index.html');
  }

  @override
  void dispose() {
    // Restore default system UI mode and orientation settings when screen is disposed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.yellow, // Swedish themed accent
                ),
              ),
          ],
        ),
      ),
    );
  }
}
