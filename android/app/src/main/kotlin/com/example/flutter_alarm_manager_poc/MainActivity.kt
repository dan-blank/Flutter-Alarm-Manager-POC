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
    private val TAG = "POC"

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
                    // 1. Extract the trigger time from the arguments.
                    val triggerTime = call.argument<Long>("triggerTime")
                    if (triggerTime != null) {
                        Log.d(TAG, "Method Channel: Scheduling alarm for time: $triggerTime")
                        // 2. Create an AlarmItem and schedule it.
                        val alarmItem = AlarmItem(id = 1, message = "Time for your check-in!")
                        alarmScheduler.schedule(alarmItem, triggerTime)
                        result.success(null)
                    } else {
                        Log.e(TAG, "Method Channel: 'triggerTime' argument was null.")
                        result.error("INVALID_ARGUMENT", "triggerTime cannot be null", null)
                    }
                }
                // No changes needed for the 'questionnaireFinished' handler on this side,
                // as its logic is now entirely in Flutter. We can remove it for clarity.
                else -> result.notImplemented()
            }
        }
    }
}
