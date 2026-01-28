import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/chat_service.dart';
import '../../../utils/chat_helper.dart';
import 'chat_detail_page.dart';

class MitraChatsPage extends StatefulWidget {
  const MitraChatsPage({Key? key}) : super(key: key);

  @override
  State<MitraChatsPage> createState() => _MitraChatsPageState();
}

class _MitraChatsPageState extends State<MitraChatsPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  int? _userId;
  String _userRole = 'mitra';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final userRole = prefs.getString('user_role') ?? 'mitra';

    print('🔍 MitraChatsPage - User ID: $userId, Role: $userRole');

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
        appBar: AppBar(
          backgroundColor: Color(0xFF0F4AA3),
          elevation: 0,
          title: Text(
            'Chats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
        title: Text(
          'Chats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
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
                print(
                    '🎬 MitraChatsPage StreamBuilder state: ${snapshot.connectionState}');
                print('🎬 Has data: ${snapshot.hasData}');
                print('🎬 Has error: ${snapshot.hasError}');

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
                        Text(
                            'Chat akan muncul setelah ada customer yang booking',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Filter conversations based on search query
                final conversations = snapshot.data!.where((conv) {
                  if (_searchQuery.isEmpty) return true;
                  final customerName =
                      (conv['customerName'] as String? ?? '').toLowerCase();
                  final lastMessage =
                      (conv['lastMessage'] as String? ?? '').toLowerCase();
                  return customerName.contains(_searchQuery) ||
                      lastMessage.contains(_searchQuery);
                }).toList();

                if (conversations.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No chats found',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final conversationId = conv['id'] as String;
                    final customerName =
                        conv['customerName'] as String? ?? 'Customer';
                    final customerPhoto = conv['customerPhoto'] as String?;
                    final lastMessage = conv['lastMessage'] as String? ?? '';
                    final unreadCount = conv['unreadMitra'] as int? ?? 0;
                    final lastMessageAt = conv['lastMessageAt'] as Timestamp?;
                    final bookingType =
                        conv['bookingType'] as String? ?? 'motor';

                    String timeText = '';
                    if (lastMessageAt != null) {
                      final lastTime = lastMessageAt.toDate();
                      final now = DateTime.now();
                      final diff = now.difference(lastTime);
                      final today = DateTime(now.year, now.month, now.day);
                      final yesterday = today.subtract(Duration(days: 1));
                      final lastDate =
                          DateTime(lastTime.year, lastTime.month, lastTime.day);

                      if (diff.inSeconds < 60) {
                        timeText = 'now';
                      } else if (diff.inMinutes < 60) {
                        timeText = '${diff.inMinutes}mins';
                      } else if (lastDate == today) {
                        // Today - show time
                        final hour = lastTime.hour > 12
                            ? lastTime.hour - 12
                            : (lastTime.hour == 0 ? 12 : lastTime.hour);
                        final minute =
                            lastTime.minute.toString().padLeft(2, '0');
                        final period = lastTime.hour >= 12 ? 'PM' : 'AM';
                        timeText = '$hour:$minute$period';
                      } else if (lastDate == yesterday) {
                        timeText = 'Yesterday';
                      } else if (diff.inDays < 7) {
                        // This week - show day name
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        timeText = days[lastTime.weekday - 1];
                      } else {
                        // Older - show date
                        timeText = '${lastTime.day}/${lastTime.month}';
                      }
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MitraChatDetailPage(
                              conversationId: conversationId,
                              otherUserName: customerName,
                              otherUserPhoto: customerPhoto,
                              bookingType: bookingType,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.grey[300]!, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFF0F4AA3),
                              backgroundImage: customerPhoto != null &&
                                      customerPhoto.isNotEmpty
                                  ? NetworkImage(customerPhoto)
                                  : null,
                              child:
                                  customerPhoto == null || customerPhoto.isEmpty
                                      ? Text(
                                          customerName.isNotEmpty
                                              ? customerName[0].toUpperCase()
                                              : 'C',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : null,
                            ),
                            SizedBox(width: 12),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          customerName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (timeText.isNotEmpty)
                                        Text(
                                          timeText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: unreadCount > 0
                                                ? Color(0xFF0F4AA3)
                                                : Colors.grey,
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lastMessage.isEmpty
                                              ? 'Belum ada pesan'
                                              : lastMessage,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: lastMessage.isEmpty
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (unreadCount > 0) ...[
                                        SizedBox(width: 8),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Color(0xFFEC4899),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              unreadCount > 9
                                                  ? '9+'
                                                  : unreadCount.toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
}
