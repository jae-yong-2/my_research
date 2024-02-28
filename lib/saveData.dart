import 'package:firebase_database/firebase_database.dart';

class SaveData {
  final databaseRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getUserRecordsStream(String id, String category) {
    return databaseRef.child("$id/$category").onValue;
  }

  Future<void> saveData( String id, String category, Map<String, dynamic> userData) async {
    await databaseRef.child("$id/$category").push().set(userData);
  }

  Future<void> deleteData(String id, String category) async {
    await databaseRef.child("$id/$category").remove();
  }

  // 사용자 기록을 가져오는 함수
  Future<Map<String, dynamic>?> getData(String id, String category) async {
    try {
      // "userRecords" 아래에 있는 모든 기록을 읽습니다.
      DatabaseEvent event = await databaseRef.child("$id/$category").once();
      Map<String, dynamic>? data = event.snapshot.value as Map<String, dynamic>?;
      return data;
    } catch (e) {
      print("Error fetching data: $e");
      return null;
    }
  }
}
