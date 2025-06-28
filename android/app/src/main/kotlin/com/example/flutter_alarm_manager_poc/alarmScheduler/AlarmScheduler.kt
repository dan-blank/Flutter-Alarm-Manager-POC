package com.example.flutter_alarm_manager_poc.alarmScheduler

import com.example.flutter_alarm_manager_poc.model.AlarmItem

interface AlarmScheduler {
    fun schedule(alarmItem: AlarmItem, triggerTimeInMillis: Long, behavior: String)
    fun cancel(alarmItem: AlarmItem)
}