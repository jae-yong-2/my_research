import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SaveData {
  final databaseRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getUserRecordsStream() {
    return databaseRef.child("userRecords").onValue;
  }

  Future<void> saveData(Map<String, dynamic> userData) async {
    await databaseRef.child("userRecords").push().set(userData);
  }

  Future<void> deleteData() async {
    await databaseRef.child("key").remove();
  }

  // 사용자 기록을 가져오는 함수
  Future<Map<String, dynamic>?> getData() async {
    try {
      // "userRecords" 아래에 있는 모든 기록을 읽습니다.
      DatabaseEvent event = await databaseRef.child("userRecords").once();
      Map<String, dynamic>? data = event.snapshot.value as Map<String, dynamic>?;
      return data;
    } catch (e) {
      print("Error fetching data: $e");
      return null;
    }
  }
  // SharedPreferences에 디바이스 ID를 저장하는 함수
  /* saveDeviceId 함수는 SharedPreferences 인스턴스를 비동기적으로 가져온 다음,
     setString 메서드를 사용하여 'key'라는 키로 deviceId 값을 저장합니다.
     이 함수를 호출하여 디바이스 ID를 SharedPreferences에 저장할 수 있습니다.
   */

  Future<void> saveDeviceId(String deviceId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('key', deviceId);
  }
}

