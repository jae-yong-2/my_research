import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataStore {
  final databaseRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getUserRecordsStream(String id, String category) {
    print(databaseRef.child("$id/$category").onValue);
    return databaseRef.child("$id/$category").onValue;
  }

  Future<void> saveData( String id, String category, Map<String, dynamic> userData) async {
    await databaseRef.child("$id/$category").set(userData ?? "0");
  }
  Future<void> saveIntData( String id, String category, int userData) async {
    await databaseRef.child("$id/$category").set(userData ?? "0");
  }
  Future<void> saveDataProfile( String id, String category, Map<String, dynamic> userData) async {
    await databaseRef.child("$id/$category").push().set(userData);
  }

  Future<Map<String, dynamic>?> getData(String id, String category) async {
    DataSnapshot snapshot = await databaseRef.child("$id/$category").get();
    if (snapshot.exists) {
      // 데이터가 존재하면, Map 형태로 변환하여 반환
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      // 데이터가 존재하지 않으면, null을 반환
      return null;
    }
  }
  Future<Map<String, dynamic>?> getIntData(String id, String category) async {
    DataSnapshot snapshot = await databaseRef.child("$id/$category").get();
    if (snapshot.exists) {
      // 데이터가 존재하면, Map 형태로 변환하여 반환
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      // 데이터가 존재하지 않으면, null을 반환
      return null;
    }
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
    await prefs.setString(key, value ?? "0");
  }

  Future<void> saveSharedPreferencesInt(String key, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value ?? 0);
  }

  Future<String?> getSharedPreferencesString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // 'myKey'에 저장된 값을 가져옵니다. 값이 없으면 null을 반환합니다.
    final myValue = prefs.getString(key);
    return myValue;
  }
  Future<int?> getSharedPreferencesInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // 'myKey'에 저장된 값을 가져옵니다. 값이 없으면 null을 반환합니다.
    final myValue = prefs.getInt(key);
    return myValue;
  }

  Future<void> saveSharedPreferencesBool(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value ?? false);
  }
  Future<bool?> getSharedPreferencesBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // 'myKey'에 저장된 값을 가져옵니다. 값이 없으면 null을 반환합니다.
    final myValue = prefs.getBool(key);
    return myValue;
  }
}
