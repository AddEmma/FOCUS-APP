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
        const val EXTRA_PACKAGE_NAME = "package_name"
        
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

    private var blockedApps: List<String> = emptyList()
    private var endTimeMillis: Long = 0
    private val handler = Handler(Looper.getMainLooper())
    private var isMonitoring = false
    private var lastForegroundApp: String? = null
    private var launcherPackage: String? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        updateLauncherPackage()
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

    private fun updateLauncherPackage() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
        }
        val resolveInfo = packageManager.resolveActivity(intent, 0)
        launcherPackage = resolveInfo?.activityInfo?.packageName
        Log.d(TAG, "Launcher resolved to: $launcherPackage")
    }

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
                val isNewApp = foregroundApp != lastForegroundApp
                
                if (isNewApp) {
                    Log.d(TAG, "New Foreground App: $foregroundApp, shouldBlock=$isBlocked")
                    
                    // Increment blocked attempts on first detection of a blocked app
                    if (isBlocked) {
                        blockedAttempts++
                    }
                    
                    lastForegroundApp = foregroundApp
                    // Stream detection event with blocking status
                    onBlockedAttempt?.invoke(foregroundApp, blockedAttempts, isBlocked)
                }
            
                // ALWAYS block on every poll cycle — not just on app change.
                // This ensures that if the user dismisses the overlay and returns
                // to the blocked app, it gets re-blocked immediately on the next tick.
                if (isBlocked) {
                    Log.i(TAG, "!!! SHIELD ACTIVE: Blocking $foregroundApp !!!")
                    // Send user to home screen first, then show overlay
                    sendUserHome()
                    showBlockingOverlay(foregroundApp)
                    onBlockedAttempt?.invoke(foregroundApp, blockedAttempts, true)
                }
            }

            // Schedule next check (300ms for snappier interception)
            handler.postDelayed(this, 300)
        }
    }

    private fun getForegroundApp(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()

        // Source 1: Aggregated Usage Stats (Last 1 minute)
        // This is often more reliable for "Who is in front right now?" on some ROMs
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 60000, now)
        var latestStatsApp: String? = null
        var latestStatsTime: Long = 0
        
        if (stats != null) {
            for (stat in stats) {
                if (stat.lastTimeUsed > latestStatsTime) {
                    latestStatsApp = stat.packageName
                    latestStatsTime = stat.lastTimeUsed
                }
            }
        }

        // Source 2: Recent Events (Last 10 seconds)
        // Faster for detecting quick switches
        val usageEvents = usageStatsManager.queryEvents(now - 10000, now)
        val event = android.app.usage.UsageEvents.Event()
        var latestEventApp: String? = null
        var latestEventTime: Long = 0
        
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.timeStamp > latestEventTime) {
                if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED) {
                    latestEventApp = event.packageName
                    latestEventTime = event.timeStamp
                }
            }
        }

        // Resolution: Prefer Activity Events (more specific) if fresh, else use UsageStats
        val resolvedApp = if (latestEventTime > latestStatsTime - 500) latestEventApp else latestStatsApp
        
        if (resolvedApp != null) {
            Log.v(TAG, "Detection -> Stats: $latestStatsApp (${now - latestStatsTime}ms ago), " +
                  "Event: $latestEventApp (${now - latestEventTime}ms ago) -> Resolved: $resolvedApp")
        }
        
        return resolvedApp ?: latestStatsApp ?: latestEventApp
    }

    private fun shouldBlock(pkg: String): Boolean {
        // ALWAYS ALLOW: Focus app itself
        if (pkg == packageName) return false

        // ALWAYS ALLOW: The Launcher (Home Screen)
        // Use cached launcher if available, else resolve
        val launcher = launcherPackage ?: updateLauncherPackage().let { launcherPackage }
        if (pkg == launcher) return false

        // ALWAYS ALLOW: System Settings & common system UI
        if (pkg == "com.android.settings" || pkg == "com.android.systemui") return false
        
        // ALLOW: MIUI Security Center (required for permissions overlays sometimes)
        if (pkg == "com.miui.securitycenter") return false

        // BLOCK if the package IS in the blocked apps list
        val isBlockedList = blockedApps.any { it.equals(pkg, ignoreCase = true) }
        
        if (isBlockedList) {
            Log.d(TAG, "Shield check: $pkg IS BLOCKED (Matches in list of ${blockedApps.size} apps)")
        }
        
        return isBlockedList
    }

    private fun isLauncher(pkg: String): Boolean {
        return pkg == launcherPackage
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
                    Log.d(TAG, "Starting blocking session for ${blockedApps.size} apps: $blockedApps")
                    startForegroundService()
                    startMonitoring()
                    isRunning = true
                } else {
                    Log.w(TAG, "Start requested but end time $endTimeMillis is in the past!")
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
    
    fun showBlockingOverlay(pkgName: String? = null) {
        val intent = Intent(this, BlockingOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            putExtra(EXTRA_END_TIME, endTimeMillis)
            putExtra(EXTRA_PACKAGE_NAME, pkgName)
        }
        startActivity(intent)
    }

    private fun sendUserHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
    }
}

