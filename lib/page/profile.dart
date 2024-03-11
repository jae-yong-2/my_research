import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_research/data/category.dart';
import 'package:my_research/data/data_store.dart';
import 'package:firebase_database/firebase_database.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _habitController = TextEditingController();
  final TextEditingController _bodyIssueController = TextEditingController();
  final DataStore _dataControllerInstance = DataStore();
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();


  @override
  void dispose() {
    _habitController.dispose();
    _bodyIssueController.dispose();
    super.dispose();
  }

  void _saveData() {
    // 사용자 입력을 Map 형태로 SaveData 클래스에 전달
    Map<String, dynamic> userData = {
      "습관 및 자세": _habitController.text,
      "신체 특이 사항": _bodyIssueController.text,
    };

    DataStore().saveDataProfile(Category().ID,Category().BODYPROFILE,userData).then((_) {
      Fluttertoast.showToast(msg: "저장되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "저장 실패: $error", gravity: ToastGravity.CENTER);
    });
  }

  void _update() {
    // 사용자 입력을 Map 형태로 SaveData 클래스에 전달
    var userData = {
      "습관 및 자세": _habitController.text,
      "신체 특이 사항": _bodyIssueController.text,
    };
    DataStore().deleteData(Category().ID,Category().BODYPROFILE).then((_) {
    }).catchError((error) {
      Fluttertoast.showToast(msg: "삭제 실패: $error", gravity: ToastGravity.CENTER);
    });
    DataStore().saveData(Category().ID,Category().BODYPROFILE,userData).then((_) {
    }).catchError((error) {
      Fluttertoast.showToast(msg: "저장 실패: $error", gravity: ToastGravity.CENTER);
    });
    Fluttertoast.showToast(msg: "변경되었습니다.", gravity: ToastGravity.CENTER);
  }


  void _deleteData() {
    // 데이터 삭제 로직을 여기에 구현합니다.
    DataStore().deleteData(Category().ID,Category().BODYPROFILE).then((_) {
      Fluttertoast.showToast(msg: "삭제되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "삭제 실패: $error", gravity: ToastGravity.CENTER);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Scaffold(
        body: Column(
          children: [
            SizedBox(height: 10),
            TextFormField(
              controller: _habitController,
              decoration: InputDecoration(
                labelText: '평소 습관 및 자세',
                helperText: '업무나 일상 중 운동 습관 및 자세를 입력하세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _bodyIssueController,
              decoration: InputDecoration(
                labelText: '신체 특이 사항',
                helperText: '평소 통증이 있거나 불편한 부위에 대해서 입력하세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveData,
                  child: Text('저장하기'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _deleteData,
                  style: ElevatedButton.styleFrom(
                    // primary: Colors.red, // 삭제 버튼 색상
                  ),
                  child: Text('삭제하기'),
                ),
                ElevatedButton(
                  onPressed:_update,
                  style: ElevatedButton.styleFrom(
                    // primary: Colors.red, // 삭제 버튼 색상
                  ),
                  child: Text('변경하기'),
                ),
              ],
            ),



            //특이사항을 가져오는 코드
            SizedBox(height: 8), Expanded(
              child: Container(
                // Define the box decoration
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                // Define some padding inside the box
                padding: EdgeInsets.all(8),
                // Define a max height for the container
                constraints: BoxConstraints(maxHeight: 300),
                // Use a ListView.builder for a scrollable list
                child: StreamBuilder<DatabaseEvent>(
                  stream: _dataControllerInstance.getUserRecordsStream(Category().ID,Category().BODYPROFILE),
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          String key = data.keys.elementAt(index);
                          Map entry = data[key];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4), // Add margin for each card
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('습관: ${entry['습관 및 자세']}'),
                                  SizedBox(height: 8), // Space between habit and body issue
                                  Text('특이사항: ${entry['신체 특이 사항']}'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return Center(child: Text('No user records found.'));
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}