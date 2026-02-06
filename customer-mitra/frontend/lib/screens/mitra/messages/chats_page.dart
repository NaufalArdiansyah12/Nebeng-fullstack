import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/shared/chat_service.dart';

import 'chat_detail_page.dart';

class MitraChatsPage extends StatefulWidget {
  const MitraChatsPage({Key? key}) : super(key: key);

  @override
  State<MitraChatsPage> createState() => _MitraChatsPageState();
}

class _MitraChatsPageState extends State<MitraChatsPage> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  TabController? _tabController;
  int? _userId;
  String _userRole = 'mitra';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final userRole = prefs.getString('user_role') ?? 'mitra';

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              icon: Icon(Icons.person),
              text: 'Customer',
            ),
            Tab(
              icon: Icon(Icons.store),
              text: 'Pos Mitra',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Customer Conversations
          _buildChatList(filterRole: 'customer'),
          // Tab 2: Pos Mitra Conversations
          _buildChatList(filterRole: 'posmitra'),
        ],
      ),
    );
  }

  Widget _buildChatList({required String filterRole}) {
    return Column(
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
          child: _buildConversationList(filterRole: filterRole),
        ),
      ],
    );
  }

  Widget _buildConversationList({required String filterRole}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getConversations(_userId!, _userRole),
              builder: (context, snapshot) {
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
                        Icon(
                          filterRole == 'posmitra' 
                            ? Icons.store_outlined 
                            : Icons.message_outlined,
                          size: 80, 
                          color: Colors.grey
                        ),
                        SizedBox(height: 16),
                        Text('Belum ada percakapan',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text(
                            filterRole == 'posmitra'
                              ? 'Chat dengan Pos Mitra akan muncul setelah Anda membuat tebengan'
                              : 'Chat akan muncul setelah ada customer yang booking',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Filter conversations based on role and search query
                final allConversations = snapshot.data!.where((conv) {
                  // Filter by role first
                  final otherUserRole = conv['otherUserRole'] as String?;
                  final isOldFormat = conv['_type'] == 'old_format';
                  
                  // For old format (customer-mitra), consider it as customer conversation
                  bool matchesRole;
                  if (filterRole == 'customer') {
                    matchesRole = isOldFormat || otherUserRole == 'customer';
                  } else {
                    matchesRole = !isOldFormat && otherUserRole == 'posmitra';
                  }
                  
                  if (!matchesRole) return false;
                  
                  // Then filter by search query
                  if (_searchQuery.isEmpty) return true;
                  final customerName =
                      (conv['customerName'] as String? ?? '').toLowerCase();
                  final lastMessage =
                      (conv['lastMessage'] as String? ?? '').toLowerCase();
                  return customerName.contains(_searchQuery) ||
                      lastMessage.contains(_searchQuery);
                }).toList();

                if (allConversations.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
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
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          filterRole == 'posmitra' 
                            ? Icons.store_outlined 
                            : Icons.message_outlined,
                          size: 80, 
                          color: Colors.grey
                        ),
                        SizedBox(height: 16),
                        Text('Belum ada percakapan',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text(
                            filterRole == 'posmitra'
                              ? 'Chat dengan Pos Mitra akan muncul setelah Anda membuat tebengan'
                              : 'Chat akan muncul setelah ada customer yang booking',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final conversations = allConversations;

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
                    final conversationContext = conv['context'] as String?;
                    final otherUserRole = conv['otherUserRole'] as String?;

                    // Determine if this is pos mitra conversation
                    final isPosMitra = otherUserRole == 'posmitra';

                    // Create display name with context
                    String displayName = customerName;
                    if (isPosMitra && conversationContext != null) {
                      displayName = '$customerName ($conversationContext)';
                    }

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
                              isPosMitra: isPosMitra,
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
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: isPosMitra
                                      ? Color(0xFFEC4899)
                                      : Color(0xFF0F4AA3),
                                  backgroundImage: customerPhoto != null &&
                                          customerPhoto.isNotEmpty
                                      ? NetworkImage(customerPhoto)
                                      : null,
                                  child: customerPhoto == null ||
                                          customerPhoto.isEmpty
                                      ? Icon(
                                          isPosMitra
                                              ? Icons.store
                                              : Icons.person,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : null,
                                ),
                                if (isPosMitra)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFEC4899),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.location_on,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
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
                                            if (isPosMitra)
                                              Text(
                                                'Pos Mitra',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFEC4899),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
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
            );
  }
}