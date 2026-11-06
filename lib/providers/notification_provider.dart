import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../utils/error_messages.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  NotificationProvider(this._service);

  StreamSubscription<List<AppNotification>>? _subscription;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _loadError;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  void startListening(String uid) {
    if (_subscription != null) return;
    _subscription = _service.watchForUser(uid).listen(
      (list) {
        _notifications = list;
        _isLoading = false;
        _loadError = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Could not load notifications: $e');
        _isLoading = false;
        _loadError = ErrorMessages.from(e);
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    _isLoading = true;
    _loadError = null;
  }

  Future<void> markAsRead(AppNotification notification) async {
    if (notification.read) return;
    try {
      await _service.markAsRead(notification.id);
    } catch (e) {
      debugPrint('Could not mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIds = _notifications.where((n) => !n.read).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;
    try {
      await _service.markAllAsRead(unreadIds);
    } catch (e) {
      debugPrint('Could not mark notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}