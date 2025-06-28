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
    // --- Define unique Channel IDs for each behavior ---
    private val CHANNEL_ID_VIBRATE_AND_SOUND = "alarm_channel_vibrate_sound"
    private val CHANNEL_ID_VIBRATE_ONLY = "alarm_channel_vibrate_only"
    private val CHANNEL_ID_SILENT = "alarm_channel_silent"

    private val notificationManager: NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannels()
    }

    override fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 1. Channel for Vibrate and Sound
            val vibrateAndSoundChannel = NotificationChannel(
                CHANNEL_ID_VIBRATE_AND_SOUND,
                "Alarms (Vibrate and Sound)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for alarms with sound and vibration."
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
                // Default sound is enabled with IMPORTANCE_HIGH
            }

            // 2. Channel for Vibrate Only
            val vibrateOnlyChannel = NotificationChannel(
                CHANNEL_ID_VIBRATE_ONLY,
                "Alarms (Vibrate Only)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for alarms with vibration only."
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
                setSound(null, null) // Explicitly disable sound for this channel
            }

            // 3. Channel for Silent
            val silentChannel = NotificationChannel(
                CHANNEL_ID_SILENT,
                "Alarms (Silent)",
                NotificationManager.IMPORTANCE_HIGH // Still high to show as a heads-up notification
            ).apply {
                description = "Channel for silent alarms."
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(false) 
                setSound(null, null)   
            }

            // --- Register all channels with the system ---
            notificationManager.createNotificationChannel(vibrateAndSoundChannel)
            notificationManager.createNotificationChannel(vibrateOnlyChannel)
            notificationManager.createNotificationChannel(silentChannel)
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

        // --- Determine which channel to use based on the behavior string ---
        val channelId = when (behavior.lowercase()) {
            "vibrate" -> CHANNEL_ID_VIBRATE_ONLY
            "silent" -> CHANNEL_ID_SILENT
            "vibrateandsound" -> CHANNEL_ID_VIBRATE_AND_SOUND
            else -> CHANNEL_ID_VIBRATE_AND_SOUND // Default case
        }


        // --- Build the notification using the selected channel ID ---
        val notificationBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.notification_bell)
            .setContentTitle("Alarm")
            .setContentText(alarmItem.message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setOngoing(true)
            .setAutoCancel(false)

        val notification = notificationBuilder.build()

        // The system now handles sound/vibration based on the channel
        notificationManager.notify(alarmItem.id, notification)
    }

    override fun cancelNotification(id: Int) {
        notificationManager.cancel(id)
    }
}