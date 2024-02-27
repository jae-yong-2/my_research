import 'package:firebase_database/firebase_database.dart';

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
}
