import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Utility to update existing conversations with profile photos from database
class UpdateConversationPhotos {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fix localhost URLs in all conversations
  static Future<void> fixLocalhostUrls() async {
    try {
      print('🔄 Fixing localhost URLs in conversations...');

      final conversationsSnapshot =
          await _firestore.collection('conversations').get();

      int fixed = 0;

      for (var doc in conversationsSnapshot.docs) {
        final data = doc.data();
        final conversationId = doc.id;

        Map<String, dynamic> updateData = {};

        // Fix customerPhoto if it has localhost
        final customerPhoto = data['customerPhoto'] as String?;
        if (customerPhoto != null && customerPhoto.contains('localhost')) {
          final fixedUrl = customerPhoto.replaceAll(
              'http://localhost', 'http://10.200.8.21');
          updateData['customerPhoto'] = fixedUrl;
          print('✅ Fixed customerPhoto for $conversationId');
        }

        // Fix mitraPhoto if it has localhost
        final mitraPhoto = data['mitraPhoto'] as String?;
        if (mitraPhoto != null && mitraPhoto.contains('localhost')) {
          final fixedUrl =
              mitraPhoto.replaceAll('http://localhost', 'http://10.200.8.21');
          updateData['mitraPhoto'] = fixedUrl;
          print('✅ Fixed mitraPhoto for $conversationId');
        }

        // Update conversation if we have fixes
        if (updateData.isNotEmpty) {
          await _firestore
              .collection('conversations')
              .doc(conversationId)
              .update(updateData);
          fixed++;
        }
      }

      print('✅ URL fix complete! Fixed: $fixed conversations');
    } catch (e) {
      print('❌ Error fixing URLs: $e');
    }
  }

  /// Update all conversations with missing photos
  static Future<void> updateAllConversations() async {
    try {
      print('🔄 Starting conversation photo update...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        print('❌ No API token found');
        return;
      }

      final conversationsSnapshot =
          await _firestore.collection('conversations').get();

      int updated = 0;
      int skipped = 0;

      for (var doc in conversationsSnapshot.docs) {
        final data = doc.data();
        final conversationId = doc.id;

        // Check if photos are already present
        final hasCustomerPhoto = data['customerPhoto'] != null &&
            (data['customerPhoto'] as String).isNotEmpty;
        final hasMitraPhoto = data['mitraPhoto'] != null &&
            (data['mitraPhoto'] as String).isNotEmpty;

        if (hasCustomerPhoto && hasMitraPhoto) {
          skipped++;
          continue;
        }

        // Get user IDs
        final customerId = data['customerId'] as int?;
        final mitraId = data['mitraId'] as int?;

        Map<String, dynamic> updateData = {};

        // Fetch customer photo if missing
        if (!hasCustomerPhoto && customerId != null) {
          try {
            final customerData =
                await ApiService.getUserById(customerId, token);
            final customerPhoto = customerData['photo_url'] as String?;

            if (customerPhoto != null && customerPhoto.isNotEmpty) {
              updateData['customerPhoto'] = _getFullPhotoUrl(customerPhoto);
              print(
                  '✅ Updated customer photo for conversation $conversationId');
            }
          } catch (e) {
            print('⚠️ Failed to fetch customer $customerId photo: $e');
          }
        }

        // Fetch mitra photo if missing
        if (!hasMitraPhoto && mitraId != null) {
          try {
            final mitraData = await ApiService.getUserById(mitraId, token);
            final mitraPhoto = mitraData['photo_url'] as String?;

            if (mitraPhoto != null && mitraPhoto.isNotEmpty) {
              updateData['mitraPhoto'] = _getFullPhotoUrl(mitraPhoto);
              print('✅ Updated mitra photo for conversation $conversationId');
            }
          } catch (e) {
            print('⚠️ Failed to fetch mitra $mitraId photo: $e');
          }
        }

        // Update conversation if we have new data
        if (updateData.isNotEmpty) {
          await _firestore
              .collection('conversations')
              .doc(conversationId)
              .update(updateData);
          updated++;
        }
      }

      print('✅ Photo update complete! Updated: $updated, Skipped: $skipped');
    } catch (e) {
      print('❌ Error updating conversation photos: $e');
    }
  }

  /// Ensure photo URL is absolute
  static String _getFullPhotoUrl(String photo) {
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }

    final baseUrl = ApiService.baseUrl;
    final cleanPhoto = photo.startsWith('/') ? photo : '/$photo';
    return '$baseUrl$cleanPhoto';
  }
}
