import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataStore {
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
  Future<void> saveSharedPreferencesString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> saveSharedPreferencesInt(String key, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
}
