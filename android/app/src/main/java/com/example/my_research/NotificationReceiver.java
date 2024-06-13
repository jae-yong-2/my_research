package com.example.my_research;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class NotificationReceiver extends BroadcastReceiver {
    private static final String TAG = "NotificationReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "Broadcast received, sending notification...");
        MyForegroundService myService = new MyForegroundService();
        myService.sendSwipeNotification();
    }
}
