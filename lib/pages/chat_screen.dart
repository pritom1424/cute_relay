import 'package:fast_chat/app_constatnts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import 'dart:convert';
import 'dart:async';
import '../session_manager.dart';
import '../widgets/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChatScreen extends StatefulWidget {
  final String userName, roomId;
  final bool isCreating; // ADD THIS
  const ChatScreen({
    super.key,
    required this.userName,
    required this.roomId,
    this.isCreating = false,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _localUserId = ''; // ADD THIS
  IO.Socket? socket;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> messages = [];
  bool isOnline = false;
  bool showEmoji = false;
  bool isInitializing = true; // Added to manage initial loading state

  final ValueNotifier<bool> _otherTyping = ValueNotifier<bool>(false);
  Timer? _typingTimer;

  List<String> _gifIds = [];
  bool _gifLoading = false;
  bool _gifError = false;

  //custom GIF
  Future<void> _loadGifs() async {
    try {
      setState(() {
        _gifLoading = true;
        _gifError = false;
      });

      final res = await http.get(Uri.parse(AppConstatnts.rawURlGif));

      if (res.statusCode != 200) {
        throw Exception("Failed to load manifest");
      }

      final data = jsonDecode(res.body);

      List pages = data['pages'] ?? [];

      List<String> loaded = [];

      for (var page in pages) {
        for (var item in page['items']) {
          loaded.add(item.toString());
        }
      }

      setState(() {
        _gifIds = loaded;
        _gifLoading = false;
      });
    } catch (e) {
      setState(() {
        _gifLoading = false;
        _gifError = true;
      });
    }
  }
  void _openGifPicker() {
    _loadGifs();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: _gifLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _gifError
                  ? Center(
                child: ElevatedButton(
                  onPressed: _loadGifs,
                  child: const Text("Retry"),
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: _gifIds.length,
                itemBuilder: (context, index) {
                  final id = _gifIds[index];
                  final url =
                      "${AppConstatnts.cloudinaryBase}$id.gif";

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _send('gif', url);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  //end custom GIF

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && showEmoji) setState(() => showEmoji = false);
    });
    _setup();
  }

  @override
  void dispose() {
    socket?.off('receive-payload');
    socket?.disconnect();
    socket?.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _otherTyping.dispose();
    _typingTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    final prefs = await SharedPreferences.getInstance();

    // Get or create a stable local user ID
    String? localId = prefs.getString('local_user_id');
    if (localId == null) {
      localId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('local_user_id', localId);
    }
    _localUserId = localId;

    // Load history
    String? history = prefs.getString('chat_${widget.roomId}');
    if (history != null) {
      if (mounted) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(jsonDecode(history));
        });
      }
      _jump();
    }

    // Fetch Dynamic URL from Gist
    try {
      final String rawGistURl =
          "https://gist.githubusercontent.com/pritom1424/145109e9439d97ea90ac8ecdb9ac2bd8/raw/config.json";

      final response = await http
          .get(Uri.parse(rawGistURl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String socketUrl = data['socket_url'];

        // On web, replace https with wss for the socket connection
        if (kIsWeb) {
          socketUrl = socketUrl.replaceFirst('https://', 'wss://');
        }
        _connect(socketUrl);
      } else {
        throw Exception("Gist Load Failed");
      }
    } catch (e) {
      _connect('https://capable-cariotta-pumpkin-d453d8e0.koyeb.app');
    }
  }

  void _connect(String url) {
    socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      if (widget.isCreating) {
        socket!.emit('create-room', widget.roomId);
      } else {
        socket!.emit('join-room', widget.roomId);
      }
    });

    socket!.on('system-msg', (data) {
      if (!mounted) return;
      if (data['status'] == 'success') {
        setState(() {
          isInitializing = false;
          isOnline = true;
        });
        _send('system', '${widget.userName} joined ✨', saveLocally: false);
      } else {
        socket!.disconnect();
        _showErrorDialog(data['message']);
      }
    });

    socket!.on('receive-payload', (data) {
      if (!mounted) return;

      if (data['type'] == 'typing') {
        if (data['senderId'] != _localUserId) {
          // ← FIXED
          _otherTyping.value = data['isTyping'] ?? false;
        }
        return;
      }

      setState(() {
        bool isDuplicate = messages.any(
          (m) =>
              m['content'] == data['content'] &&
              m['senderId'] == data['senderId'],
        );

        if (!isDuplicate || data['type'] == 'system') {
          messages.add(Map<String, dynamic>.from(data));
          _save();
          _jump();
        }
      });
    });

    socket!.onConnectError((err) {
      if (mounted) setState(() => isInitializing = false);
      print("Connection Error: $err");
    });
  }

  // Add this helper method inside _ChatScreenState
  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Oops!"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Lobby
            },
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }

  void _send(String type, String content, {bool saveLocally = true}) {
    if (socket == null) return;
    var data = {
      'roomId': widget.roomId,
      'type': type,
      'content': content,
      'senderName': widget.userName,
      'senderId': _localUserId, // ← FIXED
    };
    socket!.emit('send-payload', data);

    if (saveLocally && type != 'system') {
      setState(() => messages.add(data));
      _save();
      _jump();
    }
  }

  void _onTextChanged(String val) {
    if (socket == null) return;
    socket!.emit('send-payload', {
      'roomId': widget.roomId,
      'type': 'typing',
      'isTyping': val.isNotEmpty,
      'senderId': _localUserId, // ← FIXED
    });
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && socket != null)
        socket!.emit('send-payload', {
          'roomId': widget.roomId,
          'type': 'typing',
          'isTyping': false,
          'senderId': _localUserId, // ← FIXED
        });
    });
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      _send('image', base64Encode(bytes));
    }
  }

  Future<void> _pickGiphy() async {
    GiphyGif? gif = await GiphyGet.getGif(
      context: context,
      apiKey: 'gA8nJlYL5wy3QeeHaQSby8Na46CqjQ6G',
    );
    if (gif?.images?.fixedHeightDownsampled?.url != null)
      _send('gif', gif!.images!.fixedHeightDownsampled!.url);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('chat_${widget.roomId}', jsonEncode(messages));
  }

  void _jump() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isWide = screen.width > 600;

    final chatBody = isInitializing
        ? Center(
            child: LoadingAnimationWidget.fourRotatingDots(
              color: AppConstatnts.colorTeal,
              size: screen.height * 0.06,
            ),
          )
        : PopScope(
            canPop: !showEmoji,
            onPopInvokedWithResult: (didPop, result) {
              if (showEmoji) setState(() => showEmoji = false);
            },
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _focusNode.unfocus();
                      setState(() => showEmoji = false);
                    },
                    child: ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 24 : 16,
                        vertical: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (c, i) => ChatBubble(
                        key: ValueKey(messages[i]['content'] + i.toString()),
                        message: messages[i],
                        isMe: messages[i]['senderId'] == _localUserId,
                      ),
                    ),
                  ),
                ),
                _buildInputArea(isWide),
                if (!kIsWeb && showEmoji)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) =>
                          _controller.text += emoji.emoji,
                    ),
                  ),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Room ID: ${widget.roomId}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _otherTyping,
              builder: (context, typing, _) => Text(
                typing
                    ? "typing..."
                    : (isOnline ? "Active now" : "Connecting..."),
                style: TextStyle(
                  fontSize: 12,
                  color: typing
                      ? Colors.blue
                      : (isOnline ? Colors.green : Colors.orange),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.pink),
            onPressed: () async {
              await SessionManager.clearRoom(widget.roomId);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      // On wide screens, center the chat with max width
      body: isWide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: chatBody,
              ),
            )
          : chatBody,
    );
  }

  Widget _buildInputArea(bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // IconButton(
            //   icon: Icon(
            //     showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
            //   ),
            //   color: Colors.teal,
            //   onPressed: () {
            //     if (showEmoji) {
            //       _focusNode.requestFocus();
            //     } else {
            //       _focusNode.unfocus();
            //       setState(() => showEmoji = true);
            //     }
            //   },
            // ),
            IconButton(onPressed: _openGifPicker, icon: const Icon(Icons.gif_box),),
            IconButton(
              icon: const Icon(Icons.gif_box_outlined),
              onPressed: _pickGiphy,
              color: Colors.teal,
            ),
            // Hide emoji + giphy buttons on web
            // if (!kIsWeb) ...[
            //   IconButton(
            //     icon: Icon(
            //       showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
            //     ),
            //     color: Colors.teal,
            //     onPressed: () {
            //       if (showEmoji) {
            //         _focusNode.requestFocus();
            //       } else {
            //         _focusNode.unfocus();
            //         setState(() => showEmoji = true);
            //       }
            //     },
            //   ),
            //   IconButton(
            //     icon: const Icon(Icons.gif_box_outlined),
            //     onPressed: _pickGiphy,
            //     color: Colors.teal,
            //   ),
            // ],
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: _pickImage,
              color: Colors.pink,
            ),
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                controller: _controller,
                onChanged: _onTextChanged,
                onSubmitted: (_) {
                  // Allow Enter key to send on web
                  if (kIsWeb && _controller.text.trim().isNotEmpty) {
                    _send('text', _controller.text.trim());
                    _controller.clear();
                    _onTextChanged("");
                  }
                },
                contentInsertionConfiguration: ContentInsertionConfiguration(
                  allowedMimeTypes: const <String>[
                    'image/gif',
                    'image/png',
                    'image/jpeg',
                  ],
                  onContentInserted: (KeyboardInsertedContent content) async {
                    if (content.data != null) {
                      _send('gif', base64Encode(content.data!));
                    } else if (content.uri.isNotEmpty) {
                      _send('gif', content.uri);
                    }
                  },
                ),
                decoration: InputDecoration(
                  hintText: kIsWeb
                      ? "Message... (Enter to send)"
                      : "Message...",
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.pink),
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  _send('text', _controller.text.trim());
                  _controller.clear();
                  _focusNode.unfocus();
                  setState(() => showEmoji = false);
                  _onTextChanged("");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


class GifItem {
  final String id;

  GifItem({required this.id});

  factory GifItem.fromJson(dynamic json) {
    return GifItem(id: json.toString());
  }
}