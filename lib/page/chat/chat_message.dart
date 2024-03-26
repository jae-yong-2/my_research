import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String txt;
  final bool isMyTurn;
  final bool isCurrentUser;

  const ChatMessage(this.txt,this.isMyTurn, this.isCurrentUser, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Expanded(
      child: Column(
        crossAxisAlignment: isMyTurn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMyTurn) // 현재 사용자가 아니면 이름 표시
            Text("Dr.GPT", style: TextStyle(fontWeight: FontWeight.bold)),
          if (isMyTurn) // 현재 사용자면 이름 표시
            Text("나", style: TextStyle(fontWeight: FontWeight.bold)),
          Stack(
            children: [
              Positioned(
                left: isMyTurn ? null : 0,
                right: isMyTurn ? 0 : null,
                top: 10,
                child: Transform.rotate(
                  angle: isMyTurn ? 0.1 : -0.1,
                  child: CustomPaint(
                    painter: TrianglePainter(isMyTurn,isCurrentUser),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 10.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.lightBlueAccent : Colors.amber[800],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(txt, softWrap: true), // 텍스트가 자동으로 줄바꿈되도록 설정
                ),
              ),
            ],
          ),
        ],
      ),
    );

  }
}

class TrianglePainter extends CustomPainter {
  final bool isCurrentUser;
  final bool isMyTurn;

  TrianglePainter(this.isMyTurn, this.isCurrentUser);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = (isCurrentUser?Colors.lightBlueAccent:Colors.amber[800])!;
    Path path = Path();
    if (isCurrentUser) {
      path.moveTo(size.width, 0);
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
