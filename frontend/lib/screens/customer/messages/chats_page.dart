import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(96),
        child: AppBar(
          backgroundColor: Color(0xFF0F4AA3),
          elevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back, color: Color(0xFF0F4AA3)),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text('Chats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: _sampleChats.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 80, endIndent: 16),
              itemBuilder: (context, index) {
                final c = _sampleChats[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(name: c['name']!))),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(c['avatar']!),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(c['name']!, style: TextStyle(fontWeight: FontWeight.w600))),
                      Text(c['time']!, style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(c['last']!, style: TextStyle(color: Colors.grey[700]))),
                        if (c['unread'] == '1')
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(color: Color(0xFFFF6B9B), shape: BoxShape.circle),
                            child: Center(child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final List<Map<String, String>> _sampleChats = [
  {
    'name': 'Eunwoo',
    'last': 'Halo, Pak/Bu. Saya sudah....',
    'time': '5mins',
    'avatar': 'https://i.pravatar.cc/150?img=10',
    'unread': '0'
  },
  {
    'name': 'Lee Jen',
    'last': 'Baik pak',
    'time': '12:05PM',
    'avatar': 'https://i.pravatar.cc/150?img=5',
    'unread': '0'
  },
  {
    'name': 'Jamal',
    'last': 'saya sedang dalam perjalanan men...',
    'time': '3:00PM',
    'avatar': 'https://i.pravatar.cc/150?img=8',
    'unread': '1'
  },
  {
    'name': 'Mahen',
    'last': 'Saya tunggu di depan rumah...',
    'time': '1:35PM',
    'avatar': 'https://i.pravatar.cc/150?img=11',
    'unread': '0'
  },
  {
    'name': 'Hawkins',
    'last': 'Sama-sama, Pak/Bu. Terima kasih...',
    'time': 'Yesterday',
    'avatar': 'https://i.pravatar.cc/150?img=12',
    'unread': '0'
  },
];

// Simple Chat page
class ChatPage extends StatelessWidget {
  final String name;
  const ChatPage({Key? key, required this.name}) : super(key: key);

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
            CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5')),
            SizedBox(width: 10),
            Text(name, style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.call, color: Colors.black87)),
        ],
      ),
      body: ChatConversation(),
    );
  }
}

class ChatConversation extends StatefulWidget {
  @override
  _ChatConversationState createState() => _ChatConversationState();
}

class _ChatConversationState extends State<ChatConversation> {
  final List<Map<String, dynamic>> _messages = [
    {'fromMe': false, 'text': 'Halo, mas. Saya pesan ojek ke alamat saya di Jl. Merdeka No. 10. Sudah dekat?'},
    {'fromMe': true, 'text': 'Halo, kak. Iya, saya sudah dekat. Lagi di Jl. Sudirman. mungkin sekitar 5 menit lagi sampai.'},
    {'fromMe': false, 'text': 'Oke, saya tunggu di depan rumah ya.'},
    {'fromMe': true, 'text': 'Siap, mas. Nanti saya lihat. Terima kasih ya.'},
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              if (m['fromMe']) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: Color(0xFF0F4AA3), borderRadius: BorderRadius.circular(16)) ,
                          child: Text(m['text'], style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=10')),
                    SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: Color(0xFFF2F4F7), borderRadius: BorderRadius.circular(16)),
                        child: Text(m['text'], style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(border: InputBorder.none, hintText: 'Write your message'),
                          ),
                        ),
                        IconButton(onPressed: () {}, icon: Icon(Icons.mic, color: Colors.grey[600])),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (_controller.text.trim().isEmpty) return;
                            setState(() {
                              _messages.add({'fromMe': true, 'text': _controller.text.trim()});
                              _controller.clear();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Color(0xFF0F4AA3), shape: BoxShape.circle),
                            child: Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
