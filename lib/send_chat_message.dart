import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String txt;
  final bool isCurrentUser; // 현재 사용자인지 여부를 나타내는 변수 추가

  const ChatMessage(this.txt, {Key? key, this.isCurrentUser = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start, // 위치 조정
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) // 현재 사용자가 아니면 아바타 표시
            CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Text("N", style: TextStyle(color: Colors.white)),
            ),
          if (!isCurrentUser)
            SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, // 텍스트 위치 조정
              children: [
                if (!isCurrentUser) // 현재 사용자가 아니면 이름 표시
                  Text("Dr.GPT", style: TextStyle(fontWeight: FontWeight.bold)),
                Stack(
                  children: [
                    Positioned(
                      left: isCurrentUser ? null : 0, // 삼각형 위치 조정
                      right: isCurrentUser ? 0 : null, // 삼각형 위치 조정
                      top: 10,
                      child: Transform.rotate(
                        angle: isCurrentUser ? 0.1 : -0.1, // 삼각형 회전 방향 변경
                        child: CustomPaint(
                          painter: TrianglePainter(isCurrentUser: isCurrentUser), // Painter에게 현재 사용자 여부 전달
                          child: Container(
                            height: 20,
                            width: 20,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(txt),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCurrentUser) // 현재 사용자면 아바타 오른쪽에 표시
            SizedBox(width: 10.0),
          if (isCurrentUser) // 현재 사용자면 아바타 오른쪽에 표시
            CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Text("Me", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final bool isCurrentUser;

  TrianglePainter({this.isCurrentUser = false});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.lightBlueAccent;
    Path path = Path();
    if (isCurrentUser) {
      path.moveTo(size.width, 0); // 시작점 변경
      path.lineTo(size.width / 2, size.height);
      path.lineTo(0, 0);
    } else {
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
