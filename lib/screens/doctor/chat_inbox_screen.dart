// Temporary fix for chat_inbox_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/services/chat_service.dart';
import 'package:smartcare_app/utils/chat_status.dart';
import 'package:smartcare_app/screens/doctor/chat_screen.dart';

class ChatInboxScreen extends StatelessWidget {
  const ChatInboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please log in to view chats.'));
    }

    final ChatService _chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Inbox'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Use the no-order method temporarily
        stream: _chatService.getDoctorChatsNoOrder(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error loading chats: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading chats'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force rebuild
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No chats available'),
                  SizedBox(height: 8),
                  Text('Patients will see your chat requests here',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Sort the chats manually by createdAt (newest first)
          final chats = snapshot.data!.docs;
          chats.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime); // Descending order
          });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              final patientName = chatData['patientName'] ?? 'Unknown Patient';
              final status = chatData['status'] ?? 'pending';
              final initialMessage = chatData['initialMessage'] ?? 'No message';
              final patientId = chatData['patientId'];
              final createdAt = chatData['createdAt'] as Timestamp?;

              IconData statusIcon;
              Color statusColor;

              switch (status) {
                case 'pending':
                  statusIcon = Icons.access_time;
                  statusColor = Colors.orange;
                  break;
                case 'active':
                  statusIcon = Icons.chat;
                  statusColor = Colors.green;
                  break;
                case 'closed':
                  statusIcon = Icons.check_circle;
                  statusColor = Colors.grey;
                  break;
                case 'declined':
                  statusIcon = Icons.cancel;
                  statusColor = Colors.red;
                  break;
                default:
                  statusIcon = Icons.help;
                  statusColor = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text(patientName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        initialMessage.length > 50
                            ? '${initialMessage.substring(0, 50)}...'
                            : initialMessage,
                      ),
                      if (createdAt != null)
                        Text(
                          'Created: ${createdAt.toDate().toString().substring(0, 16)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: status == 'pending'
                      ? const Icon(Icons.notification_important, color: Colors.orange)
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorChatScreen(
                          chatId: chats[index].id,
                          patientId: patientId,
                          patientName: patientName,
                          initialMessage: initialMessage,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}