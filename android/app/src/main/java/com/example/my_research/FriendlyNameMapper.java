package com.example.my_research;

import java.util.HashMap;
import java.util.Map;

public class FriendlyNameMapper {
    private static final Map<String, String> friendlyNames = new HashMap<>();

    static {
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
    }

    public static String getFriendlyName(String packageName) {
        String name = friendlyNames.getOrDefault(packageName, "Unknown");
        System.out.println(name);
        return name;
    }
}
