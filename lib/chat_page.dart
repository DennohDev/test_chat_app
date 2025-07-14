import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String userId;
  final String userEmail;
  const ChatPage({Key? key, required this.userId, required this.userEmail})
    : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _chatStream() {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('participants', arrayContains: currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendNotification(
    String fcmToken,
    String title,
    String body,
  ) async {
    final url =
        'https://notification-service-hmzb.onrender.com/send-notification'; // TODO: Replace with your deployed URL
    try {
      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcmToken': fcmToken, 'title': title, 'body': body}),
      );
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await FirebaseFirestore.instance.collection('messages').add({
      'senderId': currentUser!.uid,
      'receiverId': widget.userId,
      'participants': [currentUser!.uid, widget.userId],
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Fetch recipient's FCM token
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final fcmToken = userDoc.data()?['fcmToken'];
    final senderEmail = currentUser?.email ?? 'Someone';
    if (fcmToken != null) {
      await sendNotification(fcmToken, 'Message from $senderEmail', text);
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userEmail)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                final messages = snapshot.data!.docs
                    .where(
                      (doc) =>
                          (doc['senderId'] == currentUser!.uid &&
                              doc['receiverId'] == widget.userId) ||
                          (doc['senderId'] == widget.userId &&
                              doc['receiverId'] == currentUser!.uid),
                    )
                    .toList();
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser!.uid;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(msg['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
