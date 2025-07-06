// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/background_notification_service.dart';
import 'services/local_notification_service.dart';
import 'services/notification_customization_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/navigation/main_navigation_screen.dart';

void main() async {
  // Flutter初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // テスト環境かどうかをチェック
  bool isTestEnvironment =
      const bool.fromEnvironment('dart.vm.product') == false;

  // テスト環境でProviderの型チェックを無効化
  if (isTestEnvironment) {
    Provider.debugCheckInvalidValueType = null;
  }

  // Firebaseの初期化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ローカル通知サービスの初期化
  await LocalNotificationService().initialize();

  // バックグラウンド通知サービスの初期化
  await BackgroundNotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late NotificationCustomizationService _customizationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BackgroundNotificationService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // 通知カスタマイズサービスの初期化
      _customizationService = NotificationCustomizationService();
      await _customizationService.initialize();
    } catch (e) {
      debugPrint('Error initializing services: $e');
      // フォールバック処理
      _customizationService = NotificationCustomizationService();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // アプリがバックグラウンドに移行
        debugPrint('App moved to background');
        break;
      case AppLifecycleState.resumed:
        // アプリがフォアグラウンドに復帰
        debugPrint('App resumed from background');
        // 通知チェックを実行
        _checkPendingNotifications();
        break;
      case AppLifecycleState.detached:
        // アプリが終了
        BackgroundNotificationService.dispose();
        break;
      default:
        break;
    }
  }

  Future<void> _checkPendingNotifications() async {
    // アプリ復帰時に未処理の通知をチェック
    try {
      // バックグラウンドで発生した通知をチェック（パブリックメソッドを使用）
      await BackgroundNotificationService.checkDueNotifications();
    } catch (e) {
      debugPrint('Error checking pending notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        // 通知カスタマイズサービスをProviderに追加
        Provider<NotificationCustomizationService>.value(
          value: _customizationService,
        ),
      ],
      child: Consumer2<AuthService, SettingsService>(
        builder: (ctx, auth, settings, _) => MaterialApp(
          title: 'ReptiTrack',
          theme: _buildTheme(),
          home:
              auth.currentUser == null ? AuthScreen() : MainNavigationScreen(),
          routes: {
            '/auth': (ctx) => AuthScreen(),
            '/main': (ctx) => MainNavigationScreen(),
          },
          // アプリ全体でのエラーハンドリング
          builder: (context, child) {
            return _AppErrorHandler(child: child);
          },
          // デバッグバナーを非表示（本番環境でのみ）
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }

  /// アプリのテーマ設定
  ThemeData _buildTheme() {
    return ThemeData(
      primaryColor: Color(0xFF388087),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // カラースキーム設定
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF388087),
        brightness: Brightness.light,
      ),

      // AppBarテーマ
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),

      // BottomNavigationBarのテーマ設定
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),

      // FloatingActionButtonテーマ
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      // ElevatedButtonテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // 入力フィールドテーマ
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }
}

// アプリ全体のエラーハンドリング
class _AppErrorHandler extends StatelessWidget {
  final Widget? child;

  const _AppErrorHandler({this.child});

  @override
  Widget build(BuildContext context) {
    return child ?? Container();
  }
}

// バックグラウンドタスクのエントリーポイント（iOS用）
@pragma('vm:entry-point')
void backgroundTaskHandler() async {
  // バックグラウンドでの通知チェック処理
  try {
    await BackgroundNotificationService.checkDueNotifications(); // パブリックメソッドを使用
    debugPrint('Background notification check completed');
  } catch (e) {
    debugPrint('Background task error: $e');
  }
}

// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
