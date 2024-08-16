import 'dart:async';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/page/page_navigation.dart';

import '../../data/data_store.dart';
import '../../package/const_key.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  bool _isAtTop = false; // 스크롤이 최상단에 있는지 여부를 추적하는 플래그
  final ScrollController _scrollController = ScrollController();
  int limit = 15;
  Timer? _scrollTimer;

  List<ChatMessage> _messages = <ChatMessage>[];

  final ChatUser _currentUser = ChatUser(
    id: KeyValue().AGENT,
    firstName: 'Me',
    lastName: '',
    profileImage:
    "https://cdn-icons-png.flaticon.com/128/149/149071.png",
  );
  final ChatUser _gptChatUser = ChatUser(
    id: KeyValue().GPT,
    firstName: 'HealthCare',
    lastName: 'Agent',
    profileImage:
    "https://cdn-icons-png.flaticon.com/128/6667/6667585.png",
  );
  final _openAI = OpenAI.instance.build(
    token: API_KEY,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      connectTimeout: const Duration(seconds: 30),
    ),
    enableLog: true,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    loadChatRecords(limit);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> loadChatRecords(int limit) async {
    final dataController = DataStore();
    final stream = dataController.getUserRecordsStream(
        KeyValue().ID, KeyValue().Chat);

    stream.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data =
        event.snapshot.value as Map<dynamic, dynamic>;
        List<ChatMessage> messages = [];
        data.forEach((key, value) {
          final message = ChatMessage(
            text: value[KeyValue().CONTENT],
            user: value[KeyValue().CHAT_ID] == _currentUser.id
                ? _currentUser
                : _gptChatUser,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
                value[KeyValue().MILLITIMESTAMP]),
          );
          messages.add(message);
        });

        // 최신 메시지부터 정렬 후, 상위 limit 개수만 가져오기
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        setState(() {
          _messages = messages.take(limit).toList();
        });
      }
    });
  }

  void _scrollListener() {
    // 스크롤이 최상단에 도달했을 때만 1초 동안 대기 후 추가 메시지 로드
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isAtTop) {
        _isAtTop = true;
        _startScrollTimer();
      }
    } else {
      if (_isAtTop) {
        _isAtTop = false;
        _scrollTimer?.cancel();
      }
    }
  }

  void _startScrollTimer() {
    _scrollTimer = Timer(const Duration(seconds: 1), () {
      if (_isAtTop) {
        print("1초 동안 최상단에 머물렀습니다. 새로고침을 수행합니다.");
        limit += 16;
        loadChatRecords(limit);
      }
    });
  }

  Future<void> chatPageAccessCount() async {
    var time = DateTime.now().millisecondsSinceEpoch;

    var savetime = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    String formattedTime = formatter.format(savetime);
    await DataStore().saveData(
        KeyValue().ID, "${KeyValue().CHAT_PAGE_ACCESS_COUNT}/$formattedTime", {
      KeyValue().OPEN_STATE: "resume",
      KeyValue().TIMESTAMP: formattedTime,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 다시 활성화되었을 때 원하는 작업을 수행합니다.
    if ((state == AppLifecycleState.resumed)) {
      // 여기에 백그라운드에서 다시 활성화될 때 실행할 작업을 추가합니다.
      // chatPageAccessCount();
      print('앱이 다시 활성화되었습니다.');
    }
  }

  @override
  void dispose() {
    // WidgetsBindingObserver를 해제합니다.
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashChat(
        currentUser: _currentUser,
        onSend: (ChatMessage m) {
          Fluttertoast.showToast(msg: "현재 기능을 사용할 수 없습니다.");
        },
        messages: _messages,
        messageOptions: MessageOptions(
          showCurrentUserAvatar: true,
          showOtherUsersName: true,
          showTime: true,
          maxWidth: MediaQuery.of(context).size.width * 0.68,
          timeFormat: DateFormat('HH:mm'),
        ),
        messageListOptions: MessageListOptions(
          dateSeparatorBuilder: (DateTime date) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  DateFormat('yyyy년 MM월 dd일').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
          scrollController: _scrollController,
        ),
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
    });

    final dataController = DataStore();
    var time = DateTime.now().millisecondsSinceEpoch;
    await dataController.saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
      KeyValue().CHAT_ID: m.user.id,
      KeyValue().CONTENT: m.text,
      KeyValue().TIMESTAMP: time,
    });

    var recentMessages = _messages.take(10).toList().reversed.toList();

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
      temperature: 1,
    );
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      if (element.message != null) {
        var time = DateTime.now().millisecondsSinceEpoch;
        await dataController.saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
          KeyValue().CHAT_ID: KeyValue().GPT,
          KeyValue().CONTENT: element.message!.content,
          KeyValue().TIMESTAMP: time,
        });
        setState(() {});
      }
    }
  }
}
