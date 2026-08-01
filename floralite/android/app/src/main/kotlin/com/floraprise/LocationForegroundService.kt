package com.floraprise

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.floraprise.app.MainActivity
import com.floraprise.app.R
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class LocationForegroundService : Service() {
    private val CHANNEL_ID = "location_tracking_channel"
    private val NOTIFICATION_ID = 1001
    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Initialize Flutter engine for background execution
        flutterEngine = FlutterEngine(this)
        flutterEngine?.dartExecutor?.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            methodChannel = MethodChannel(messenger, "com.floraprise/location")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START_TRACKING" -> {
                val deliveryId = intent.getStringExtra("deliveryId") ?: ""
                methodChannel?.invokeMethod("startTracking", mapOf("deliveryId" to deliveryId))
            }
            "STOP_TRACKING" -> {
                methodChannel?.invokeMethod("stopTracking", null)
                stopForeground(true)
                stopSelf()
            }
            "UPDATE_NOTIFICATION" -> {
                val status = intent.getStringExtra("status") ?: "Active"
                val notification = createNotification(status)
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        flutterEngine?.destroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Delivery Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracking your delivery location"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(status: String = "Active"): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Delivery Tracking Active")
            .setContentText("Tracking your location - $status")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)

        builder.setContentIntent(pendingIntent)

        return builder.build()
    }
}
