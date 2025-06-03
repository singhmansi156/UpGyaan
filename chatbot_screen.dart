import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator/loading_indicator.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  List<Map<String, dynamic>> messages = [];

  String? userId;
  

  @override
  void initState() {
    super.initState();
    loadUserId();
    
  }

  Future<void> loadUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final storedUserId = prefs.get('user_id');

  setState(() {
    userId = storedUserId.toString(); // Convert int or string to String
  });

  if (userId != null) {
    getChatHistory();
  }
}


  Future<void> getChatHistory() async {
  final url = Uri.parse('http://127.0.0.1:5000/get_chat_history/$userId');

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    setState(() {
     messages = (data['messages'] as List)
    .map((msg) => {
          'sender': msg['sender'].toString(),
          'text': msg['text'].toString(),
          'time': msg['time'] ?? '', // safely get time
        })
    .toList();
    });
  } else {
    setState(() {
      messages.add({'sender': 'bot', 'text': 'Failed to load chat history'});
    });
  }
}


Future<void> sendMessage(String question) async {
  setState(() {
    _isLoading = true;
    messages.add({
      'sender': 'user',
      'text': question,
      'time': TimeOfDay.now().format(context), // show current time
    });
  });

  final url = Uri.parse('http://127.0.0.1:5000/chat');
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"user_id": userId, "question": question}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final reply = data["response"];
    final time = data["time"] ?? TimeOfDay.now().format(context);

    setState(() {
      messages.add({
        'sender': 'bot',
        'text': reply,
        'time': time,
      });
      _isLoading = false;
    });
  } else {
    setState(() {
      messages.add({'sender': 'bot', 'text': 'Something went wrong!', 'time': ''});
      _isLoading = false;
    });
  }

  _controller.clear();

  Future.delayed(const Duration(milliseconds: 300), () {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  });
}

Widget buildMessageBubble(String text, bool isUser, String time) {
  return Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.only(top: 12,left: 16, right: 16, bottom: 5),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF8BD7D1) : Colors.grey.shade200,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isUser ? 12 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            textAlign: TextAlign.justify,
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              time, // Just show the plain time string
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ],
      ),
    ),
  );
}



  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: const Color(0xFFEFF9F8),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF136961), Color(0xFF28BABA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      centerTitle: true,
      elevation: 5,
      title: const Text(
        'UpGyaan Chatbot',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isUser = message['sender'] == 'user';
              return buildMessageBubble(message['text']!, isUser, message['time']!);
            },
          ),
        ),
        if (_isLoading)
          const  SizedBox(
                    height: 40,
                    width: 40,
                    child: LoadingIndicator(
                      indicatorType: Indicator.lineSpinFadeLoader,
                      colors: [
                        Color(0xFF6DA76A),
                        Color(0xFFD9B37A),
                        Color(0xFFD4A662),
                      ],
                      strokeWidth: 2,
                    ),
                  ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1FDFD),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color.fromARGB(255, 25, 145, 145),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20,),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty && !_isLoading) {
                      sendMessage(_controller.text.trim());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}
