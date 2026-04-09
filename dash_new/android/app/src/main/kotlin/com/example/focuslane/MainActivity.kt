package com.example.focuslane

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "exact_alarm_channel"
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM))
                    }
                    result.success(true)
                }
                "canScheduleExactAlarms" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val am = getSystemService(AlarmManager::class.java)
                        result.success(am.canScheduleExactAlarms())
                    } else result.success(true)
                }
                "scheduleExact" -> {
                    val id = call.argument<Int>("id")!!
                    val title = call.argument<String>("title") ?: "Recordatorio"
                    val body = call.argument<String>("body") ?: ""
                    val at = call.argument<Long>("epochMillis")!!
                    val channelId = call.argument<String>("channelId") ?: "schedule_channel"
                    val payload = call.argument<String>("payload")

                    val intent = Intent(this, ExactAlarmReceiver::class.java).apply {
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("body", body)
                        putExtra("channelId", channelId)
                        if (payload != null) putExtra("payload", payload)
                    }
                    val flags = PendingIntent.FLAG_CANCEL_CURRENT or
                            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                    val pi = PendingIntent.getBroadcast(this, id, intent, flags)

                    val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
                    } else {
                        am.setExact(AlarmManager.RTC_WAKEUP, at, pi)
                    }
                    result.success(true)
                }
                "cancelExact" -> {
                    val id = call.argument<Int>("id")!!
                    val intent = Intent(this, ExactAlarmReceiver::class.java)
                    val flags = PendingIntent.FLAG_CANCEL_CURRENT or
                            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                    val pi = PendingIntent.getBroadcast(this, id, intent, flags)
                    val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    am.cancel(pi)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 👇 Si la Activity se abre con un payload, lo mandamos a Dart
        deliverLaunchPayload(intent?.getStringExtra("payload"))
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        deliverLaunchPayload(intent.getStringExtra("payload"))
    }

    private fun deliverLaunchPayload(payload: String?) {
        if (::channel.isInitialized && payload != null && payload.isNotEmpty()) {
            channel.invokeMethod("deliverPayload", payload)
        }
    }
}
