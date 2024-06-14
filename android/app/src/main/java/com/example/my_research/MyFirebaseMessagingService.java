package com.example.my_research;

import android.app.PendingIntent;

import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import androidx.core.app.NotificationCompat;
import android.content.Intent;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import android.app.usage.UsageEvents;

import androidx.annotation.RequiresApi;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.google.gson.Gson;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import android.os.Handler;
import android.os.Looper;


import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;

public class MyFirebaseMessagingService extends FirebaseMessagingService {
    private static final String TAG = "MyFirebaseMsgService";
    private static final String CHANNEL_ID = "ForegroundServiceChannel";
    private static final String CHANNEL = "com.example.my_research/fcm";

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Log.d(TAG, "From: " + remoteMessage.getFrom());
        String currentApp = "Unknown";
        String packageName = "Unknown";
        int appUsageTime = 0;
        String appName = "Unknown";

        // Check if the app is running

        if (remoteMessage.getData().size() > 0) {
            Log.d(TAG, "Message data payload: " + remoteMessage.getData());

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                try {
                    List<Map<String, Object>> usageStats = getUsageStats();
//                    Log.d(TAG, "Usage Stats: " + usageStats.toString());
                    currentApp = getCurrentApp();
//                    Log.d(TAG, "Current App ProjectName: " + currentApp);
                    appName = getCurrentAppName(currentApp); // 패키지 이름을 앱 이름으로 변환하여 로그
//                    Log.d(TAG, "Current App Name: " + appName);

                    packageName = currentApp; // 원하는 앱의 패키지 이름
                    appUsageTime = getAppUsageTime(packageName);
                    // Log.d(TAG, "App Usage Time for " + packageName + ": " + appUsageTime);

                    // 결과를 SharedPreferences에 저장
//                    saveResultsToSharedPreferences(currentApp, usageStats, appUsageTime, appName);
                    // 데이터를 Flutter로 전달
                    // 데이터를 Flutter로 전달
                    sendToFlutter(currentApp, usageStats, appUsageTime, appName);


                } catch (Exception e) {
                    Log.e(TAG, "Error processing usage stats", e);
                }
            } else {
                Log.e(TAG, "Usage stats are not available on this device.");
            }
        }
        if (remoteMessage.getData().size() > 0) {

                sendNotification(appName, appUsageTime);
        } else {
            Log.d(TAG, "No notification payload and no data payload");
        }

    }
    //앱 백그라운드에서 완전히 종료되면 강제 실행



    private void sendNotification(String currentApp, int currentUsageTime) {

        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Firebase Message Channel", NotificationManager.IMPORTANCE_HIGH);
            notificationManager.createNotificationChannel(channel);
        }
        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE);

        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Current App in Use")
                .setContentText("Package: " + currentApp + "\n" + "Time: " + currentUsageTime/60 + "시간 " + currentUsageTime%60 + "분")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent) // 알림 클릭 시 실행될 인텐트 설정
                .setAutoCancel(true) // 알림 클릭 시 자동으로 삭제되도록 설정
                .build();

        // 알림을 업데이트합니다.
        notificationManager.notify(11, notification);
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
                    Map<String, Object> usageMap = usageStatsMap.get(packageName);
                    long existingTime = (long) usageMap.get("totalTimeInForeground");
                    usageMap.put("totalTimeInForeground", existingTime + totalTimeInForeground);
                } else {
                    Map<String, Object> usageMap = new HashMap<>();
                    usageMap.put("packageName", packageName);
                    usageMap.put("totalTimeInForeground", totalTimeInForeground);
//                    try {
//                        ApplicationInfo appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
//                        String appName = pm.getApplicationLabel(appInfo).toString();
//                        usageMap.put("appName", appName);
//                    } catch (PackageManager.NameNotFoundException e) {
//                        usageMap.put("appName", FriendlyNameMapper.getFriendlyName(packageName));
//                    }
                    usageStatsMap.put(packageName, usageMap);
                }
            }
        }
        return new ArrayList<>(usageStatsMap.values());
    }

    private String getCurrentAppName(String packageName) {
        PackageManager pm = getPackageManager();
        try {
            ApplicationInfo appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
            return pm.getApplicationLabel(appInfo).toString();
        } catch (PackageManager.NameNotFoundException e) {
            return FriendlyNameMapper.getFriendlyName(packageName);
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
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
//        Log.d(TAG, "Usage Stats: " + usageStats.toString());

        for (Map<String, Object> usageStat : usageStats) {
            if (usageStat.get("packageName").equals(packageName)) {
                long usageTime = ((Number) usageStat.get("totalTimeInForeground")).longValue();
                return (int) usageTime; // long을 int로 변환
            }
        }
        return 0;
    }


    private void saveResultsToSharedPreferences(String currentApp, List<Map<String, Object>> usageStats, int appUsageTime, String appName) {
        SharedPreferences prefs = getSharedPreferences("MyPrefs", Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        Gson gson = new Gson();
        editor.putString("currentApp", currentApp);
        editor.putString("currentAppName", appName);
        editor.putInt("appUsageTime", appUsageTime);
        editor.putString("usageStats", gson.toJson(usageStats));

        editor.apply();

        Log.d(TAG, "----------------------------------------------------------");
        // 추가된 확인 로그
        Log.d(TAG, "Saved currentApp: " + prefs.getString("currentApp", "N/A"));
        Log.d(TAG, "Saved currentAppName: " + prefs.getString("currentAppName", "N/A"));
        Log.d(TAG, "Saved appUsageTime: " + prefs.getInt("appUsageTime", -1));
        Log.d(TAG, "Saved usageStats: " + prefs.getString("usageStats", "N/A"));

        Log.d(TAG, "--------------------save android data---------------------");
    }
    private void sendToFlutter(String currentApp, List<Map<String, Object>> usageStats, int appUsageTime, String appName) {
        Handler mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.post(() -> {
            FlutterEngine flutterEngine = FlutterEngineCache.getInstance().get("my_engine_id");
            if (flutterEngine != null) {
                MethodChannel methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
                Map<String, Object> data = new HashMap<>();
                data.put("currentApp", currentApp);
                data.put("currentAppName", appName);
                data.put("appUsageTime", appUsageTime);
                data.put("usageStats", usageStats);
                Log.d(TAG, "-----------------------------------------");
                Log.d(TAG, "Sending : "+ data);
                String jsonData = new Gson().toJson(data);

                methodChannel.invokeMethod("usageStats", jsonData);
            }
        });
    }

}
