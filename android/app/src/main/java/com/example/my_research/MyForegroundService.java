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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.app.usage.UsageStats;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import android.app.AlarmManager;

import android.app.PendingIntent;
import java.util.Calendar;

// FriendlyNameMapper import 추가
import com.example.my_research.FriendlyNameMapper;

public class MyForegroundService extends Service {
    private static final String CHANNEL_ID = "ForegroundServiceChannel";
    private static final String TAG = "MyForegroundService";
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
        // 최초 실행 시 startForeground 호출
        String currentApp = getCurrentApp();
        int currentUsageTime = getAppUsageTime(currentApp);
        Notification initialNotification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Current App in Use")
                .setContentText("Package: " + currentApp + "\n")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build();
        startForeground(11, initialNotification);

        // 알림 업데이트를 위한 Runnable 정의
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        // 서비스 로직을 여기에 추가
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Intent broadcastIntent = new Intent(this, ServiceRestartReceiver.class);
        sendBroadcast(broadcastIntent);
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        super.onTaskRemoved(rootIntent);
        sendSwipeNotification();
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
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(serviceChannel);
            }
        }
    }

//    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
//    private List<Map<String, Object>> getUsageStats() {
//        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
//        Calendar calendar = Calendar.getInstance();
//        long endTime = calendar.getTimeInMillis();
//        calendar.set(Calendar.HOUR_OF_DAY, 0);
//        calendar.set(Calendar.MINUTE, 0);
//        calendar.set(Calendar.SECOND, 0);
//        calendar.set(Calendar.MILLISECOND, 0);
//        long startTime = calendar.getTimeInMillis();
//
//        List<UsageStats> stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_BEST, startTime, endTime);
//        Map<String, Map<String, Object>> usageStatsMap = new HashMap<>();
//        PackageManager pm = getPackageManager();
//
//        for (UsageStats usageStat : stats) {
//            if (usageStat.getTotalTimeInForeground() > 0) {
//                String packageName = usageStat.getPackageName();
//                long totalTimeInForeground = usageStat.getTotalTimeInForeground() / 1000 / 60; // Convert milliseconds to minutes
//
//                if (usageStatsMap.containsKey(packageName)) {
//                    // If the package already exists, update the existing time
//                    Map<String, Object> usageMap = usageStatsMap.get(packageName);
//                    long existingTime = (long) usageMap.get("totalTimeInForeground");
//                    usageMap.put("totalTimeInForeground", existingTime + totalTimeInForeground);
//                } else {
//                    // If the package doesn't exist, create a new entry
//                    Map<String, Object> usageMap = new HashMap<>();
//                    usageMap.put("packageName", packageName);
//                    usageMap.put("totalTimeInForeground", totalTimeInForeground);
//                    try {
//                        ApplicationInfo appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
//                        String appName = pm.getApplicationLabel(appInfo).toString();
//                        usageMap.put("appName", appName);
//                    } catch (PackageManager.NameNotFoundException e) {
//                        usageMap.put("appName", FriendlyNameMapper.getFriendlyName(packageName));
//                    }
//                    usageStatsMap.put(packageName, usageMap);
//                }
//            }
//        }
//        return new ArrayList<>(usageStatsMap.values());
//    }

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

        UsageEvents usageEvents = usageStatsManager.queryEvents(startTime, endTime);
        UsageEvents.Event event = new UsageEvents.Event();
        Map<String, Long> usageMap = new HashMap<>();
        Map<String, Long> lastForegroundTimes = new HashMap<>();
        PackageManager pm = getPackageManager();

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event);

            String packageName = event.getPackageName();
            if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                lastForegroundTimes.put(packageName, event.getTimeStamp());
            } else if (event.getEventType() == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                if (lastForegroundTimes.containsKey(packageName)) {
                    long startTimeInForeground = lastForegroundTimes.get(packageName);
                    long timeInForeground = event.getTimeStamp() - startTimeInForeground;

                    usageMap.put(packageName, usageMap.getOrDefault(packageName, 0L) + timeInForeground);
                    lastForegroundTimes.remove(packageName);
                }
            }
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (Map.Entry<String, Long> entry : usageMap.entrySet()) {
            String packageName = entry.getKey();
            long totalTimeInForeground = entry.getValue() / 1000 / 60; // Convert milliseconds to minutes

            Map<String, Object> usageStats = new HashMap<>();
            usageStats.put("packageName", packageName);
            usageStats.put("totalTimeInForeground", totalTimeInForeground);

            try {
                ApplicationInfo appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
                String appName = pm.getApplicationLabel(appInfo).toString();
                usageStats.put("appName", appName);
            } catch (PackageManager.NameNotFoundException e) {
                usageStats.put("appName", packageName);
            }

            result.add(usageStats);
        }
        return result;
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
    private int getAppUsageTime(String packageName) {
        List<Map<String, Object>> usageStats = getUsageStats();
        Log.d(TAG, "Usage Stats: " + usageStats.toString());

        for (Map<String, Object> usageStat : usageStats) {
            if (usageStat.get("packageName").equals(packageName)) {
                long usageTime = ((Number) usageStat.get("totalTimeInForeground")).longValue();
                return (int) usageTime; // long을 int로 변환
            }
        }
        return 0;
    }
    public void sendSwipeNotification() {
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Swipe Notification Channel", NotificationManager.IMPORTANCE_HIGH);
            notificationManager.createNotificationChannel(channel);
        }

        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE);

        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("앱이 종료되었습니다.")
                .setContentText("알람을 눌러 앱을 실행시켜주시기 바랍니다.")
                .setSmallIcon(R.drawable.warning) // 적절한 아이콘 리소스 사용
                .setPriority(NotificationCompat.PRIORITY_HIGH) // 높은 우선순위 설정
                .setContentIntent(pendingIntent)
                .setAutoCancel(false)
                .setOngoing(true) // 영구 알림 설정
                .build();

// 각 알림에 고유한 ID 사용
        notificationManager.notify(10, notification);
    }


    public static void cancelRepeatingNotification(Context context) {
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        Intent intent = new Intent(context, NotificationReceiver.class);
        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        alarmManager.cancel(pendingIntent);
    }
}
