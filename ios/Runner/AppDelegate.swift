// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import FirebaseCore
import BackgroundTasks

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let backgroundTaskIdentifier = "com.example.reptitrack-app.notification-check"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // バックグラウンドタスクの登録
        registerBackgroundTasks()

        // 通知権限のリクエスト
        requestNotificationPermissions()

        // バックグラウンドタスクのメソッドチャンネル設定
        setupBackgroundTasksChannel()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // バックグラウンドタスクの登録
    private func registerBackgroundTasks() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: backgroundTaskIdentifier,
                using: nil
            ) { task in
                self.handleBackgroundNotificationCheck(task: task as! BGAppRefreshTask)
            }
        }
    }

    // 通知権限のリクエスト
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission denied")
            }
        }
    }

    // バックグラウンドタスクの実行
    @available(iOS 13.0, *)
    private func handleBackgroundNotificationCheck(task: BGAppRefreshTask) {
        // バックグラウンドタスクの期限を設定
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // 次のバックグラウンドタスクをスケジュール
        scheduleBackgroundAppRefresh()

        // 通知チェック処理を実行
        performNotificationCheck { success in
            task.setTaskCompleted(success: success)
        }
    }

    // 次のバックグラウンドタスクをスケジュール
    private func scheduleBackgroundAppRefresh() {
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15分後

            do {
                try BGTaskScheduler.shared.submit(request)
                print("Background app refresh scheduled")
            } catch {
                print("Could not schedule app refresh: \(error)")
            }
        }
    }

    // 通知チェック処理
    private func performNotificationCheck(completion: @escaping (Bool) -> Void) {
        // Flutterエンジンを使用して通知チェックを実行
        let controller = window?.rootViewController as? FlutterViewController
        let methodChannel = FlutterMethodChannel(
            name: "background_notification_check",
            binaryMessenger: controller?.binaryMessenger ?? FlutterEngine().binaryMessenger
        )

        methodChannel.invokeMethod("checkNotifications", arguments: nil) { result in
            if let success = result as? Bool {
                completion(success)
            } else {
                completion(false)
            }
        }
    }

    // バックグラウンドタスクのメソッドチャンネル設定
    private func setupBackgroundTasksChannel() {
        let controller = window?.rootViewController as? FlutterViewController
        let methodChannel = FlutterMethodChannel(
            name: "background_tasks",
            binaryMessenger: controller?.binaryMessenger ?? FlutterEngine().binaryMessenger
        )

        methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "registerBackgroundTask":
                self.registerBackgroundTasks()
                result(true)
            case "scheduleBackgroundTask":
                self.scheduleBackgroundAppRefresh()
                result(true)
            case "isSupported":
                if #available(iOS 13.0, *) {
                    result(true)
                } else {
                    result(false)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // アプリがバックグラウンドに移行したときの処理
    override func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleBackgroundAppRefresh()
    }

    // アプリがフォアグラウンドに復帰したときの処理
    override func applicationWillEnterForeground(_ application: UIApplication) {
        // 通知バッジをクリア
        UIApplication.shared.applicationIconBadgeNumber = 0

        // 即座に通知チェックを実行
        performNotificationCheck { success in
            print("Foreground notification check completed: \(success)")
        }
    }

    // プッシュ通知の設定
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Firebase Messaging にデバイストークンを設定
        print("Device token registered: \(deviceToken)")
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }

    // 通知がタップされたときの処理
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // 通知のペイロードを処理
        if let payload = userInfo["payload"] as? String {
            handleNotificationPayload(payload)
        }

        completionHandler()
    }

    // 通知ペイロードの処理
    private func handleNotificationPayload(_ payload: String) {
        let controller = window?.rootViewController as? FlutterViewController
        let methodChannel = FlutterMethodChannel(
            name: "notification_actions",
            binaryMessenger: controller?.binaryMessenger ?? FlutterEngine().binaryMessenger
        )

        methodChannel.invokeMethod("handleNotificationAction", arguments: payload)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // フォアグラウンドで通知を受信したときの処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでも通知を表示
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
}

//import Flutter
//import UIKit
//
//@main
//@objc class AppDelegate: FlutterAppDelegate {
//  override func application(
//    _ application: UIApplication,
//    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//  ) -> Bool {
//    GeneratedPluginRegistrant.register(with: self)
//    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//  }
//}
