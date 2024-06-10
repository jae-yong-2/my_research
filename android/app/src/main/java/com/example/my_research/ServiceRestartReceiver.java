package com.example.my_research;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class ServiceRestartReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        // 서비스가 종료되었을 때 다시 시작
        context.startService(new Intent(context, MyForegroundService.class));
    }
}
