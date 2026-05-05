import 'dart:convert';
import 'dart:html' as html; // only used on web
import 'package:fast_chat/app_constatnts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Ensure this is in pubspec.yaml

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const ChatBubble({
    required Key key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  // 1. Image Full Screen Viewer
  void _showFullScreenImage(BuildContext context, String content) {
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

  // 2. WebView Pop-up (Bottom Sheet)
  void _showWebPopup(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WebPreviewPopup(url: url),
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
          color: isMe ? AppConstatnts.colorTeal : AppConstatnts.colorPink,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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

    // Handle Images and GIFs
    if (message['type'] == 'image' || message['type'] == 'gif') {
      return GestureDetector(
        onTap: () => _showFullScreenImage(context, content),
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

    // Handle Text (and detect Links for WebView)
    return GestureDetector(
      onTap: isUrl ? () {
        if (kIsWeb) {
          // Open in new tab on web
          html.window.open(content, '_blank');
        } else {
          _showWebPopup(context, content);
        }
      } : null,
      child: Text(
        content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
          decorationColor: isMe ? Colors.white70 : Colors.blue,
        ),
      ),
    );
  }
}

// Internal WebView Pop-up Class
// Internal WebView Pop-up Class - FIXED SCROLLING
class _WebPreviewPopup extends StatefulWidget {
  final String url;
  const _WebPreviewPopup({required this.url});

  @override
  State<_WebPreviewPopup> createState() => _WebPreviewPopupState();
}

class _WebPreviewPopupState extends State<_WebPreviewPopup> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Allows the webview to handle its own scrolling
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Height set to 90% for a better "Browser" feel
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 5,
            width: 45,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Wrap in a GestureDetector to prevent the bottom sheet
                // from intercepting the scroll swipes
                GestureDetector(
                  onVerticalDragUpdate:
                      (
                        _,
                      ) {}, // Prevents "dragging down" to close while scrolling content
                  child: WebViewWidget(controller: _controller),
                ),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
