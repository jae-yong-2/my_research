package com.example.my_research;

import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.app.usage.UsageEvents;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import java.util.ArrayList;

import java.util.Collections;
import java.util.Comparator;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import java.util.Calendar;

// FriendlyNameMapper import 추가
import com.example.my_research.FriendlyNameMapper;

public class MyForegroundService extends Service {
    private static final String CHANNEL_ID = "ForegroundServiceChannel";
    private static final String TAG = "MyForegroundService";
    private Handler handler = new Handler();
    private Runnable updateTask;
    private NotificationManager notificationManager;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        startForegroundService();
    }

    private void startForegroundService() {
        updateTask = new Runnable() {
            @Override
            public void run() {
                String currentApp = getCurrentApp();
                String currentUsageTime = getAppUsageTime(currentApp);
                Log.d(TAG, "Current App Package: " + currentApp);

                Notification notification = new NotificationCompat.Builder(MyForegroundService.this, CHANNEL_ID)
                        .setContentTitle("Current App in Use")
                        .setContentText("Package: " + currentApp + "\n" + "Time: " + currentUsageTime)
                        .setSmallIcon(R.mipmap.ic_launcher)
                        .setOngoing(true)
                        .build();

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(1, notification);
                } else {
                    startForeground(1, notification);
                }

                // Update the notification content instead of starting a new foreground service
                notificationManager.notify(1, notification);

                handler.postDelayed(this, 60000); // 1분마다 업데이트
            }
        };

        handler.post(updateTask);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        // 서비스 로직을 여기에 추가
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        handler.removeCallbacks(updateTask);
        Intent broadcastIntent = new Intent(this, ServiceRestartReceiver.class);
        sendBroadcast(broadcastIntent);
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        super.onTaskRemoved(rootIntent);
        handler.removeCallbacks(updateTask);
        Intent broadcastIntent = new Intent(this, ServiceRestartReceiver.class);
        sendBroadcast(broadcastIntent);
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Foreground Service Channel",
                    NotificationManager.IMPORTANCE_HIGH
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(serviceChannel);
            }
        }
    }
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getUsageStats() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        Calendar calendar = Calendar.getInstance();
        long endTime = calendar.getTimeInMillis();
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();

        List<UsageStats> stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime);
        Map<String, Map<String, Object>> usageStatsMap = new HashMap<>();
        PackageManager pm = getPackageManager();

        for (UsageStats usageStat : stats) {
            if (usageStat.getTotalTimeInForeground() > 0) {
                String packageName = usageStat.getPackageName();
                long totalTimeInForeground = usageStat.getTotalTimeInForeground() / 1000 / 60; // Convert milliseconds to minutes

                if (usageStatsMap.containsKey(packageName)) {
                    // If the package already exists, update the existing time
                    Map<String, Object> usageMap = usageStatsMap.get(packageName);
                    long existingTime = (long) usageMap.get("totalTimeInForeground");
                    usageMap.put("totalTimeInForeground", existingTime + totalTimeInForeground);
                } else {
                    // If the package doesn't exist, create a new entry
                    Map<String, Object> usageMap = new HashMap<>();
                    usageMap.put("packageName", packageName);
                    usageMap.put("totalTimeInForeground", totalTimeInForeground);
                    try {
                        ApplicationInfo appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
                        String appName = pm.getApplicationLabel(appInfo).toString();
                        usageMap.put("appName", appName);
                    } catch (PackageManager.NameNotFoundException e) {
                        usageMap.put("appName", FriendlyNameMapper.getFriendlyName(packageName));
                    }
                    usageStatsMap.put(packageName, usageMap);
                }
            }
        }
        return new ArrayList<>(usageStatsMap.values());
    }
    private String getCurrentApp() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long endTime = System.currentTimeMillis();
        long beginTime = endTime - 1000 * 60 * 60; // Check for the past hour

        UsageEvents usageEvents = usageStatsManager.queryEvents(beginTime, endTime);
        UsageEvents.Event event = new UsageEvents.Event();
        String currentPackageName = null;

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event);
            if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                currentPackageName = event.getPackageName();
            }
        }

        return currentPackageName != null ? currentPackageName : "Unknown";
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private String getAppUsageTime(String packageName) {
        List<Map<String, Object>> usageStats = getUsageStats();
        Log.d(TAG, "Usage Stats: " + usageStats.toString());

        for (Map<String, Object> usageStat : usageStats) {
            if (usageStat.get("packageName").equals(packageName)) {
                return usageStat.get("totalTimeInForeground") + "분";
            }
        }
        return "0분";
    }
}
