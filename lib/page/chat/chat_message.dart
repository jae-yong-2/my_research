import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String txt;
  final bool isMyTurn;
  final bool isCurrentUser;

  const ChatMessage(this.txt,this.isMyTurn, this.isCurrentUser, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: isMyTurn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyTurn) // 현재 사용자가 아니면 왼쪽에 아바타 표시
            CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Text("N", style: TextStyle(color: Colors.white)),
            ),
          if (!isMyTurn)
            SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: isMyTurn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMyTurn) // 현재 사용자가 아니면 이름 표시
                  Text("Dr.GPT", style: TextStyle(fontWeight: FontWeight.bold)),
                if (isMyTurn) // 현재 사용자가 아니면 이름 표시
                  Padding(padding: EdgeInsets.only(right: 8.0),child:
                  Text("나", style: TextStyle(fontWeight: FontWeight.bold))),
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
                      padding: EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration:
                        BoxDecoration(
                          color: isCurrentUser?Colors.lightBlueAccent:Colors.amber[800],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(txt),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isMyTurn) // 현재 사용자면 오른쪽에 아바타 표시
            SizedBox(width: 10.0),
          if (isMyTurn)
            Padding(
              padding: EdgeInsets.only(top: 8.0), // 원하는 패딩 값으로 설정
              child: CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Text("Me", style: TextStyle(color: Colors.white)),
              ),
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
