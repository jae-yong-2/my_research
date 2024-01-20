import 'package:flutter/material.dart';

class ReceiveChatMessage extends StatelessWidget {
  final String txt;
  const ReceiveChatMessage(this.txt, {Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    String text="";
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blueGrey,
            child: Text("N", style: TextStyle(color: Colors.white)),
          ),
          SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dr.GPT", style: TextStyle(fontWeight: FontWeight.bold)),
                Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 10,
                      child: Transform.rotate(
                        angle: -0.1,
                        child: CustomPaint(
                          painter: TrianglePainter(),
                          child: Container(
                            height: 20,
                            width: 20,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0,right: 8.0),
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
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.lightBlueAccent;
    Path path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
