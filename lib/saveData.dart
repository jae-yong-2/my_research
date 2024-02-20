import 'package:firebase_database/firebase_database.dart';

class SaveData{
  // Firebase Realtime Database의 참조를 생성합니다.
  final databaseRef = FirebaseDatabase.instance.ref();

  // 데이터베이스에 값을 저장하는 함수입니다.
  Future<void> saveData() async {
    await databaseRef.set({"key": 1});
  }

  // 데이터베이스에서 값을 삭제하는 함수입니다.
  Future<void> deleteData() async {
    await databaseRef.child("key").remove();
    // 또는 setValue(null)을 사용하여 삭제할 수도 있습니다.
    // await databaseRef.child("key").setValue(null);
  }
}