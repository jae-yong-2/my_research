import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_research/foreground_service.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Column(
          children: [IconButton(
              icon: Icon(Icons.send, color: Colors.blue),
              onPressed: () => ForegroundServiceAPI(),
            ),Text("profile")
          ],
        )
      ),
    );
  }
}
