import android.app.AppOpsManager;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.Calendar;
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
                                            Log.d(TAG, "Package: " + stat.get("packageName") + ", Time: " + stat.get("totalTimeInForeground"));
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

        Log.d(TAG, "Usage stats size: " + stats.size()); // 로그 추가

        for (UsageStats usageStat : stats) {
            if (usageStat.getTotalTimeInForeground() > 0) {
                Map<String, Object> usageMap = new HashMap<>();
                usageMap.put("packageName", usageStat.getPackageName());
                usageMap.put("totalTimeInForeground", usageStat.getTotalTimeInForeground());
                usageStats.add(usageMap);
            }
        }

        return usageStats;
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
