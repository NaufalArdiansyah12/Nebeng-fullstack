import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/chat_service.dart';
import '../../../services/api_service.dart';
import '../../../utils/phone_helper.dart';

class MitraChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String bookingType;

  const MitraChatDetailPage({
    Key? key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.bookingType = 'motor',
  }) : super(key: key);

  @override
  State<MitraChatDetailPage> createState() => _MitraChatDetailPageState();
}

class _MitraChatDetailPageState extends State<MitraChatDetailPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  int? _userId;
  String? _userName;
  String _userRole = 'mitra';
  String? _customerPhone; // Nomor telepon customer

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadConversationData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
      _userName =
          prefs.getString('user_name') ?? prefs.getString('name') ?? 'Mitra';
      _userRole = prefs.getString('user_role') ?? 'mitra';
    });

    print(
        '🔍 MitraChatDetailPage - User ID: $_userId, Name: $_userName, Role: $_userRole');

    // Mark as read when opening chat
    if (_userId != null) {
      _chatService.markAsRead(widget.conversationId, _userId!, _userRole);
    }
  }

  Future<void> _loadConversationData() async {
    try {
      print('🔍 Loading conversation data for: ${widget.conversationId}');
      final conv = await _chatService.getConversation(widget.conversationId);

      if (conv == null) {
        print('❌ Conversation not found');
        return;
      }

      print('📦 Conversation data: ${conv.keys}');

      if (mounted) {
        // Mitra chat, maka ambil customerPhone
        String? phone = conv['customerPhone'] as String?;
        print('📞 Phone from conversation: $phone');

        // Fallback: Jika phone tidak ada di conversation (conversation lama),
        // ambil dari API berdasarkan customerId
        if (phone == null || phone.isEmpty) {
          final customerId = conv['customerId'] as int?;
          print('👤 CustomerId from conversation: $customerId');

          if (customerId != null) {
            try {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('api_token');
              print('🔑 Token exists: ${token != null}');

              if (token != null) {
                print(
                    '📞 Fetching customer phone from API for customerId: $customerId');
                final userData =
                    await ApiService.getUserById(customerId, token);
                print('📦 User data keys: ${userData.keys}');

                phone = userData['phone'] as String? ??
                    userData['phone_number'] as String?;
                print('✅ Phone from API: $phone');

                // Update Firestore conversation with phone number for future use
                if (phone != null && phone.isNotEmpty) {
                  try {
                    await _chatService.updateConversationPhone(
                      widget.conversationId,
                      customerPhone: phone,
                    );
                    print('✅ Updated conversation with phone number');
                  } catch (e) {
                    print('⚠️ Failed to update conversation: $e');
                  }
                }
              } else {
                print('❌ No token available');
              }
            } catch (e) {
              print('⚠️ Error fetching phone from API: $e');
              print('⚠️ Stack trace: ${StackTrace.current}');
            }
          } else {
            print('❌ No customerId in conversation');
          }
        }

        setState(() {
          _customerPhone = phone;
        });
        print('📱 Final phone loaded: $_customerPhone');
      }
    } catch (e) {
      print('❌ Error loading conversation data: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _userId == null) return;

    final text = _controller.text.trim();
    _controller.clear();

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: _userId!,
        senderName: _userName ?? 'Mitra',
        text: text,
      );
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF0F4AA3).withOpacity(0.1),
              backgroundImage: widget.otherUserPhoto != null &&
                      widget.otherUserPhoto!.isNotEmpty
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null ||
                      widget.otherUserPhoto!.isEmpty
                  ? Icon(Icons.person, size: 18, color: Color(0xFF0F4AA3))
                  : null,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getBookingTypeLabel(widget.bookingType),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (_customerPhone != null && _customerPhone!.isNotEmpty) {
                PhoneHelper.showCallDialog(
                  context: context,
                  phoneNumber: _customerPhone!,
                  userName: widget.otherUserName,
                  userPhoto: widget.otherUserPhoto,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nomor telepon tidak tersedia'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: Icon(Icons.call, color: Colors.black87),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('❌ Error loading messages: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Mulai percakapan',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Kirim pesan pertama Anda',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg['senderId'] == _userId;

                    return _buildMessageBubble(
                      text: msg['text'] ?? '',
                      isMe: isMe,
                      timestamp: msg['createdAt'],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    dynamic timestamp,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Color(0xFF0F4AA3) : Color(0xFFF0F0F0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 20 : 4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatMessageTime(timestamp),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tulis pesan...',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.mic, color: Colors.grey.shade600),
                      onPressed: () {
                        // TODO: Implement voice recording
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fitur voice akan datang')),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF0F4AA3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return '$hour:$minute';
      }
      return '${date.day}/${date.month} $hour:$minute';
    } catch (e) {
      return '';
    }
  }

  String _getBookingTypeLabel(String type) {
    switch (type) {
      case 'motor':
        return 'Nebeng Motor';
      case 'mobil':
        return 'Nebeng Mobil';
      case 'barang':
        return 'Nebeng Barang';
      case 'titip':
        return 'Nebeng Titip';
      default:
        return 'Booking';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
