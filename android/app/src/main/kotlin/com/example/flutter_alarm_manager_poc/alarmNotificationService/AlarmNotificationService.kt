package com.example.flutter_alarm_manager_poc.alarmNotificationService

import com.example.flutter_alarm_manager_poc.model.AlarmItem

interface AlarmNotificationService {
    fun createNotificationChannels()
    fun showNotification(alarmItem: AlarmItem, behavior: String)
    fun cancelNotification(id: Int)
}