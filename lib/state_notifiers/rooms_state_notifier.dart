import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/message.dart';
import 'package:twitter_clone/models/profile.dart';
import 'package:twitter_clone/models/room.dart';

final roomsStateNotifierProvider =
    StateNotifierProvider.family<RoomsStateNotifier, RoomsState, String>(
        (ref, userId) {
  return RoomsStateNotifier(myUserId: userId)..loadRooms();
});

abstract class RoomsState {}

class RoomsLoading extends RoomsState {}

class RoomsEmpty extends RoomsState {}

class RoomsLoaded extends RoomsState {
  final List<Room> rooms;
  final int unreadCount;

  RoomsLoaded(
    this.rooms, {
    required this.unreadCount,
  });
}

class RoomsError extends RoomsState {
  final String message;

  RoomsError(this.message);
}

class RoomsStateNotifier extends StateNotifier<RoomsState> {
  RoomsStateNotifier({
    required String myUserId,
  })  : _myUserId = myUserId,
        super(RoomsLoading());

  final String _myUserId;

  final Map<String, StreamSubscription<Message?>> _messageSubscriptions = {};

  /// In-memory cache for all the profiles that the user is chatting with
  final Map<String, Profile> _profilesCache = {};

  /// List of rooms
  List<Room> _rooms = [];
  StreamSubscription<List<Map<String, dynamic>>>? _rawRoomsSubscription;

  Future<void> loadRooms() async {
    /// Get realtime updates on rooms that the user is in
    _rawRoomsSubscription = supabase
        .from('room_participants')
        .stream(primaryKey: ['id']).listen((participantMaps) async {
      if (participantMaps.isEmpty) {
        state = RoomsEmpty();
        return;
      }

      _rooms = participantMaps
          .map(Room.fromRoomParticipants)
          .where((room) => room.otherUserId != _myUserId)
          .toList();
      for (final room in _rooms) {
        _getNewestMessage(roomId: room.id);
        await _getProfile(room.otherUserId);
      }
      final unreadCount =
          _rooms.where((room) => room.lastMessage?.isUnread ?? false).length;
      state = RoomsLoaded(_rooms, unreadCount: unreadCount);
    }, onError: (error) {
      state = RoomsError('Error loading rooms');
    });
  }

  Future<void> _getProfile(String userId) async {
    if (_profilesCache[userId] != null) {
      return;
    }
    final data = await supabase
        .from('profiles')
        .select<Map<String, dynamic>>()
        .eq('id', userId)
        .single();
    final profile = Profile.fromJson(data);
    _profilesCache[userId] = profile;
    final targetIndex = _rooms.indexWhere((room) => room.otherUserId == userId);
    _rooms[targetIndex] = _rooms[targetIndex].copyWith(otherUser: profile);
  }

  // Setup listeners to listen to the most recent message in each room
  void _getNewestMessage({
    required String roomId,
  }) {
    _messageSubscriptions[roomId] = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .limit(1)
        .map<Message?>(
          (data) => data.isEmpty ? null : Message.fromMap(data.first),
        )
        .listen((message) {
          final index = _rooms.indexWhere((room) => room.id == roomId);
          _rooms[index] = _rooms[index].copyWith(lastMessage: message);
          _rooms.sort((a, b) {
            /// Sort according to the last message
            /// Use the room createdAt when last message is not available
            final aTimeStamp =
                a.lastMessage != null ? a.lastMessage!.createdAt : a.createdAt;
            final bTimeStamp =
                b.lastMessage != null ? b.lastMessage!.createdAt : b.createdAt;
            return bTimeStamp.compareTo(aTimeStamp);
          });
          final unreadCount = _rooms
              .where((room) => room.lastMessage?.isUnread ?? false)
              .length;
          state = RoomsLoaded(_rooms, unreadCount: unreadCount);
        });
  }

  /// Creates or returns an existing roomID of both participants
  ///
  /// Returns the room ID of the created room. It will return the room ID if a room already existed
  Future<String> createRoom(String otherUserId) async {
    final data = await supabase
        .rpc('create_new_room', params: {'other_user_id': otherUserId});
    final unreadCount =
        _rooms.where((room) => room.lastMessage?.isUnread ?? false).length;
    state = RoomsLoaded(_rooms, unreadCount: unreadCount);
    return data as String;
  }

  Future<void> readMessages() async {
    await supabase
        .from('messages')
        .update({'has_been_read': true}).eq('has_been_read', false);
  }

  @override
  void dispose() {
    _rawRoomsSubscription?.cancel();
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}
