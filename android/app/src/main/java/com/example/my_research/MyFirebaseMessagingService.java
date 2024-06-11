package com.example.my_research;

import android.app.ActivityManager;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import android.app.usage.UsageEvents;
import android.app.usage.UsageStatsManager;

import androidx.annotation.RequiresApi;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.google.gson.Gson;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MyFirebaseMessagingService extends FirebaseMessagingService {
    private static final String TAG = "MyFirebaseMsgService";

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Log.d(TAG, "From: " + remoteMessage.getFrom());

        if (remoteMessage.getData().size() > 0) {
            Log.d(TAG, "Message data payload: " + remoteMessage.getData());

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                try {
                    List<Map<String, Object>> usageStats = getUsageStats();
                    Log.d(TAG, "Usage Stats: " + usageStats.toString());

                    String currentApp = getCurrentApp();
                    Log.d(TAG, "Current App ProjectName: " + currentApp);
                    String appName = getCurrentAppName(currentApp); // 패키지 이름을 앱 이름으로 변환하여 로그
                    Log.d(TAG, "Current App Name: " + appName);


                    String packageName = currentApp; // 원하는 앱의 패키지 이름
                    long appUsageTime = getAppUsageTime(packageName);
                    appUsageTime = (appUsageTime / 1000 / 60);
//                    Log.d(TAG, "App Usage Time for " + packageName + ": " + appUsageTime);

                    // 결과를 SharedPreferences에 저장
                    saveResultsToSharedPreferences(currentApp, usageStats, appUsageTime);
                } catch (Exception e) {
                    Log.e(TAG, "Error processing usage stats", e);
                }
            } else {
                Log.e(TAG, "Usage stats are not available on this device.");
            }
        }

        if (remoteMessage.getNotification() != null) {
            Log.d(TAG, "Message Notification Body: " + remoteMessage.getNotification().getBody());
            sendNotification(remoteMessage.getNotification().getBody());
        }
    }

    private void sendNotification(String messageBody) {
        // 알림을 생성하고 보여주는 코드를 여기에 작성합니다.
    }

    private String logCurrentAppName(String currentAppPackageName) {
        String appName = FriendlyNameMapper.getFriendlyName(currentAppPackageName);
        return appName;
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
    private long getAppUsageTime(String packageName) {
        List<Map<String, Object>> usageStats = getUsageStats();

        for (Map<String, Object> usageStat : usageStats) {
            if (usageStat.get("packageName").equals(packageName)) {
                Log.d(TAG, "current totalTimeInForeground : " + usageStats.toString());
                return (long)usageStat.get("totalTimeInForeground");
            }
        }
        return 0;
    }

    private void saveResultsToSharedPreferences(String currentApp, List<Map<String, Object>> usageStats, long appUsageTime) {
        SharedPreferences prefs = getSharedPreferences("MyPrefs", Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        Gson gson = new Gson();
        editor.putString("currentApp", currentApp);
        editor.putString("usageStats", gson.toJson(usageStats));
        editor.apply();

    }
}


