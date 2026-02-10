package com.example.add_focus_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class AppBlockerService : Service() {
    
    companion object {
        const val CHANNEL_ID = "app_blocker_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.example.add_focus_app.START_BLOCKING"
        const val ACTION_STOP = "com.example.add_focus_app.STOP_BLOCKING"
        const val EXTRA_BLOCKED_APPS = "blocked_apps"
        const val EXTRA_END_TIME = "end_time"
        
        const val TAG = "AppBlockerService"
        
        var isRunning = false
            private set

        // Real-time monitoring data accessible from MainActivity
        var blockedAppsList: List<String> = emptyList()
            private set
        var blockedAttempts: Int = 0
            private set
        var sessionEndTimeMillis: Long = 0
            private set

        // Listener for real-time events
        var onBlockedAttempt: ((String, Int, Boolean) -> Unit)? = null
        
        var instance: AppBlockerService? = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }
    
    override fun onDestroy() {
        instance = null
        stopMonitoring()
        isRunning = false
        blockedAppsList = emptyList()
        blockedAttempts = 0
        sessionEndTimeMillis = 0
        onBlockedAttempt = null
        super.onDestroy()
    }
    
    private var blockedApps: List<String> = emptyList()
    private var endTimeMillis: Long = 0
    private val handler = Handler(Looper.getMainLooper())
    private var isMonitoring = false
    private var lastForegroundApp: String? = null

    private val monitorRunnable = object : Runnable {
        override fun run() {
            if (!isMonitoring) {
                Log.d(TAG, "Monitoring stopped")
                return
            }

            // Check if session has ended
            if (System.currentTimeMillis() >= endTimeMillis) {
                Log.d(TAG, "Session ended, stopping service")
                stopSelf()
                return
            }

            // Check foreground app
            val foregroundApp = getForegroundApp()
            
            if (foregroundApp != null) {
                val isBlocked = shouldBlock(foregroundApp)
                
                if (foregroundApp != lastForegroundApp) {
                     Log.d(TAG, "New Foreground App: $foregroundApp, shouldBlock=$isBlocked")
                     lastForegroundApp = foregroundApp
                     // Stream detection event with blocking status
                     onBlockedAttempt?.invoke(foregroundApp, blockedAttempts, isBlocked) 
                }
            
                if (isBlocked) {
                    Log.d(TAG, "Blocking app: $foregroundApp")
                    // Force show overlay
                    showBlockingOverlay()
                    
                    // Increment attempts if it's a "fresh" block (or maybe just keep updating status)
                     if (foregroundApp != lastForegroundApp) {
                        blockedAttempts++
                    }
                    // Re-send with updated attempt count
                    onBlockedAttempt?.invoke(foregroundApp, blockedAttempts, true)
                }
            }

            // Schedule next check
            handler.postDelayed(this, 500)
        }
    }

    private fun shouldBlock(pkg: String): Boolean {
        // ALWAYS ALLOW: Focus app itself
        if (pkg == packageName) return false

        // ALWAYS ALLOW: The Launcher (Home Screen)
        if (isLauncher(pkg)) return false

        // ALWAYS ALLOW: System Settings
        if (pkg == "com.android.settings") return false

        // BLOCK if the package IS in the blocked apps list
        // Case-insensitive check just in case
        val isBlocked = blockedApps.any { it.equals(pkg, ignoreCase = true) }
        return isBlocked
    }

    private fun isLauncher(pkg: String): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
        }
        val resolveInfo = packageManager.resolveActivity(intent, 0)
        return pkg == resolveInfo?.activityInfo?.packageName
    }
    
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                blockedApps = intent.getStringArrayListExtra(EXTRA_BLOCKED_APPS) ?: emptyList()
                endTimeMillis = intent.getLongExtra(EXTRA_END_TIME, 0)
                lastForegroundApp = null
                blockedAttempts = 0
                
                // Update companion object for real-time access
                blockedAppsList = blockedApps
                sessionEndTimeMillis = endTimeMillis
                
                if (endTimeMillis > System.currentTimeMillis()) {
                    startForegroundService()
                    startMonitoring()
                    isRunning = true
                }
            }
            ACTION_STOP -> {
                stopMonitoring()
                stopSelf()
            }
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Mode",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when focus mode is active"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun startForegroundService() {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Focus Mode Active")
            .setContentText("Blocking ${blockedApps.size} apps")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
    }
    
    private fun startMonitoring() {
        isMonitoring = true
        handler.post(monitorRunnable)
    }
    
    private fun stopMonitoring() {
        isMonitoring = false
        handler.removeCallbacks(monitorRunnable)
    }
    
    private fun getForegroundApp(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 60 * 5 

        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        val event = android.app.usage.UsageEvents.Event()
        var latestForegroundApp: String? = null
        var latestEventTime: Long = 0
        
        var eventCount = 0
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            eventCount++
            
            if (event.timeStamp > latestEventTime) {
                if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED) {
                    latestForegroundApp = event.packageName
                    latestEventTime = event.timeStamp
                    Log.v(TAG, "Unfiltered candidate: ${event.packageName} at ${event.timeStamp}")
                }
            }
        }
        
        if (eventCount == 0) {
            Log.w(TAG, "No usage events found in the last 5 minutes!")
        }

        if (latestForegroundApp != null) {
            Log.d(TAG, "Resolved Foreground App: $latestForegroundApp")
            return latestForegroundApp
        }
        
        // Fallback
        return null
    }
    
    fun showBlockingOverlay() {
        val intent = Intent(this, BlockingOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            putExtra(EXTRA_END_TIME, endTimeMillis)
        }
        startActivity(intent)
    }
}
