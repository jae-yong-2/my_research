
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_research/page/Chat/chat_page.dart';
import 'package:my_research/page/profile.dart';

import 'background_service_test.dart';

class PageNavigation extends StatefulWidget {
  const PageNavigation({super.key});

  @override
  _PageNavigationState createState() => _PageNavigationState();
}

class _PageNavigationState extends State<PageNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    Profile(),
    ChatPage(),
    BackgroundServiceTest(),
  ];

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
            icon: Icon(Icons.man),
            label: '프로필',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '세팅',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
