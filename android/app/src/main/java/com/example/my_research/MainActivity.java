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

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.app/usage_stats";
    private static final String TAG = "MainActivity";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        if (call.method.equals("getUsageStats")) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                if (hasUsageStatsPermission()) {
                                    List<Map<String, Object>> usageStats = getUsageStats();
                                    if (usageStats.isEmpty()) {
                                        Log.e(TAG, "No usage stats found");
                                    } else {
                                        for (Map<String, Object> stat : usageStats) {
                                            Log.d(TAG, "Package: " + stat.get("packageName") + ", Time: " + stat.get("totalTimeInForeground") + ", AppName: " + stat.get("appName"));
                                        }
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
                        } else {
                            result.notImplemented();
                        }
                    }
                }
        );
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getUsageStats() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        Calendar calendar = Calendar.getInstance();
        long endTime = calendar.getTimeInMillis();
        calendar.add(Calendar.DAY_OF_YEAR, -1);
        long startTime = calendar.getTimeInMillis();

        List<UsageStats> stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime);
        List<Map<String, Object>> usageStats = new ArrayList<>();
        PackageManager pm = getPackageManager();

        for (UsageStats usageStat : stats) {
            if (usageStat.getTotalTimeInForeground() > 0) {
                Map<String, Object> usageMap = new HashMap<>();
                String packageName = usageStat.getPackageName();
                usageMap.put("packageName", packageName);
                usageMap.put("totalTimeInForeground", usageStat.getTotalTimeInForeground());
                try {
                    ApplicationInfo appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
                    String appName = pm.getApplicationLabel(appInfo).toString();
                    usageMap.put("appName", appName);
                } catch (PackageManager.NameNotFoundException e) {
                    Log.e(TAG, "Package not found: " + packageName, e);
                    usageMap.put("appName", getFriendlyNameForPackage(packageName));
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

        for (UsageStats usageStat : stats) {
            if (usageStat.getTotalTimeInForeground() > 0) {
                Map<String, Object> usageMap = new HashMap<>();
                String packageName = usageStat.getPackageName();
                usageMap.put("packageName", packageName);
                usageMap.put("totalTimeInForeground", usageStat.getTotalTimeInForeground());
                try {
                    ApplicationInfo appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
                    String appName = pm.getApplicationLabel(appInfo).toString();
                    usageMap.put("appName", appName);
                } catch (PackageManager.NameNotFoundException e) {
                    Log.e(TAG, "Package not found: " + packageName, e);
                    usageMap.put("appName", getFriendlyNameForPackage(packageName));
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
                        return processInfo.processName;
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

    private String getFriendlyNameForPackage(String packageName) {
        Map<String, String> friendlyNames = new HashMap<>();

        // Google Apps
        friendlyNames.put("com.google.android.youtube", "YouTube");
        friendlyNames.put("com.google.android.apps.maps", "Google Maps");
        friendlyNames.put("com.android.chrome", "Google Chrome");
        friendlyNames.put("com.google.android.gm", "Gmail");
        friendlyNames.put("com.android.vending", "Google Play Store");

        // Meta (formerly Facebook) Apps
        friendlyNames.put("com.facebook.katana", "Facebook");
        friendlyNames.put("com.instagram.android", "Instagram");
        friendlyNames.put("com.whatsapp", "WhatsApp");
        friendlyNames.put("com.facebook.orca", "Messenger");

        // Naver Apps
        friendlyNames.put("com.nhn.android.search", "Naver");
        friendlyNames.put("com.nhn.android.navercafe", "Naver Cafe");
        friendlyNames.put("com.nhn.android.band", "Naver Band");
        friendlyNames.put("com.linecorp.line", "LINE");
        friendlyNames.put("com.naver.linewebtoon", "Naver Webtoon");
        friendlyNames.put("com.nhn.android.blog", "Naver Blog");

        // Kakao Apps
        friendlyNames.put("com.kakao.talk", "KakaoTalk");
        friendlyNames.put("com.kakao.story", "KakaoStory");
        friendlyNames.put("com.kakao.bus", "KakaoBus");
        friendlyNames.put("com.locnall.KimGiSa", "KakaoMap");
        friendlyNames.put("com.kakao.musikk", "Melon");
        friendlyNames.put("com.kakaobank.channel", "KakaoBank");

        // Coupang
        friendlyNames.put("com.coupang.mobile", "Coupang");

        // Samsung Apps
        friendlyNames.put("com.sec.android.app.samsungapps", "Samsung Apps");
        friendlyNames.put("com.samsung.android.messaging", "Samsung Messages");
        friendlyNames.put("com.samsung.android.app.sbrowser", "Samsung Internet");

        // Banking Apps
        friendlyNames.put("com.kbstar.kbbank", "KB Star Banking");
        friendlyNames.put("nh.smart", "NH Smart Banking");
        friendlyNames.put("com.shinhan.sbanking", "Shinhan Bank SOL");
        friendlyNames.put("com.ibk.android.banking", "IBK One Bank");
        friendlyNames.put("com.wooribank.smart.npib", "Woori Bank");
        friendlyNames.put("com.hanabank.ebk.channel.android.hananbank", "Hana Bank");

        // Shopping Apps
        friendlyNames.put("com.ebay.kr.auction", "Auction");
        friendlyNames.put("com.wemakeprice", "WeMakePrice");
        friendlyNames.put("com.ssg", "SSG");
        friendlyNames.put("com.tmon", "TMON");

        // Social Media Apps
        friendlyNames.put("com.twitter.android", "Twitter");
        friendlyNames.put("com.snapchat.android", "Snapchat");
        friendlyNames.put("com.zhiliaoapp.musically", "TikTok");
        friendlyNames.put("com.linkedin.android", "LinkedIn");
        friendlyNames.put("com.pinterest", "Pinterest");
        friendlyNames.put("com.reddit.frontpage", "Reddit");
        friendlyNames.put("org.telegram.messenger", "Telegram");
        friendlyNames.put("com.discord", "Discord");
        friendlyNames.put("com.tencent.mm", "WeChat");
        friendlyNames.put("jp.naver.line.android", "LINE");
        friendlyNames.put("com.viber.voip", "Viber");
        friendlyNames.put("com.tumblr", "Tumblr");
        friendlyNames.put("com.clubhouse.android", "Clubhouse");
        friendlyNames.put("org.thoughtcrime.securesms", "Signal");
        friendlyNames.put("com.sina.weibo", "Weibo");

        // 기타
        friendlyNames.put("com.nike.ntc", "Nike Training Club");
        friendlyNames.put("kr.co.vcnc.android.couple", "Between");
        friendlyNames.put("com.daum.mobile", "Daum");
        friendlyNames.put("com.nexon.devcat.marble", "Marble");
        friendlyNames.put("com.supercell.clashofclans", "Clash of Clans");

        if (friendlyNames.containsKey(packageName)) {
            return friendlyNames.get(packageName);
        } else {
            return "Unknown";
        }
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
}
