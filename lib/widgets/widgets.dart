import 'dart:convert';
import 'package:fast_chat/app_constatnts.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this to pubspec.yaml

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  // Key is vital here to prevent the image from disappearing on keyboard pop
  const ChatBubble({
    required Key key,
    required this.message,
    required this.isMe,
  }) : super(key: key);
  void _showFullScreenImage(BuildContext context, String type, String content) {
    // Helper to determine if content is a URL or Base64
    bool isUrl = content.startsWith('http');

    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: isUrl
                ? CachedNetworkImage(imageUrl: content)
                : Image.memory(base64Decode(content), gaplessPlayback: true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message['type'] == 'system') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            message['content'],
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppConstatnts.colorTeal
              : AppConstatnts
                    .colorPink, //isMe ? const Color(0xFF7E72B8) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final String content = message['content'];
    final bool isUrl = content.startsWith('http');

    if (message['type'] == 'image' || message['type'] == 'gif') {
      return GestureDetector(
        onTap: () => _showFullScreenImage(context, message['type'], content),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isUrl
              ? CachedNetworkImage(
                  imageUrl: content,
                  placeholder: (context, url) => const SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.cover,
                )
              : Image.memory(
                  base64Decode(content),
                  gaplessPlayback: true,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
        ),
      );
    }

    return Text(
      content,
      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
    );
  }
}

// Add this for the Lobby
class LobbyInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;

  const LobbyInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        prefixIconColor: Colors.teal,
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
