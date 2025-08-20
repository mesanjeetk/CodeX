import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

// Handle notification taps in background
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  _routeFromNotification(response);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _routeFromNotification,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Advanced Notifications',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      routes: {
        '/details': (context) => const DetailsPage(),
      },
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _progressId = 1001;
  Timer? _progressTimer;
  String _lastAction = "No notification interaction yet.";

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  // Simple notification
  Future<void> _showSimple() async {
    const android = AndroidNotificationDetails(
      'simple_channel',
      'Simple Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Simple Notification',
      'This is a normal notification',
      const NotificationDetails(android: android),
      payload: 'route:/details',
    );
  }

  // Notification with actions
  Future<void> _showActions() async {
    const android = AndroidNotificationDetails(
      'action_channel',
      'Action Notifications',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          'REPLY',
          'Reply',
          inputs: [AndroidNotificationActionInput(label: 'Type here')],
        ),
        AndroidNotificationAction('MARK_DONE', 'Mark Done'),
      ],
    );
    await flutterLocalNotificationsPlugin.show(
      1,
      'Interactive Notification',
      'Tap an action below',
      const NotificationDetails(android: android),
      payload: 'route:/details',
    );
  }

  // Progress notification
  Future<void> _showProgress() async {
    int progress = 0;
    _progressTimer?.cancel();

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      progress += 20;
      final android = AndroidNotificationDetails(
        'progress_channel',
        'Progress Notifications',
        channelDescription: 'Shows progress',
        importance: Importance.low,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
      );

      await flutterLocalNotificationsPlugin.show(
        _progressId,
        'Downloading',
        '$progress% completed',
        NotificationDetails(android: android),
      );

      if (progress >= 100) timer.cancel();
    });
  }

  // Big text notification
  Future<void> _showBigText() async {
    const android = AndroidNotificationDetails(
      'bigtext_channel',
      'Big Text Notifications',
      styleInformation: BigTextStyleInformation(
        'This is a very long text that will be shown in expanded mode. '
        'You can use this for detailed updates, announcements, or content previews.',
      ),
    );
    await flutterLocalNotificationsPlugin.show(
      2,
      'Big Text Example',
      'Swipe down to expand',
      const NotificationDetails(android: android),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      (_showSimple, "Show Simple Notification"),
      (_showActions, "Show Interactive Notification"),
      (_showProgress, "Show Progress Notification"),
      (_showBigText, "Show BigText Notification"),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Local Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final btn in buttons)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: btn.$1,
                child: Text(btn.$2),
              ),
            ),
          const Divider(height: 32),
          Text(
            "📩 Last action/result:\n$_lastAction",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Handle navigation + update UI
void _routeFromNotification(NotificationResponse response) {
  final payload = response.payload ?? '';
  final message =
      'ActionId: ${response.actionId}, Input: ${response.input ?? "(none)"}';

  // Update HomePage if it's mounted
  if (_navKey.currentState?.context.mounted ?? false) {
    final ctx = _navKey.currentState!.context;
    if (ctx.findAncestorStateOfType<_HomePageState>() case final homeState?) {
      homeState.setState(() {
        homeState._lastAction = message;
      });
    }
  }

  // Navigate if payload has route
  if (payload.startsWith('route:')) {
    final route = payload.replaceFirst('route:', '');
    _navKey.currentState?.pushNamed(route, arguments: {
      'actionId': response.actionId,
      'input': response.input,
    });
  }
}

// Details Page
class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Details Page')),
      body: Center(
        child: Text(
          "Navigated via notification!\n"
          "ActionId: ${args?['actionId'] ?? "(none)"}\n"
          "Input: ${args?['input'] ?? "(none)"}",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}