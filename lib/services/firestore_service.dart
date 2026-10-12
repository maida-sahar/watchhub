import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

/// Owns ALL reads/writes to the `users` collection. No other layer talks
/// to Firestore directly — this keeps the query surface in one place and
/// makes it easy to add caching, offline persistence tweaks, etc. later.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<bool> userDocumentExists(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.exists;
  }

  Future<void> createUserDocument(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUserDocument(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return UserModel.fromMap(snapshot.data()!, uid);
  }

  /// Partial update. Always stamps `updatedAt`, and deliberately never
  /// accepts a `role` key here — role changes should go through a
  /// dedicated admin-only path, matching the Firestore security rules.
  Future<void> updateUserDocument(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final safeData = Map<String, dynamic>.from(data)
      ..remove('role')
      ..remove('uid')
      ..['updatedAt'] = Timestamp.fromDate(DateTime.now());

    await _usersCollection.doc(uid).update(safeData);
  }

  Stream<UserModel?> watchUserDocument(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromMap(snapshot.data()!, uid);
    });
  }
}