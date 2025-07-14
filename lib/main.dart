import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

// TODO: Add stream controller
// used to pass messages from event handler to the UI
final _messageStreamController = BehaviorSubject<RemoteMessage>();
// TODO: Define the background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
    print('Message notification: ${message.notification?.body}');
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // TODO: Request permission
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) {
    print('Permission granted: ${settings.authorizationStatus}');
  }
  // TODO: Registre with FCM
  // It requests a registration token for sending messages to users from your app server or another trusted server environment
  String? token = await messaging.getToken();
  if (kDebugMode) {
    print('Registration Token=$token');
  }
  // TODO: Set up foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (kDebugMode) {
      print('Received a foreground message: \nData: ${message.data}');
      if (message.notification != null) {
        print('Notification Title: ${message.notification?.title}');
        print('Notification Body: ${message.notification?.body}');
      }
    }
    _messageStreamController.add(message);

    // Show local notification
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'fcm_default_channel',
            'FCM Notifications',
            channelDescription: 'This channel is used for FCM notifications.',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
      );
    }
  });
  // TODO: Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkAuthAndNavigate(context),
      builder: (context, snapshot) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Future<void> _checkAuthAndNavigate(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUser?.uid)
              .toList();
          if (users.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['email'] ?? 'No email'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        userId: user.id,
                        userEmail: user['email'] ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lastMessage = "";

  _MyHomePageState() {
    _messageStreamController.listen((message) {
      setState(() {
        if (message.notification != null) {
          _lastMessage =
              'Received a notification message:'
              '\nTitle=${message.notification?.title},'
              '\nBody=${message.notification?.body},'
              '\nData=${message.data}';
        } else {
          _lastMessage = 'Received a data message: ${message.data}';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Last message from Firebase Messaging:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(_lastMessage, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
