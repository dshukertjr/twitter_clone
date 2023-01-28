import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/message.dart';
import 'package:twitter_clone/models/profile.dart';
import 'package:twitter_clone/state_notifiers/rooms_state_notifier.dart';

final chatsStateNotifierProvider = StateNotifierProvider.autoDispose
    .family<ChatsStateNotifier, ChatsState, String>((ref, roomId) {
  final myUserId = supabase.auth.currentUser!.id;
  final roomsStateNotifier =
      ref.watch(roomsStateNotifierProvider(myUserId).notifier);

  return ChatsStateNotifier(roomId: roomId)..loadMessages(roomsStateNotifier);
});

abstract class ChatsState {}

class ChatsLoading extends ChatsState {}

class ChatsEmpty extends ChatsState {
  final Profile? otherUser;

  ChatsEmpty(this.otherUser);
}

class ChatsLoaded extends ChatsState {
  final List<Message> messages;
  final Profile? otherUser;

  ChatsLoaded({
    required this.messages,
    required this.otherUser,
  });
}

class ChatsError extends ChatsState {
  final String message;

  ChatsError(this.message);
}

class ChatsStateNotifier extends StateNotifier<ChatsState> {
  ChatsStateNotifier({required String roomId})
      : _roomId = roomId,
        super(ChatsLoading());

  final String _roomId;

  List<Message>? _messages;
  Profile? _otherUser;

  late final StreamSubscription<List<Message>> _messagesSubscription;

  Future<void> loadMessages(RoomsStateNotifier roomsStateNotifier) async {
    roomsStateNotifier.readMessages();
    _messagesSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.map(Message.fromMap).toList())
        .listen((messages) {
          _messages = messages;
          if (_messages!.isEmpty) {
            state = ChatsEmpty(_otherUser);
          } else {
            state = ChatsLoaded(
              messages: _messages!,
              otherUser: _otherUser,
            );
          }
        });

    final myUserId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('room_participants')
        .select<Map<String, dynamic>>('other_user:profiles(*)')
        .eq('room_id', _roomId)
        .neq('user_id', myUserId)
        .single();
    _otherUser = Profile.fromJson(data['other_user']);
    if (_messages != null) {
      if (_messages!.isEmpty) {
        state = ChatsEmpty(_otherUser);
      } else {
        state = ChatsLoaded(
          messages: _messages!,
          otherUser: _otherUser,
        );
      }
    }
  }

  Future<void> sendChat(String text) async {
    final myUserId = supabase.auth.currentUser!.id;

    _messages = _messages ?? [];
    final messages = Message(
      id: 'new',
      content: text,
      roomId: _roomId,
      createdAt: DateTime.now(),
      userId: myUserId,
      hasBeenRead: false,
    );
    _messages!.insert(0, messages);
    state = ChatsLoaded(messages: _messages!, otherUser: _otherUser);
    await supabase.from('messages').insert({
      'room_id': _roomId,
      'content': text,
    });
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    super.dispose();
  }
}
