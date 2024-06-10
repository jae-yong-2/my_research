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

                    List<Map<String, Object>> top10Apps = getTop10Apps();
//                    Log.d(TAG, "Top 10 Apps: " + top10Apps.toString());

                    String packageName = currentApp; // 원하는 앱의 패키지 이름
                    long appUsageTime = getAppUsageTime(packageName);
                    appUsageTime = (appUsageTime / 1000 / 60);
//                    Log.d(TAG, "App Usage Time for " + packageName + ": " + appUsageTime);

                    // 결과를 SharedPreferences에 저장
                    saveResultsToSharedPreferences(currentApp, usageStats, top10Apps, appUsageTime);
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
        calendar.add(Calendar.DAY_OF_YEAR, -1);
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


    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getTop10Apps() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        Calendar calendar = Calendar.getInstance();
        long endTime = calendar.getTimeInMillis();
        calendar.add(Calendar.DAY_OF_YEAR, -7);
        long startTime = calendar.getTimeInMillis();

        List<UsageStats> stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime);
        List<Map<String, Object>> usageStats = new ArrayList<>();
        PackageManager pm = getPackageManager();

        for (UsageStats usageStat : stats) {
            if (usageStat.getTotalTimeInForeground() > 0) {
                Map<String, Object> usageMap = new HashMap<>();
                String packageName = usageStat.getPackageName();
                usageMap.put("packageName", packageName);
                usageMap.put("totalTimeInForeground", usageStat.getTotalTimeInForeground() / 1000 / 60); // Convert milliseconds to minutes
                try {
                    ApplicationInfo appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
                    String appName = pm.getApplicationLabel(appInfo).toString();
                    usageMap.put("appName", appName);
                } catch (PackageManager.NameNotFoundException e) {
                    String name = FriendlyNameMapper.getFriendlyName(packageName);
                    usageMap.put("appName", name);
                }
                usageStats.add(usageMap);
            }
        }

        Collections.sort(usageStats, new Comparator<Map<String, Object>>() {
            @Override
            public int compare(Map<String, Object> o1, Map<String, Object> o2) {
                return ((Long) o2.get("totalTimeInForeground")).compareTo((Long) o1.get("totalTimeInForeground"));
            }
        });

        return usageStats.subList(0, Math.min(10, usageStats.size()));
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

    private String getCurrentApp() {
        ActivityManager am = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            List<ActivityManager.RunningAppProcessInfo> runningProcesses = am.getRunningAppProcesses();
            if (runningProcesses != null && !runningProcesses.isEmpty()) {
                for (ActivityManager.RunningAppProcessInfo processInfo : runningProcesses) {
                    if (processInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
                        // Return the first package name from the pkgList
                        if (processInfo.pkgList != null && processInfo.pkgList.length > 0) {
                            return processInfo.pkgList[0];
                        }
                    }
                }
            }
        } else {
            List<ActivityManager.RunningTaskInfo> taskInfo = am.getRunningTasks(1);
            if (taskInfo != null && !taskInfo.isEmpty()) {
                return taskInfo.get(0).topActivity.getPackageName();
            }
        }
        return "Unknown";
    }


    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private long getAppUsageTime(String packageName) {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        Calendar calendar = Calendar.getInstance();

        // 현재 시간을 설정
        long endTime = calendar.getTimeInMillis();

        // 하루의 시작 시간을 설정
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();

        // 하루 단위로 앱 사용 시간을 조회
        List<UsageStats> stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime);

        // 주어진 패키지 이름에 해당하는 사용 시간 반환
        for (UsageStats usageStat : stats) {
            if (usageStat.getPackageName().equals(packageName)) {
                return usageStat.getTotalTimeInForeground();
            }
        }
        return 0;
    }

    private void saveResultsToSharedPreferences(String currentApp, List<Map<String, Object>> usageStats, List<Map<String, Object>> top10Apps, long appUsageTime) {
        SharedPreferences prefs = getSharedPreferences("MyPrefs", Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        Gson gson = new Gson();

        editor.putString("currentApp", currentApp);
        editor.putString("usageStats", gson.toJson(usageStats));
        editor.putString("top10Apps", gson.toJson(top10Apps));
        editor.putLong("appUsageTime", appUsageTime);
        System.out.println("---------------save_data---------------");
        editor.apply();

        String currentApp1 = prefs.getString("currentApp", "Unknown");
        String usageStatsJson1 = prefs.getString("usageStats", "[]");
        String top10AppsJson1 = prefs.getString("top10Apps", "[]");
        long appUsageTime1 = prefs.getLong("appUsageTime", 0);

        Log.d(TAG, "currentApp : "+currentApp1);
        Log.d(TAG, "appUsageTime : "+appUsageTime1);
//        Log.d(TAG, "usageStats : "+usageStatsJson1);
        Log.d(TAG, "top10Apps : "+top10AppsJson1);

        System.out.println("---------------save_data---------------");

    }
}


