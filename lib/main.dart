import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Native libmpv engine initialization
  MediaKit.ensureInitialized();

  // Pure cinema fullscreen - hides navigation & status bars
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const MerishPlayerApp());
}

class MerishPlayerApp extends StatelessWidget {
  const MerishPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // Pure AMOLED Black
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          surface: Colors.black,
        ),
      ),
      home: const VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    initEngine();
  }

  Future<void> initEngine() async {
    // Request storage access for offline media playback
    await Permission.storage.request();
    await Permission.videos.request();

    // 1. Initialize Player with low-buffer & zero-telemetry
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32MB Strict buffer to prevent memory bloat
        logLevel: LogLevel.none,       // Zero debug logging overhead
      ),
    );

    // 2. Hardware Texture Acceleration via Android MediaCodec
    controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
        hwdec: 'mediacodec', // Snapdragon direct VPU hardware hook
      ),
    );

    if (mounted) {
      setState(() {
        isReady = true;
      });
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.amber,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Video(
          controller: controller,
          controls: AdaptiveVideoControls, // Responsive touch controls
        ),
      ),
    );
  }
}
