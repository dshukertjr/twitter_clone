import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/message.dart';
import 'package:twitter_clone/models/profile.dart';
import 'package:twitter_clone/state_notifiers/chats_state_notifier.dart';

class ChatPage extends ConsumerWidget {
  static Route<void> route(String roomId) {
    return MaterialPageRoute(builder: ((context) {
      return ChatPage(roomId: roomId);
    }));
  }

  const ChatPage({super.key, required String roomId}) : _roomId = roomId;

  final String _roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(chatsStateNotifierProvider(_roomId));
    final chatsStateNotifier =
        ref.watch(chatsStateNotifierProvider(_roomId).notifier);
    if (chatsState is ChatsLoading) {}
    return Scaffold(
      appBar: _appBar(chatsState),
      body: _body(chatsState, chatsStateNotifier),
    );
  }

  AppBar _appBar(ChatsState state) {
    if (state is ChatsEmpty) {
      final otherUser = state.otherUser;
      if (otherUser != null) {
        return _userLoadedAppbar(otherUser);
      }
    } else if (state is ChatsLoaded) {
      final otherUser = state.otherUser;
      if (otherUser != null) {
        return _userLoadedAppbar(otherUser);
      }
    }
    return AppBar();
  }

  Widget _body(ChatsState state, ChatsStateNotifier chatsStateNotifier) {
    if (state is ChatsLoading) {
      return preloader;
    } else if (state is ChatsEmpty) {
      return Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('Start talking to someone!'),
            ),
          ),
          _MessageBar(chatsStateNotifier: chatsStateNotifier),
        ],
      );
    } else if (state is ChatsError) {
      return Center(child: Text(state.message));
    } else if (state is ChatsLoaded) {
      final messages = state.messages;
      final otherUser = state.otherUser;
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _ChatBubble(
                  message: message,
                  otherUser: otherUser,
                );
              },
            ),
          ),
          _MessageBar(chatsStateNotifier: chatsStateNotifier),
        ],
      );
    }
    throw UnimplementedError('Unknown ChatsState: ${state.runtimeType}');
  }

  AppBar _userLoadedAppbar(Profile otherUser) {
    return AppBar(
      title: Row(
        children: [
          ProfileImage(user: otherUser),
          spacer,
          Text(otherUser.name),
        ],
      ),
    );
  }
}

/// Set of widget that contains TextField and Button to submit message
class _MessageBar extends StatefulWidget {
  const _MessageBar({
    Key? key,
    required ChatsStateNotifier chatsStateNotifier,
  })  : _chatsStateNotifier = chatsStateNotifier,
        super(key: key);

  final ChatsStateNotifier _chatsStateNotifier;

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 8,
            left: 8,
            right: 8,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  autofocus: true,
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _submitMessage(),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final text = _textController.text;
    if (text.isEmpty) {
      return;
    }
    widget._chatsStateNotifier.sendChat(text);
    _textController.clear();
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.otherUser,
  }) : super(key: key);

  final Message message;
  final Profile? otherUser;

  @override
  Widget build(BuildContext context) {
    List<Widget> chatContents = [
      if (!message.isMine) ProfileImage(user: otherUser!),
      const SizedBox(width: 12),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: message.isMine
                ? Colors.grey[300]
                : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: message.isMine
                  ? Colors.black
                  : Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(width: 60),
    ];
    if (message.isMine) {
      chatContents = chatContents.reversed.toList();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment:
            message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}
