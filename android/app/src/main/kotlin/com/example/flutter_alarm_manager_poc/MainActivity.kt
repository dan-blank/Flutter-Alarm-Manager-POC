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

        FlutterEngineCache.getInstance().put(ENGINE_ID,flutterEngine)

        alarmScheduler = AlarmSchedulerImpl(this)


        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    Log.d(TAG, "Method Channel Invoked, Alarm Scheduling")
                    scheduleAlarm()
                    result.success(null)
                }
                "questionnaireFinished" -> {
                    val args = call.arguments as? Map<String, Any>
                    val status = args?.get("status") as? String

                    when (status) {
                        "answered" -> {
                            val data = args["data"] as? Map<String, Int>
                            val feeling = data?.get("feeling")
                            val sleepQuality = data?.get("sleepQuality")
                            Log.d(TAG, "Questionnaire answered: Feeling=$feeling, Sleep Quality=$sleepQuality")
                        }
                        "declined" -> {
                            Log.d(TAG, "Questionnaire was declined by the user.")
                        }
                        "snoozed" -> {
                            Log.d(TAG, "Questionnaire was snoozed.")
                        }
                        else -> {
                            Log.w(TAG, "Unknown questionnaire status: $status")
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleAlarm() {

        val alarmItem = AlarmItem(
            id = 1,
            message = "Alarm has been ringing"
        )
        alarmScheduler.schedule(alarmItem)
    }
}
