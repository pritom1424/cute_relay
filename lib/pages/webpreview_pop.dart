import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class WebPreviewPopup extends StatefulWidget {
  final String url;
  const WebPreviewPopup({super.key, required this.url});

  @override
  State<WebPreviewPopup> createState() => _WebPreviewPopupState();
}

class _WebPreviewPopupState extends State<WebPreviewPopup> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle area
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
                WebViewWidget(
                  controller: _controller,
                  // THIS IS THE KEY FIX:
                  // It forces the WebView to claim vertical drag gestures
                  gestureRecognizers: {
                    Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                    ),
                  },
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
