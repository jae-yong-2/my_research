import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:my_research/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController textEditingController = TextEditingController();
  final List chat = [];
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    textEditingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void handleSubmitted(String text) {
    Logger().d(text);

    if (text.trim().isNotEmpty) {
      ChatMessage newChat = ChatMessage(text,true,true);
      setState(() {
        chat.add(newChat);
        scrollToBottom();
      });
    }
    textEditingController.clear();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: chat.length,
              itemBuilder: (context, index) {
                // 메시지 리스트의 null 체크를 여기에 추가할 수 있습니다.
                return chat[index];
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: textEditingController,
              onSubmitted: handleSubmitted,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요.',
                fillColor: Colors.grey.shade200,
                filled: true,
                border: UnderlineInputBorder(borderSide: BorderSide.none),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () => handleSubmitted(textEditingController.text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
