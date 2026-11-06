import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  // Real-time list of one user's notifications, newest first
  Stream<List<AppNotification>> watchForUser(String uid) {
    return _notifications
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(AppNotification.fromDoc).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markAsRead(String id) {
    return _notifications.doc(id).update({'read': true});
  }

  Future<void> markAllAsRead(List<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_notifications.doc(id), {'read': true});
    }
    await batch.commit();
  }
}