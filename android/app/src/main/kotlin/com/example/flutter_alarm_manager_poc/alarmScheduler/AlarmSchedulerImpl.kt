package com.example.flutter_alarm_manager_poc.alarmScheduler

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.example.flutter_alarm_manager_poc.model.AlarmItem
import com.example.flutter_alarm_manager_poc.receiver.AlarmReceiver

class AlarmSchedulerImpl(private val context: Context) : AlarmScheduler {

    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    // The schedule method now takes the pre-calculated trigger time.
    override fun schedule(alarmItem: AlarmItem, triggerTimeInMillis: Long) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("ALARM_ID", alarmItem.id)
            putExtra("ALARM_MESSAGE", alarmItem.message)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmItem.id,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT // Use UPDATE_CURRENT to ensure extras are updated
        )

        // No more time calculation here. Just use the value from Flutter.
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerTimeInMillis,
            pendingIntent
        )
    }

    override fun cancel(alarmItem: AlarmItem) {
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmItem.id,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        pendingIntent?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
    }
}
