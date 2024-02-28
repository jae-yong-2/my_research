import 'package:firebase_database/firebase_database.dart';

class DataContorller {
  final databaseRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getUserRecordsStream(String id, String category) {
    return databaseRef.child("$id/$category").onValue;
  }

  Future<void> saveData( String id, String category, Map<String, dynamic> userData) async {
    await databaseRef.child("$id/$category").push().set(userData);
  }

  Future<void> deleteData(String id, String category) async {
    // 지정된 경로에서 데이터를 시간 순으로 정렬
    Query query = databaseRef.child("$id/$category").orderByChild('timestamp');

    // 가장 최근의 데이터 하나만 가져오기
    DataSnapshot snapshot = await query.limitToLast(1).get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      String keyToDelete = data.keys.first;

      // 해당 데이터 삭제
      await databaseRef.child('$id/$category/$keyToDelete').remove();
      print("최신 데이터가 삭제되었습니다.");
    } else {
      print("삭제할 데이터가 없습니다.");
    }
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
