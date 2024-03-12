
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_research/data/category.dart';

import '../../data/data_store.dart';
import '../../package/const_key.dart';


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {

  @override
  void initState() {
    super.initState();
    loadChatRecords();
  }

  List<ChatMessage> _messages = <ChatMessage>[];

  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Me',lastName: '',profileImage: "https://placekitten.com/200/200",);
  final ChatUser _gptChatUser = ChatUser(id: '2', firstName: 'Chat',lastName: 'GPT',profileImage: "https://placekitten.com/200/200",);
  final _openAI = OpenAI.instance.build(
      token: API_KEY,
      baseOption: HttpSetup(
          receiveTimeout: const Duration(
            seconds: 30,
          ),
          sendTimeout: const Duration(
            seconds: 30,
          ),
          connectTimeout: const Duration(
            seconds: 30,
          ),
      ),
    enableLog: true,
  );



  Future<void> loadChatRecords() async {
    final dataController = DataStore();
    final stream = dataController.getUserRecordsStream(Category().ID, Category().Chat);

    stream.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        List<ChatMessage> messages = [];
        data.forEach((key, value) {
          final message = ChatMessage(
            text: value["text"],
            user: value["senderId"] == _currentUser.id ? _currentUser : _gptChatUser,
            createdAt: DateTime.fromMillisecondsSinceEpoch(value["timestamp"]),
          );
          messages.add(message);
        });
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        setState(() {
          _messages = messages.reversed.toList();
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashChat(
        currentUser: _currentUser,
        onSend: (ChatMessage m){
          getChatResponse(m);
        },
        messages: _messages,
        messageOptions: MessageOptions(
          showCurrentUserAvatar: true,
          showOtherUsersName: true,
          showTime: true,
          timeFormat: DateFormat('HH:mm'), // 이 부분이 올바르게 설정되었는지 확인하세요.
        ),

        messageListOptions: MessageListOptions(
          dateSeparatorBuilder: (DateTime date) {
            // 날짜 구분자 커스터마이즈
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  DateFormat('yyyy년 MM월 dd일').format(date), // 날짜 포맷 지정
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m ) async{
    setState((){
      _messages.insert(0, m);
    });

    final dataController = DataStore();
    var time = DateTime.now().millisecondsSinceEpoch;
    await dataController.saveData(Category().ID, '${Category().Chat}/$time', {
      "senderId": m.user.id,
      "text": m.text,
      "timestamp": time,
    });
    // 최근 5개 메시지만 추출
    var recentMessages = _messages.take(10).toList().reversed.toList();

    // Messages 객체 리스트 생성
    List<Messages> messagesHistory = recentMessages.map((m) {
      return Messages(
        role: m.user.id == _currentUser.id ? Role.user : Role.assistant,
        content: m.text,
      );
    }).toList();

    final request = ChatCompleteText(
      model: Gpt4ChatModel(),
      messages: messagesHistory,
      maxToken: 200,
    );
    final response = await _openAI.onChatCompletion(request: request);
    for(var element in response!.choices){
      if (element.message != null){
        time = DateTime.now().millisecondsSinceEpoch;
        await dataController.saveData(Category().ID, '${Category().Chat}/$time', {
          "senderId": "2",
          "text": element.message!.content,
          "timestamp": time,
        });
        setState(() {
        });
      }
    }
  }
}