import 'dart:convert';
// import 'dart:html';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:my_research/Const.dart';
import 'package:my_research/chat_message.dart';
import 'package:http/http.dart' as http;



class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController textEditingController = TextEditingController();
  final List chat = [];
  final ScrollController scrollController = ScrollController();
  final _openAI = OpenAI.instance.build(
      token: API_KEY,
      baseOption:  HttpSetup(
        receiveTimeout:  const Duration(
          seconds: 5,
        ),
      ),
    enableLog: true,
  );

  @override
  void dispose() {
    textEditingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<String> getChatResponse(String m) async{
    return m;
  }

  Future<void> handleSubmitted(String text) async {
    Logger().d(text);

    if (text.trim().isNotEmpty) {
      ChatMessage newChat = ChatMessage(text,true,true);
      setState(() {
        chat.add(newChat);
        scrollToBottom();
      });
    }
    textEditingController.clear();

    // GPT API 호출
    try {
      String gpt3Response = await getChatResponse(text);
      ChatMessage gptMessage = ChatMessage(gpt3Response, false, false);
      setState(() {
        chat.add(gptMessage);
        scrollToBottom();
      });
    } catch (e) {
      Logger().e("Error fetching GPT-3 response: $e");
    }
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
