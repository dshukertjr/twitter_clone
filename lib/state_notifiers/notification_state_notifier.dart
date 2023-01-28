import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/app_notification.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier()
    .._getNotifications()
    .._setupRealtimeListener();
});

abstract class NotificationsState {}

class NotificationLoading extends NotificationsState {}

class EmptyNotification extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  final int newNotificationCount;

  NotificationsLoaded({
    required this.notifications,
    required this.newNotificationCount,
  });
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(NotificationLoading());

  late final RealtimeChannel _realtimeChannel;

  List<AppNotification> _notifications = [];

  Future<void> _getNotifications() async {
    final data = await supabase
        .from('notifications_view')
        .select<List<Map<String, dynamic>>>()
        .order('created_at')
        .limit(20);

    _notifications = data.map(AppNotification.fromJson).toList();
    if (_notifications.isEmpty) {
      state = EmptyNotification();
    } else {
      final newNotificationCount = _notifications
          .where((notification) => !notification.hasBeenRead)
          .length;

      state = NotificationsLoaded(
        notifications: _notifications,
        newNotificationCount: newNotificationCount,
      );
    }
  }

  Future<void> readNotification() async {
    _notifications =
        _notifications.map((notification) => notification.read()).toList();
    state = NotificationsLoaded(
        notifications: _notifications, newNotificationCount: 0);
    await supabase
        .from('notifications')
        .update({'has_been_read': true}).eq('has_been_read', false);
  }

  void _setupRealtimeListener() {
    _realtimeChannel = supabase.channel('notification');
    _realtimeChannel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
        ), (payload, [ref]) {
      _getNotifications();
    }).subscribe();
  }

  @override
  void dispose() {
    supabase.removeChannel(_realtimeChannel);
    super.dispose();
  }
}
