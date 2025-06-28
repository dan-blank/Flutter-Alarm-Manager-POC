package com.example.flutter_alarm_manager_poc.alarmNotificationService

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.flutter_alarm_manager_poc.R
import com.example.flutter_alarm_manager_poc.activity.AlarmActivity
import com.example.flutter_alarm_manager_poc.model.AlarmItem

class AlarmNotificationServiceImpl(private val context: Context) : AlarmNotificationService {
    private val CHANNEL_ID = "alarm_channel"
    private val notificationManager: NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannel()
    }

    override fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Alarm Channel"
            val descriptionText = "Channel for Alarm Notifications"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setBypassDnd(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableLights(true)
                enableVibration(true) // Vibrate is enabled by default on the channel
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun showNotification(alarmItem: AlarmItem, behavior: String) {
        val fullScreenIntent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS 

            putExtra("ALARM_ID", alarmItem.id)
            putExtra("ALARM_MESSAGE", alarmItem.message)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            alarmItem.id,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.notification_bell)
            .setContentTitle("Alarm")
            .setContentText(alarmItem.message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setOngoing(true)
            .setAutoCancel(false)

        // --- Configure notification based on the behavior string ---
        when (behavior) {
            "Vibrate" -> {
                // The channel has vibration enabled, so we only need to remove the sound.
                notificationBuilder.setSound(null)
            }
            "Silent" -> {
                // Remove both sound and vibration.
                notificationBuilder.setSound(null)
                notificationBuilder.setVibrate(null)
            }
            "VibrateAndSound" -> {
                // Do nothing, let the channel's default behavior (high importance) take over.
            }
        }

        val notification = notificationBuilder.build()

        notificationManager.cancel(alarmItem.id)
        notificationManager.notify(alarmItem.id, notification)
    }

    override fun cancelNotification(id: Int) {
        notificationManager.cancel(id)
    }
}