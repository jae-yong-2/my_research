import 'package:firebase_database/firebase_database.dart';

class DataContorller {
  final databaseRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getUserRecordsStream(String id, String category) {
    print(databaseRef.child("$id/$category").onValue);
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
  Future<void> update( String id, String category, Map<String, dynamic> userData) async {
    deleteData(id, category);
    saveData(id, category, userData);
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

}
