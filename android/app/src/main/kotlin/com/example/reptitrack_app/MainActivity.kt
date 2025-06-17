// android/app/src/main/kotlin/com/example/reptitrack_app/MainActivity.kt
package com.example.reptitrack_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "background_tasks"
    private val NOTIFICATION_CHANNEL = "background_notification_check"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // バックグラウンドタスクのメソッドチャンネル設定
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "registerBackgroundTask" -> {
                    scheduleBackgroundTask()
                    result.success(true)
                }
                "isSupported" -> {
                    result.success(true)
                }
                "requestExactAlarmPermission" -> {
                    requestExactAlarmPermission()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 通知アクションのメソッドチャンネル設定
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notification_actions").setMethodCallHandler { call, result ->
            when (call.method) {
                "handleNotificationAction" -> {
                    val payload = call.argument<String>("payload")
                    handleNotificationAction(payload)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 通知チェックのメソッドチャンネル設定
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotifications" -> {
                    performNotificationCheck()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // バックグラウンドタスクのスケジュール
    private fun scheduleBackgroundTask() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, BackgroundNotificationReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 15分間隔で実行
        val intervalMillis = 15 * 60 * 1000L // 15 minutes
        val triggerAtMillis = System.currentTimeMillis() + intervalMillis

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
        } catch (e: SecurityException) {
            // Android 13+ で正確なアラーム権限が必要
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                requestExactAlarmPermission()
            }
        }
    }

    // 正確なアラーム権限のリクエスト (Android 12+)
    private fun requestExactAlarmPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (!alarmManager.canScheduleExactAlarms()) {
                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                startActivity(intent)
            }
        }
    }

    // 通知チェック処理
    private fun performNotificationCheck() {
        // Firebaseと連携してリマインダーチェックを実行
        // この実装は簡略化されており、実際にはFirebaseSDKを使用
        println("Performing background notification check")
    }

    // 通知アクションの処理
    private fun handleNotificationAction(payload: String?) {
        payload?.let {
            // ペイロードに基づいてアクションを実行
            when {
                it.startsWith("smart_feeding") -> {
                    // 食事記録画面に遷移
                    println("Handling feeding action: $it")
                }
                it.startsWith("smart_weight") -> {
                    // 体重記録画面に遷移
                    println("Handling weight action: $it")
                }
                it.startsWith("reminder_complete") -> {
                    // リマインダー完了処理
                    println("Completing reminder: $it")
                }
            }
        }
    }
}