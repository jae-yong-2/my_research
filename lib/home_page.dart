import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:my_research/chat_message.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  TextEditingController textEditingController = TextEditingController();

  List<ChatMessage> chat = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dr.Chat')),
      body: Column(
        children: [
          Expanded(child: ListView.builder(itemBuilder:(context,index){
            return chat[index];
          }, itemCount: chat.length,)),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: textEditingController,
              onSubmitted: handleSubmitted,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요.',
                fillColor: Colors.grey.shade200, // 연한 회색 배경
                filled: true,
                border: UnderlineInputBorder(
                  borderSide: BorderSide.none,
                ),

                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    // TODO: 메시지 보내기 로직 추가
                    handleSubmitted(textEditingController.text);

                  },
                ),
              ),
            ),
          ),
        ],
      ),


      bottomNavigationBar: BottomAppBar(
        height: 50,
        child:SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.man),
              Icon(Icons.message),
            ],
          ),
        ),
      ),
    );
  }


  void handleSubmitted(String text){
    Logger().d(text);

    ChatMessage newChat = ChatMessage(text);
    if(text.isNotEmpty) {
      setState(() {
        chat.add(newChat);
      });
    }

    textEditingController.clear();
  }
}
