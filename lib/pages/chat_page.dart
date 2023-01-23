import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  static Route<void> route(String roomId) {
    return MaterialPageRoute(builder: ((context) {
      return ChatPage(roomId: roomId);
    }));
  }

  const ChatPage({super.key, required String roomId}) : _roomId = roomId;

  final String _roomId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
