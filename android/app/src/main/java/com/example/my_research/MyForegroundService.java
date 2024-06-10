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

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

public class MyForegroundService extends Service {
    private static final String CHANNEL_ID = "ForegroundServiceChannel";
    private static final String TAG = "MyForegroundService";
    private Handler handler = new Handler();
    private Runnable updateTask;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        startForegroundService();
    }

    private void startForegroundService() {
        updateTask = new Runnable() {
            @Override
            public void run() {
                String currentApp = getCurrentApp();
                Log.d(TAG, "Current App Package: " + currentApp);

                Notification notification = new NotificationCompat.Builder(MyForegroundService.this, CHANNEL_ID)
                        .setContentTitle("Current App in Use")
                        .setContentText("Package: " + currentApp)
                        .setSmallIcon(R.mipmap.ic_launcher)
                        .setOngoing(true)
                        .build();

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(1, notification);
                } else {
                    startForeground(1, notification);
                }

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

    private String getCurrentApp() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long endTime = System.currentTimeMillis();
        long beginTime = endTime - 1000 * 10;

        UsageEvents usageEvents = usageStatsManager.queryEvents(beginTime, endTime);
        UsageEvents.Event event = new UsageEvents.Event();
        String currentApp = "Unknown";
        long lastUsedAppTime = 0;

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event);
            if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                if (event.getTimeStamp() > lastUsedAppTime) {
                    lastUsedAppTime = event.getTimeStamp();
                    currentApp = event.getPackageName();
                }
            }
        }

        return currentApp;
    }
}
