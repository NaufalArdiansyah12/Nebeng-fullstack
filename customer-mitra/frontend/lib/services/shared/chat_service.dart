import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // === CONVERSATIONS ===

  /// Get conversations list untuk user (real-time stream)
  /// Mendukung format lama (customerId/mitraId) dan format baru (participants)
  Stream<List<Map<String, dynamic>>> getConversations(
      int userId, String userRole) {
    return _firestore.collection('conversations').snapshots().map((snapshot) {
      // Use document id as key to avoid deduplicating different bookings
      // Each conversation is unique per booking, even if they share the same rideId
      final List<Map<String, dynamic>> conversations = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Format lama: customer-mitra conversation
        if (data.containsKey('customerId') || data.containsKey('mitraId')) {
          String userField = userRole == 'customer' ? 'customerId' : 'mitraId';
          if (data[userField] == userId) {
            conversations.add({
              'id': doc.id,
              ...data,
              '_type': 'old_format',
            });
          }
        }

        // Format baru: participants-based conversation
        else if (data.containsKey('participants')) {
          final participants = data['participants'] as Map<String, dynamic>?;
          if (participants != null &&
              participants.containsKey(userId.toString())) {
            final conversationType = data['conversation_type'] as String?;
            if (userRole == 'customer' &&
                conversationType == 'mitra_posmitra') {
              continue;
            }
            // Ambil data participant lainnya
            String otherUserName = 'User';
            String? otherUserPhoto;
            String? otherUserRole;
            int? otherUserId;

            for (var entry in participants.entries) {
              if (entry.key != userId.toString()) {
                final participantData = entry.value as Map<String, dynamic>;
                otherUserName = participantData['name'] as String? ?? 'User';
                otherUserPhoto = participantData['photo'] as String?;
                otherUserRole = participantData['role'] as String?;
                otherUserId = participantData['user_id'] as int?;
                break;
              }
            }

            if (userRole == 'customer' && otherUserRole == 'posmitra') {
              continue;
            }

            final context = data['context'] as String? ?? '';
            final tebenganType = data['tebengan_type'] as String? ?? '';
            final rideKey = (data['rideId'] ?? data['ride_id'])?.toString();

            conversations.add({
              'id': doc.id,
              'customerName': otherUserName,
              'customerPhoto': otherUserPhoto,
              'lastMessage': data['lastMessage'] ?? data['last_message'] ?? '',
              'lastMessageAt': data['lastMessageAt'] ?? data['last_message_at'],
              'unreadMitra': 0,
              'bookingType': tebenganType,
              'context': context,
              'otherUserRole': otherUserRole,
              '_type': 'new_format',
              'rideId': rideKey,
            });
          } else {}
        }
      }

      // Sort by last message time
      conversations.sort((a, b) {
        final aTime = a['lastMessageAt'];
        final bTime = b['lastMessageAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        // Safely handle Timestamp comparison
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        } else if (aTime is String && bTime is String) {
          return bTime.compareTo(aTime);
        } else {
          return 0;
        }
      });

      return conversations;
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
    String? customerPhone,
    required int mitraId,
    required String mitraName,
    String? mitraPhoto,
    String? mitraPhone,
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
      'customerPhone': customerPhone,
      'mitraId': mitraId,
      'mitraName': mitraName,
      'mitraPhoto': mitraPhoto,
      'mitraPhone': mitraPhone,
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

    // Determine recipient ID for notification
    int? recipientId;
    if (convData != null) {
      if (senderId == convData['customerId']) {
        updateData['unreadMitra'] = FieldValue.increment(1);
        recipientId = convData['mitraId'] as int?;
      } else {
        updateData['unreadCustomer'] = FieldValue.increment(1);
        recipientId = convData['customerId'] as int?;
      }
    }

    batch.update(convRef, updateData);

    await batch.commit();

    // Send notification to recipient
    if (recipientId != null) {
      await _sendMessageNotification(
        senderId: senderId,
        recipientId: recipientId,
        senderName: senderName,
        messageText: text,
        conversationId: conversationId,
      );
    }
  }

  /// Send notification to backend for new message
  Future<void> _sendMessageNotification({
    required int senderId,
    required int recipientId,
    required String senderName,
    required String messageText,
    required String conversationId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/chat/notify');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'sender_id': senderId,
          'recipient_id': recipientId,
          'sender_name': senderName,
          'message_text': messageText,
          'conversation_id': conversationId,
        }),
      );
    } catch (e) {
      // Don't throw error - notification failure shouldn't block message sending
    }
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

  /// Update conversation phone numbers (untuk fallback update conversation lama)
  Future<void> updateConversationPhone(
    String conversationId, {
    String? customerPhone,
    String? mitraPhone,
  }) async {
    final Map<String, dynamic> updates = {};
    if (customerPhone != null) updates['customerPhone'] = customerPhone;
    if (mitraPhone != null) updates['mitraPhone'] = mitraPhone;

    if (updates.isNotEmpty) {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update(updates);
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

  // === POS MITRA METHODS ===

  /// Get conversations untuk pos mitra (real-time stream)
  /// Returns conversations where pos mitra is a participant
  /// Filtering dilakukan di client side untuk menghindari composite index requirement
  Stream<QuerySnapshot> getConversationsForPosMitra(int userId) {
    // Query semua conversations, filter di client side
    return _firestore
        .collection('conversations')
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Get messages untuk pos mitra conversation (real-time stream)
  /// Returns QuerySnapshot for StreamBuilder compatibility
  Stream<QuerySnapshot> getMessagesForPosMitra(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Send message untuk pos mitra
  Future<void> sendMessageForPosMitra({
    required String conversationId,
    required int senderId,
    required String text,
  }) async {
    try {
      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      await messageRef.set({
        'sender_id': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      // Update last message in conversation
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mark messages as read untuk pos mitra
  Future<void> markMessagesAsReadForPosMitra(
      String conversationId, int userId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('sender_id', isNotEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      if (messagesSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {}
  }

  /// Mark booking as completed - triggers auto-delete after 24 hours
  Future<void> markBookingCompleted(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'booking_completed_at': FieldValue.serverTimestamp(),
        'booking_status': 'completed',
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mark booking as completed by rideId (for cases where conversationId not known)
  Future<void> markBookingCompletedByRide({
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

      if (querySnapshot.docs.isNotEmpty) {
        final conversationId = querySnapshot.docs.first.id;
        await markBookingCompleted(conversationId);
      }
    } catch (e) {}
  }
}
