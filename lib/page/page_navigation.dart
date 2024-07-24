
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_research/page/Chat/chat_page.dart';
import 'package:my_research/page/profile.dart';

import 'feedback.dart';

class PageNavigation extends StatefulWidget {
  final int initialIndex;

  const PageNavigation({super.key, required this.initialIndex});

  @override
  _PageNavigationState createState() => _PageNavigationState();
}

class _PageNavigationState extends State<PageNavigation> {
  late int _selectedIndex = 0;
  final List<Widget> _pages = [
    ChatPage(),
    Profile(),
    FeedbackPage(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _selectedIndex = widget.initialIndex;
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: -4,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '알람 기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.man),
            label: '프로필',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback,size: 10,),
            label: "설정",
          ),

        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
