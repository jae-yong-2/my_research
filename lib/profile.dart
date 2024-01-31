import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20), // 전체적인 패딩 추가
      child: Scaffold(
        body: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: '성별',
                helperText: '성별을 입력하세요',
                border: OutlineInputBorder(), // 테두리 스타일 적용
              ),
            ),
            SizedBox(height: 10), // 여백 추가
            TextFormField(
              decoration: InputDecoration(
                labelText: '나이',
                helperText: '나이를 숫자로 입력하세요',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                labelText: '키 (cm)',
                helperText: '키를 cm 단위로 입력하세요',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                labelText: '몸무게 (kg)',
                helperText: '몸무게를 kg 단위로 입력하세요',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
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
              },
              child: Text('저장하기'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue, // 버튼 색상
                onPrimary: Colors.white, // 텍스트 색상
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
