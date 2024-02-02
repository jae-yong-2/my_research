
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_research/Const.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Me',lastName: '',profileImage: "https://placekitten.com/200/200",);
  final ChatUser _gptChatUser = ChatUser(id: '2', firstName: 'Chat',lastName: 'GPT',profileImage: "https://placekitten.com/200/200",);

  final _openAI = OpenAI.instance.build(
      token: API_KEY,
      baseOption: HttpSetup(
          receiveTimeout: const Duration(
            seconds: 5,
          ),
      ),
    enableLog: true,
  );

  final List<ChatMessage> _messages = <ChatMessage>[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 166, 126, 1),
        title: const Text("GPT Chat",
          style: TextStyle(color: Colors.white,
          ),
        ),
      ),
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
    List<Messages> _messagesHistory = _messages.reversed.map((m){
      if(m.user == _currentUser){
        return Messages(role: Role.user, content: m.text);
      } else {
        return Messages(role: Role.assistant, content: m.text);
      }
    }).toList();
    final request = ChatCompleteText(
      model: Gpt4ChatModel(),
      messages: _messagesHistory,
      maxToken: 200,
    );
    final response = await _openAI.onChatCompletion(request: request);
    for(var element in response!.choices){
      if (element.message != null){
        setState(() {
          _messages.insert(
              0,
            ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: element.message!.content,
            ),
          );
        });
      }
    }
  }
}
