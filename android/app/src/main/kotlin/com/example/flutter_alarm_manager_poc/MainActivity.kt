package com.example.flutter_alarm_manager_poc

import android.util.Log
import com.example.flutter_alarm_manager_poc.alarmScheduler.AlarmScheduler
import com.example.flutter_alarm_manager_poc.alarmScheduler.AlarmSchedulerImpl
import com.example.flutter_alarm_manager_poc.model.AlarmItem
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val ENGINE_ID="alarm_manager_engine"
    private val CHANNEL = "com.example/alarm_manager"
    private val TAG = "POC-MainActivity"

    private lateinit var alarmScheduler: AlarmScheduler


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

                FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
        alarmScheduler = AlarmSchedulerImpl(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val triggerTime = call.argument<Long>("triggerTime")
                    // Receive the behavior string from Flutter, defaulting if not provided.
                    val behavior = call.argument<String>("behavior") ?: "VibrateAndSound"

                    if (triggerTime != null) {
                        Log.d(TAG, "Method Channel: Scheduling alarm for time: $triggerTime with behavior: $behavior")
                        val alarmItem = AlarmItem(id = 1, message = "Time for your check-in!")
                        // Pass the behavior to the scheduler.
                        alarmScheduler.schedule(alarmItem, triggerTime, behavior)
                        result.success(null)
                    } else {
                        Log.e(TAG, "Method Channel: 'triggerTime' argument was null.")
                        result.error("INVALID_ARGUMENT", "triggerTime cannot be null", null)
                    }
                }
                "cancelAlarm" -> {
                    Log.d(TAG, "Method Channel: Cancelling alarm")
                    // Use the static ID for cancellation.
                    val alarmItem = AlarmItem(id = 1, message = "")
                    alarmScheduler.cancel(alarmItem)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}