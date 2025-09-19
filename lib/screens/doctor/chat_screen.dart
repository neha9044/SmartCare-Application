// lib/screens/doctor/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/services/chat_service.dart';
import 'package:smartcare_app/utils/chat_status.dart';
import 'package:smartcare_app/screens/doctor/patient_record_screen.dart';

class DoctorChatScreen extends StatefulWidget {
  final String chatId;
  final String patientId;
  final String patientName;
  final String initialMessage;

  const DoctorChatScreen({
    Key? key,
    required this.chatId,
    required this.patientId,
    required this.patientName,
    required this.initialMessage,
  }) : super(key: key);

  @override
  _DoctorChatScreenState createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentDoctorId;
  bool _isChatActive = false;
  late StreamSubscription _chatSubscription;

  @override
  void initState() {
    super.initState();
    _currentDoctorId = FirebaseAuth.instance.currentUser?.uid;
    _listenToChatUpdates();
  }

  void _listenToChatUpdates() {
    _chatSubscription = _chatService.getChatStream(widget.chatId).listen((chatSnapshot) {
      if (chatSnapshot.exists) {
        final status = chatSnapshot.get('status');
        setState(() {
          _isChatActive = status == ChatStatus.active.toShortString();
        });
      }
    });
  }

  @override
  void dispose() {
    _chatSubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _acceptChat() async {
    await _chatService.updateChatStatus(widget.chatId, ChatStatus.active);
  }

  void _declineChat() async {
    await _chatService.updateChatStatus(widget.chatId, ChatStatus.declined);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _closeChat() async {
    await _chatService.updateChatStatus(widget.chatId, ChatStatus.closed);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: _currentDoctorId!,
        text: _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.patientName}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isChatActive)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeChat,
              tooltip: 'End Chat',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildChatStatusHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildInitialMessage();
                }

                _scrollToBottom();
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == _currentDoctorId;
                    return _buildMessageBubble(messageData['text'], isMe);
                  },
                );
              },
            ),
          ),
          if (_isChatActive)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildInitialMessage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Initial Inquiry from ${widget.patientName}:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(widget.initialMessage),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _declineChat,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Decline'),
              ),
              ElevatedButton(
                onPressed: _acceptChat,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                child: const Text('Accept Chat'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientRecordScreen(
                    patientId: widget.patientId,
                    patientName: widget.patientName,
                    doctorDetails: {}, // You may need to pass actual doctor details here
                  ),
                ),
              );
            },
            child: const Text('View Patient Record'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatStatusHeader() {
    String statusText;
    Color statusColor;

    if (_isChatActive) {
      statusText = "Chat is active. Ends in 30 minutes.";
      statusColor = Colors.green;
    } else {
      statusText = "Waiting for you to accept.";
      statusColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: statusColor.withOpacity(0.1),
      child: Center(
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryColor : AppColors.lightGrey.withOpacity(0.2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}