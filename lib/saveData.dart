import 'package:firebase_database/firebase_database.dart';

class SaveData {
  // Firebase Realtime Database의 참조를 생성합니다.
  final databaseRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getUserRecordsStream() {
    // "userRecords" 노드의 스트림을 반환합니다.
    return databaseRef.child("userRecords").onValue;
  }

  // 데이터베이스에 사용자의 기록을 저장하는 함수입니다.
  Future<void> saveData(Map<String, dynamic> userData) async {
    // "userRecords" 아래에 새 레코드를 추가합니다.
    // 여기서 push() 메소드는 고유한 키를 자동으로 생성합니다.
    await databaseRef.child("userRecords").push().set(userData);
  }

  // 데이터베이스에서 값을 삭제하는 함수입니다.
  Future<void> deleteData() async {
    // 특정 기록을 삭제하려면 해당 기록의 정확한 경로를 지정해야 합니다.
    // 예: databaseRef.child("userRecords/{recordId}").remove();
    await databaseRef.child("key").remove();
    // 또는 setValue(null)을 사용하여 삭제할 수도 있습니다.
    // await databaseRef.child("key").setValue(null);
  }
}
