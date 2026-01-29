import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/chat_service.dart';
import '../../../utils/chat_helper.dart';
import '../../../test_firestore.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  int? _userId;
  String _userRole = 'customer';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final userRole = prefs.getString('user_role') ?? 'customer';

    print('🔍 ChatsPage - User ID: $userId, Role: $userRole');

    if (mounted) {
      setState(() {
        _userId = userId;
        _userRole = userRole;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(96),
          child: AppBar(
            backgroundColor: Color(0xFF0F4AA3),
            elevation: 0,
            centerTitle: true,
            title: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text('Pesan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF0F4AA3),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Chats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Chat List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getConversations(_userId!, _userRole),
              builder: (context, snapshot) {
                print('🎬 StreamBuilder state: ${snapshot.connectionState}');
                print('🎬 Has data: ${snapshot.hasData}');
                print('🎬 Has error: ${snapshot.hasError}');
                if (snapshot.hasError) {
                  print('❌ Error: ${snapshot.error}');
                }

                // Show loading only on first load for max 5 seconds
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading conversations...',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('If stuck, check Firestore rules',
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}',
                            style: TextStyle(fontSize: 14, color: Colors.red)),
                        SizedBox(height: 8),
                        Text('${snapshot.stackTrace}',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild
                          },
                          child: Text('Retry'),
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
                        Icon(Icons.message_outlined,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Belum ada percakapan',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Chat akan muncul setelah Anda booking tebengan',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        SizedBox(height: 24),
                        // Test button untuk development
                        ElevatedButton.icon(
                          onPressed: () async {
                            print(
                                '🔘 Button clicked - Creating test conversation...');

                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Creating conversation...'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );

                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final userId = prefs.getInt('user_id');
                              final userName = prefs.getString('user_name') ??
                                  prefs.getString('name') ??
                                  'User ${prefs.getInt('user_id')}';
                              final userRole =
                                  prefs.getString('user_role') ?? 'customer';

                              print(
                                  '👤 User data - ID: $userId, Name: $userName, Role: $userRole');

                              if (userId != null) {
                                final result =
                                    await ChatHelper.createTestConversation(
                                  currentUserId: userId,
                                  currentUserName: userName,
                                  currentUserRole: userRole,
                                );

                                Navigator.pop(context); // Close loading

                                if (result != null) {
                                  print('✅ Success! Conversation ID: $result');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('✅ Test conversation created!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  print('❌ Failed to create conversation');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '❌ Failed to create conversation'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                Navigator.pop(context); // Close loading
                                print(
                                    '❌ User ID not found in SharedPreferences');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '❌ User ID not found. Please login again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e, stackTrace) {
                              Navigator.pop(context); // Close loading
                              print('❌ Exception: $e');
                              print('Stack trace: $stackTrace');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error: $e'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.add),
                          label: Text('Create Test Chat (Dev Only)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0F4AA3),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter conversations based on search query
                final conversations = snapshot.data!.where((conv) {
                  if (_searchQuery.isEmpty) return true;

                  final isCustomer = _userRole == 'customer';
                  final otherName = isCustomer
                      ? (conv['mitraName'] ?? 'Mitra')
                      : (conv['customerName'] ?? 'Customer');
                  final lastMessage = conv['lastMessage'] ?? '';

                  return otherName.toLowerCase().contains(_searchQuery) ||
                      lastMessage.toLowerCase().contains(_searchQuery);
                }).toList();

                if (conversations.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No results found',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Try searching with different keywords',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];

                    // Determine other user (mitra or customer)
                    final isCustomer = _userRole == 'customer';
                    final otherName = isCustomer
                        ? (conv['mitraName'] ?? 'Mitra')
                        : (conv['customerName'] ?? 'Customer');
                    final otherPhoto =
                        isCustomer ? conv['mitraPhoto'] : conv['customerPhoto'];
                    final unread = isCustomer
                        ? (conv['unreadCustomer'] ?? 0)
                        : (conv['unreadMitra'] ?? 0);

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                conversationId: conv['id'],
                                otherUserName: otherName,
                                otherUserPhoto: otherPhoto,
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF0F4AA3).withOpacity(0.1),
                          backgroundImage: otherPhoto != null &&
                                  otherPhoto.toString().isNotEmpty
                              ? NetworkImage(otherPhoto)
                              : null,
                          child: otherPhoto == null ||
                                  otherPhoto.toString().isEmpty
                              ? Icon(Icons.person,
                                  color: Color(0xFF0F4AA3), size: 24)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(conv['lastMessageAt']),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv['lastMessage'] ?? '',
                                  style: TextStyle(
                                    color: unread > 0
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontWeight: unread > 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF6B9B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unread > 9 ? '9+' : '$unread',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(date);

      // Check if it's today
      final isToday = date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;

      // Check if it's yesterday
      final yesterday = now.subtract(Duration(days: 1));
      final isYesterday = date.day == yesterday.day &&
          date.month == yesterday.month &&
          date.year == yesterday.year;

      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}mins';

      if (isToday) {
        // Show time in 12-hour format with AM/PM
        final hour =
            date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
        final minute = date.minute.toString().padLeft(2, '0');
        final period = date.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute$period';
      }

      if (isYesterday) return 'Yesterday';

      // For older messages, show date
      if (diff.inDays < 7) {
        final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        return weekdays[date.weekday % 7];
      }

      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }
}

// Chat page with real-time messages
class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatPage({
    Key? key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserPhoto,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  int? _userId;
  String? _userName;
  String _userRole = 'customer';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
      _userName = prefs.getString('user_name');
      _userRole = prefs.getString('user_role') ?? 'customer';
    });

    // Mark as read when opening chat
    if (_userId != null) {
      _chatService.markAsRead(widget.conversationId, _userId!, _userRole);
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
        senderName: _userName ?? 'User',
        text: text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e')),
      );
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
              child: Text(
                widget.otherUserName,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
