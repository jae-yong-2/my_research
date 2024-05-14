import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/data_store.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:my_research/module/healthKit.dart';
import 'package:url_launcher/url_launcher.dart';

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
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool isFeedbackEnabled=true;

  Future<void> _saveOperateTime() async {
    if (_startTime != null && _endTime != null) {
      Map<String, dynamic> operateTime = {
        'startHour': _startTime!.hour,
        'startMinute': _startTime!.minute,
        'endHour': _endTime!.hour,
        'endMinute': _endTime!.minute,
      };

      // 'operatetime' 카테고리 아래에 시간 정보를 저장합니다.
      // 여기서 'id'는 사용자의 고유 식별자입니다.
      await DataStore().saveData(KeyValue().ID, "operatetime", operateTime);
      print("Operate time saved to Firebase");
      Fluttertoast.showToast(msg: "저장되었습니다.", gravity: ToastGravity.CENTER);
    }
  }
  Future<void> _pickStartTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay(hour: 9, minute: 0), // 기본값 설정
    );

    if (pickedTime != null && pickedTime != _startTime) {
      setState(() {
        _startTime = pickedTime;
      });
      _saveTime('startHour', pickedTime.hour);
      _saveTime('startMinute', pickedTime.minute);
    }
  }
  // 종료 시간 선택
  Future<void> _pickEndTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay(hour: 18, minute: 0), // 기본값 설정
    );

    if (pickedTime != null && pickedTime != _endTime) {
      setState(() {
        _endTime = pickedTime;
      });
      _saveTime('endHour', pickedTime.hour);
      _saveTime('endMinute', pickedTime.minute);
    }
  }

  Future<void> _saveTime(String key, int value) async {
    DataStore().saveSharedPreferencesInt(key, value);
  }

  Future<void> _loadTime() async {
    final int startHour = await DataStore().getSharedPreferencesInt("startHour") ?? 9;
    final int startMinute = await DataStore().getSharedPreferencesInt("startMinute") ?? 0;
    final int endHour = await DataStore().getSharedPreferencesInt("endHour") ?? 18;
    final int endMinute = await DataStore().getSharedPreferencesInt("endMinute") ?? 0;

    setState(() {
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }
  @override
  void initState() {
    super.initState();
    _loadTime();
    isFeedbackEnabled= true;
    initializeSettings();
  }

  void initializeSettings() async {
    bool? feedbackEnabled = await DataStore().getSharedPreferencesBool(KeyValue().ISFEEDBACK);
    if (feedbackEnabled != null) {
      setState(() {
        isFeedbackEnabled = feedbackEnabled;
      });
    }
  }

  @override
  void dispose() {
    _habitController.dispose();
    _bodyIssueController.dispose();
    super.dispose();
  }

  void _saveData() {
    // 사용자 입력을 Map 형태로 SaveData 클래스에 전달
    if((_habitController.text.isEmpty)||( _bodyIssueController.text.isEmpty)){

      Fluttertoast.showToast(msg: "모든 내용을 채워주세요.", gravity: ToastGravity.CENTER);
      return;
    }
    Map<String, dynamic> userData = {
      "습관 및 자세": _habitController.text,
      "신체 특이 사항": _bodyIssueController.text,
    };

    DataStore().saveDataProfile(KeyValue().ID,KeyValue().BODYPROFILE,userData).then((_) {
      Fluttertoast.showToast(msg: "저장되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "저장 실패: $error", gravity: ToastGravity.CENTER);
    });
    DataStore().saveSharedPreferencesString(KeyValue().HABIT_STATE,  _habitController.text);
    DataStore().saveSharedPreferencesString(KeyValue().CURRENT_BODY_ISSUE,  _bodyIssueController.text);
  }
  void _deleteData() {
    // 데이터 삭제 로직을 여기에 구현합니다.
    DataStore().deleteData(KeyValue().ID,KeyValue().BODYPROFILE).then((_) {
      Fluttertoast.showToast(msg: "삭제되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "삭제 실패: $error", gravity: ToastGravity.CENTER);
    });
  }

  void _launchURL() async {
    final Uri _url = Uri.parse('https://forms.gle/tf5X6XtqoS97eHZp9');
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  void _toggleFeedback() async {
    setState(() {
      isFeedbackEnabled = !(isFeedbackEnabled ?? true);
      DataStore().saveSharedPreferencesBool(KeyValue().ISFEEDBACK, isFeedbackEnabled!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Scaffold(
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                ElevatedButton(
                  onPressed: _pickStartTime,
                  child: Text('시작 시간 선택'),
                ),
                if (_startTime != null)
                  Text('시작 시간: ${_startTime!.format(context)}'),
                ],
                ),
                Column(children: [
                  ElevatedButton(
                    onPressed: _pickEndTime,
                    child: Text('종료 시간 선택'),
                  ),
                  if (_endTime != null)
                    Text('종료 시간: ${_endTime!.format(context)}'),
                ],
                ),

              ],
            ),

            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _saveOperateTime,
                    child: Text('시간 저장'),
                ),
                ElevatedButton(
                  onPressed: _toggleFeedback,
                  child: Text(isFeedbackEnabled! ? '피드백 가능' : '피드백 불가능'),
                ),
                ]
            ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero
                      )// primary: Colors.red, // 삭제 버튼 색상
                  ),
                  child: Text('저장하기'),

                ),
                ElevatedButton(
                  onPressed: _launchURL,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text("버그 리포트 ${KeyValue().ID}"),
                ),
                ElevatedButton(
                  onPressed: _deleteData,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero
                    )// primary: Colors.red, // 삭제 버튼 색상
                  ),
                  child: Text('삭제하기'),
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
                  stream: _dataControllerInstance.getUserRecordsStream(KeyValue().ID,KeyValue().BODYPROFILE),
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      if(data.isEmpty) {
                        print("데이터 없음");
                      }else{
                        DataStore().saveSharedPreferencesString(
                            KeyValue().HABIT_STATE, "${data.values
                            .last["습관 및 자세"]}");
                        DataStore().saveSharedPreferencesString(
                            KeyValue().CURRENT_BODY_ISSUE, "${data.values
                            .last["신체 특이 사항"]}");
                      }
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