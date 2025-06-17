// android/app/src/main/kotlin/com/example/reptitrack_app/BackgroundNotificationReceiver.kt
package com.example.reptitrack_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.AlarmManager
import android.app.PendingIntent
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class BackgroundNotificationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "com.example.reptitrack_app.NOTIFICATION_CHECK" -> {
                performBackgroundNotificationCheck(context)
            }
            Intent.ACTION_BOOT_COMPLETED -> {
                // 端末再起動時にアラームを再設定
                rescheduleAlarm(context)
            }
        }
    }

    private fun performBackgroundNotificationCheck(context: Context) {
        try {
            // バックグラウンドでの通知チェック処理
            println("Background notification check triggered")

            // 次回のアラームを設定
            rescheduleAlarm(context)

            // 実際の通知チェック処理（簡略化）
            // ここでFirebaseからリマインダーデータを取得し、
            // 期限切れのリマインダーがあれば通知を表示

        } catch (e: Exception) {
            println("Error in background notification check: ${e.message}")
        }
    }

    private fun rescheduleAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, BackgroundNotificationReceiver::class.java).apply {
            action = "com.example.reptitrack_app.NOTIFICATION_CHECK"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

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
            println("Failed to schedule alarm: ${e.message}")
        }
    }
}