import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // === CONVERSATIONS ===

  /// Get conversations list untuk user (real-time stream)
  Stream<List<Map<String, dynamic>>> getConversations(
      int userId, String userRole) {
    String userField = userRole == 'customer' ? 'customerId' : 'mitraId';

    print('🔥 Firestore query - Field: $userField, UserId: $userId');
    print('🔥 Querying ALL conversations first (debug)...');

    // Test: Get ALL conversations first (no where filter)
    return _firestore.collection('conversations').snapshots().map((snapshot) {
      print('📦 Total documents in Firestore: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        print('📄 Doc ID: ${doc.id}');
        print('📄 Data: ${doc.data()}');
      }

      final docs = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Filter manually for now
      final filtered = docs.where((doc) => doc[userField] == userId).toList();
      print(
          '✅ Filtered conversations for $userField=$userId: ${filtered.length}');

      // Manual sort by lastMessageAt
      filtered.sort((a, b) {
        final aTime = a['lastMessageAt'];
        final bTime = b['lastMessageAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return (bTime as Timestamp).compareTo(aTime as Timestamp);
      });

      return filtered;
    });
  }

  /// Get single conversation
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    final doc =
        await _firestore.collection('conversations').doc(conversationId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Get conversation by rideId, customerId, and mitraId
  Future<Map<String, dynamic>?> getConversationByRideAndUsers({
    required int rideId,
    required int customerId,
    required int mitraId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversations')
          .where('rideId', isEqualTo: rideId)
          .where('customerId', isEqualTo: customerId)
          .where('mitraId', isEqualTo: mitraId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return {'id': doc.id, ...doc.data()};
    } catch (e) {
      print('Error getting conversation by ride and users: $e');
      return null;
    }
  }

  /// Create conversation (dipanggil saat booking)
  Future<String> createConversation({
    required int rideId,
    required String bookingType,
    required int customerId,
    required String customerName,
    String? customerPhoto,
    required int mitraId,
    required String mitraName,
    String? mitraPhoto,
  }) async {
    // Check if conversation already exists
    final existing = await _firestore
        .collection('conversations')
        .where('rideId', isEqualTo: rideId)
        .where('customerId', isEqualTo: customerId)
        .where('mitraId', isEqualTo: mitraId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Create new conversation
    final doc = await _firestore.collection('conversations').add({
      'rideId': rideId,
      'bookingType': bookingType,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhoto': customerPhoto,
      'mitraId': mitraId,
      'mitraName': mitraName,
      'mitraPhoto': mitraPhoto,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCustomer': 0,
      'unreadMitra': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // === MESSAGES ===

  /// Get messages (real-time stream)
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .limit(100)
        .snapshots()
        .map((snapshot) {
      // Sort manually di client side
      final docs = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Sort by createdAt descending (newest first)
      docs.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return docs;
    });
  }

  /// Send message
  Future<void> sendMessage({
    required String conversationId,
    required int senderId,
    required String senderName,
    required String text,
    String type = 'text',
    String? imageUrl,
    Map<String, double>? location,
  }) async {
    final batch = _firestore.batch();

    // Add message to subcollection
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      'imageUrl': imageUrl,
      'location': location,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update conversation lastMessage
    final convRef = _firestore.collection('conversations').doc(conversationId);

    // Get current conversation to determine who to increment unread for
    final convDoc = await convRef.get();
    final convData = convDoc.data();

    Map<String, dynamic> updateData = {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };

    // Increment unread count untuk penerima
    if (convData != null) {
      if (senderId == convData['customerId']) {
        updateData['unreadMitra'] = FieldValue.increment(1);
      } else {
        updateData['unreadCustomer'] = FieldValue.increment(1);
      }
    }

    batch.update(convRef, updateData);

    await batch.commit();
  }

  /// Mark messages as read
  Future<void> markAsRead(
      String conversationId, int userId, String userRole) async {
    final unreadField =
        userRole == 'customer' ? 'unreadCustomer' : 'unreadMitra';

    await _firestore.collection('conversations').doc(conversationId).update({
      unreadField: 0,
    });

    // Optional: mark individual messages as read
    final messages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    if (messages.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// Get unread count untuk badge
  Stream<int> getUnreadCount(int userId, String userRole) {
    String unreadField =
        userRole == 'customer' ? 'unreadCustomer' : 'unreadMitra';
    String userField = userRole == 'customer' ? 'customerId' : 'mitraId';

    return _firestore
        .collection('conversations')
        .where(userField, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()[unreadField] ?? 0) as int;
      }
      return total;
    });
  }
}
