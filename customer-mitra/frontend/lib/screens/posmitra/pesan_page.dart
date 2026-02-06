import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/shared/chat_service.dart';
import 'pesan/chat_detail_page.dart';

class PesanPage extends StatefulWidget {
  const PesanPage({Key? key}) : super(key: key);

  @override
  State<PesanPage> createState() => _PesanPageState();
}

class _PesanPageState extends State<PesanPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  int? _userId;
  String _userRole = 'posmitra';
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
    final userRole = prefs.getString('user_role') ?? 'posmitra';

    print('🔍 PosMitra PesanPage - User ID: $userId, Role: $userRole');

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
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Pesan',
            style: TextStyle(
              color: Color(0xFF212121),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pesan',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          // Chat List
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getConversationsForPosMitra(_userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('❌ Error loading conversations: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada percakapan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter conversations dengan mitra
                  final conversations = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final participants =
                        data['participants'] as Map<String, dynamic>?;

                    if (participants == null) return false;

                    // Cek apakah current user ada di participants
                    if (!participants.containsKey(_userId.toString())) {
                      return false;
                    }

                    // Cari participant selain user saat ini
                    for (var entry in participants.entries) {
                      if (entry.key != _userId.toString()) {
                        final participantData =
                            entry.value as Map<String, dynamic>;
                        final role = participantData['role'] as String?;

                        // Filter hanya mitra
                        if (role == 'mitra') {
                          // Filter berdasarkan search query
                          if (_searchQuery.isEmpty) return true;

                          final name =
                              (participantData['name'] as String? ?? '')
                                  .toLowerCase();
                          return name.contains(_searchQuery);
                        }
                      }
                    }
                    return false;
                  }).toList();

                  if (conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Belum ada percakapan dengan mitra'
                                : 'Tidak ada hasil pencarian',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversationDoc = conversations[index];
                      final conversationData =
                          conversationDoc.data() as Map<String, dynamic>;
                      final conversationId = conversationDoc.id;
                      final participants = conversationData['participants']
                          as Map<String, dynamic>?;

                      if (participants == null) {
                        return const SizedBox.shrink();
                      }

                      // Ambil data mitra (participant selain pos mitra)
                      String mitraName = 'Mitra';
                      String mitraAvatar = 'https://i.pravatar.cc/150?img=1';
                      String? mitraPhone;

                      for (var entry in participants.entries) {
                        if (entry.key != _userId.toString()) {
                          final participantData =
                              entry.value as Map<String, dynamic>;
                          mitraName =
                              participantData['name'] as String? ?? 'Mitra';
                          mitraPhone = participantData['phone'] as String?;

                          // Generate avatar dari phone number jika ada
                          if (mitraPhone != null && mitraPhone.isNotEmpty) {
                            final hash = mitraPhone.hashCode.abs() % 70;
                            mitraAvatar = 'https://i.pravatar.cc/150?img=$hash';
                          }
                          break;
                        }
                      }

                      // Ambil context (Pos Asal atau Pos Tujuan)
                      final context =
                          conversationData['context'] as String? ?? 'Chat';
                      final tebenganType =
                          conversationData['tebengan_type'] as String? ?? '';

                      // Format label untuk menunjukkan jenis tebengan dan context
                      String contextLabel = context;
                      if (tebenganType.isNotEmpty) {
                        contextLabel =
                            '${tebenganType.toUpperCase()} - $context';
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream:
                            _chatService.getMessagesForPosMitra(conversationId),
                        builder: (context, messageSnapshot) {
                          String lastMessage = 'Belum ada pesan';
                          String lastTime = '';
                          int unreadCount = 0;

                          if (messageSnapshot.hasData &&
                              messageSnapshot.data!.docs.isNotEmpty) {
                            final lastDoc = messageSnapshot.data!.docs.first;
                            final lastMessageData =
                                lastDoc.data() as Map<String, dynamic>;

                            lastMessage =
                                lastMessageData['text'] as String? ?? '';
                            final timestamp =
                                lastMessageData['timestamp'] as Timestamp?;

                            if (timestamp != null) {
                              final now = DateTime.now();
                              final messageTime = timestamp.toDate();
                              final difference = now.difference(messageTime);

                              if (difference.inMinutes < 1) {
                                lastTime = 'Baru saja';
                              } else if (difference.inMinutes < 60) {
                                lastTime = '${difference.inMinutes}m';
                              } else if (difference.inHours < 24) {
                                lastTime = '${difference.inHours}h';
                              } else {
                                lastTime = '${difference.inDays}d';
                              }
                            }

                            // Hitung unread messages
                            unreadCount =
                                messageSnapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final senderId = data['sender_id'].toString();
                              final isRead = data['is_read'] as bool? ?? false;
                              return senderId != _userId.toString() && !isRead;
                            }).length;
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailPage(
                                    conversationId: conversationId,
                                    otherUserName: mitraName,
                                    otherUserAvatar: mitraAvatar,
                                    currentUserId: _userId!,
                                    currentUserRole: _userRole,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        mitraAvatar,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Chat Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mitraName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF212121),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // Context label (MOTOR - Pos Asal, dll)
                                        Text(
                                          contextLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(0xFFEC407A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lastMessage,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Time and Badge
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (lastTime.isNotEmpty)
                                        Text(
                                          lastTime,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      if (unreadCount > 0)
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEC407A),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            unreadCount > 9
                                                ? '9+'
                                                : '$unreadCount',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
