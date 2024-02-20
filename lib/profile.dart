import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:my_research/saveData.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20), // 전체적인 패딩 추가
      child: Scaffold(
        body: Column(
          children: [
            SizedBox(height: 10), // 여백 추가
            TextFormField(
              decoration: InputDecoration(
                labelText: '평소 습관 및 자세',
                helperText: '업무나 일상 중 운동 습관 및 자세를 입력하세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                labelText: '신체 특이 사항',
                helperText: '평소 통증이 있거나 불편한 부위에 대해서 입력하세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () {
                // 데이터 처리 로직
                SaveData().saveData();
              },
              child: Text('저장하기'),
              style: ElevatedButton.styleFrom(
                // primary: Colors.blue, // 버튼 색상
                // onPrimary: Colors.white, // 텍스트 색상
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // 데이터 처리 로직
                SaveData().deleteData();
              },
              child: Text('삭제하기'),
              style: ElevatedButton.styleFrom(
                // primary: Colors.blue, // 버튼 색상
                // onPrimary: Colors.white, // 텍스트 색상
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}