package com.example.my_research;

import android.app.ActivityManager;
import android.app.AppOpsManager;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;
import android.os.Bundle;
import android.app.NotificationManager;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.google.firebase.FirebaseApp;
import java.util.Calendar;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;


import com.example.my_research.MyFirebaseMessagingService;
public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.app/usage_stats";
    private static final String TAG = "MainActivity";
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        FirebaseApp.initializeApp(this);
        FlutterEngineCache.getInstance().put("my_engine_id", flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        if (call.method.equals("getUsageStats")) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                if (hasUsageStatsPermission()) {
                                    List<Map<String, Object>> usageStats = getUsageStats();
                                    if (usageStats.isEmpty()) {
                                        Log.e(TAG, "No usage stats found");
                                    } else {
//                                        for (Map<String, Object> stat : usageStats) {
//                                            Log.d(TAG, "Package: " + stat.get("packageName") + ", Time: " + stat.get("totalTimeInForeground") + ", AppName: " + stat.get("appName"));
//                                        }
                                    }
                                    result.success(usageStats);
                                } else {
                                    requestUsageStatsPermission();
                                    result.error("PERMISSION_DENIED", "Usage stats permission is denied", null);
                                }
                            } else {
                                result.error("UNAVAILABLE", "Usage stats are not available on this device.", null);
                            }
                        } else if (call.method.equals("getCurrentApp")) {
                            String currentApp = getCurrentApp();
                            result.success(currentApp);
                        } else if (call.method.equals("getTop10Apps")) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                if (hasUsageStatsPermission()) {
                                    List<Map<String, Object>> top10Apps = getTop10Apps();
                                    result.success(top10Apps);
                                } else {
                                    requestUsageStatsPermission();
                                    result.error("PERMISSION_DENIED", "Usage stats permission is denied", null);
                                }
                            } else {
                                result.error("UNAVAILABLE", "Usage stats are not available on this device.", null);
                            }
                        } else if(call.method.equals("getAppUsageTime")) {
                            String packageName = call.argument("packageName");
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                if (hasUsageStatsPermission()) {
                                    long usageTime = getAppUsageTime(packageName);
                                    result.success(usageTime);
                                } else {
                                    requestUsageStatsPermission();
                                    result.error("PERMISSION_DENIED", "Usage stats permission is denied", null);
                                }
                            } else {
                                result.error("UNAVAILABLE", "Usage stats are not available on this device.", null);
                            }
                        } else {
                            result.notImplemented();
                        }
                    }
                });
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), FOREGROUND_SERVICE_CHANNEL)
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        if (call.method.equals("startForegroundService")) {
                            startForegroundService();
                            result.success(null);
                        } else {
                            result.notImplemented();
                        }
                    }
                });
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getUsageStats() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        Calendar calendar = Calendar.getInstance();
        long endTime = calendar.getTimeInMillis();
        // Set the start time to today's midnight
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
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
                    usageMap.put("appName", FriendlyNameMapper.getFriendlyName(packageName));
                }
                usageStats.add(usageMap);
            }
        }

        return usageStats;
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
        Set<String> seenPackages = new HashSet<>();

        for (UsageStats usageStat : stats) {
            if (usageStat.getTotalTimeInForeground() > 0) {
                String packageName = usageStat.getPackageName();

                // Exclude "One UI 홈"
                if (packageName.equals("com.sec.android.app.launcher")) {
                    continue;
                }

                if (seenPackages.contains(packageName)) {
                    continue; // Skip duplicates
                }
                seenPackages.add(packageName);

                Map<String, Object> usageMap = new HashMap<>();
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
        List<Map<String, Object>> usageStats = getUsageStats();
        Log.d(TAG, "Usage Stats: " + usageStats.toString());

        for (Map<String, Object> usageStat : usageStats) {
            if (usageStat.get("packageName").equals(packageName)) {
                return (int)usageStat.get("totalTimeInForeground");
            }
        }
        return 0;
    }
    private boolean hasUsageStatsPermission() {
        AppOpsManager appOps = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), getPackageName());
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    private void requestUsageStatsPermission() {
        Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
        startActivity(intent);
        Toast.makeText(this, "Please grant Usage Stats permission", Toast.LENGTH_LONG).show();
    }
//-----------------
private static final String FOREGROUND_SERVICE_CHANNEL = "com.example.app/foreground_service";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.cancel(0);
        startForegroundService();
    }

    private void startForegroundService() {
        Intent serviceIntent = new Intent(this, MyForegroundService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }
    }
}
