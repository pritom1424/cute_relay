import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Ensure these imports match your project structure
import 'package:fast_chat/app_constatnts.dart';
import 'package:fast_chat/pages/chat_screen.dart';
import 'package:fast_chat/widgets/widgets.dart';
import 'session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstatnts.colorPink,
          primary: AppConstatnts.colorPink,
          secondary: AppConstatnts.colorTeal,
          surface: const Color(0xFFFCFCFE),
        ),
      ),
      home: const LobbyScreen(),
    ),
  );
}

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _name = TextEditingController();
  final _room = TextEditingController();
  bool isJoining = false;

  @override
  void initState() {
    super.initState();
    _genRoom();
    SessionManager.flushAllData();
  }

  void _genRoom() {
    _room.text = String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'.codeUnitAt(
          Random().nextInt(36),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          // Background subtle accent
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppConstatnts.colorTeal.withValues(alpha: 0.05),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Refined Animated Logo
                  TweenAnimationBuilder(
                    duration: const Duration(seconds: 2),
                    curve: Curves.elasticOut,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // gradient: const LinearGradient(
                            //   colors: [AppConstatnts.colorPink, AppConstatnts.colorTeal],
                            //   begin: Alignment.topLeft,
                            //   end: Alignment.bottomRight,
                            // ),
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstatnts.colorPink.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/icon.png",
                            scale: 2,
                          ), //const Icon(Icons.bubble_chart_rounded, size: 60, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Animated Professional Title
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double opacity, child) => Opacity(
                      opacity: opacity,
                      child: Column(
                        children: [
                          // const Text(
                          //   "Cute Relay",
                          //   style: TextStyle(
                          //     fontSize: 34,
                          //     fontWeight: FontWeight.bold,
                          //     color: Color(0xFF2D3142),
                          //     letterSpacing: -1.0,
                          //   ),
                          // ),
                          // const SizedBox(height: 8),
                          Text(
                            "Secure • Instant • Transient",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildToggle(),
                  const SizedBox(height: 32),
                  // Professional Inputs
                  LobbyInput(
                    controller: _name,
                    label: "Display Name",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  isJoining
                      ? LobbyInput(
                          controller: _room,
                          label: "Enter Room ID",
                          icon: Icons.vpn_key,
                        )
                      : _buildRoomField(),
                  const SizedBox(height: 40),
                  // Enterprise Level Gradient Button
                  _buildMainButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [_btn("Create", !isJoining), _btn("Join", isJoining)],
    ),
  );

  Widget _btn(String t, bool s) => GestureDetector(
    onTap: () => setState(() {
      isJoining = t == "Join";
      if (isJoining)
        _room.clear();
      else
        _genRoom();
    }),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: BoxDecoration(
        color: s
            ? AppConstatnts.colorPink.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: s ? AppConstatnts.colorPink : Colors.grey.shade500,
          fontWeight: s ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );

  Widget _buildRoomField() => Stack(
    alignment: Alignment.centerRight,
    children: [
      LobbyInput(
        controller: _room,
        label: "Room ID",
        icon: Icons.lock,

        enabled: false,
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppConstatnts.colorTeal),
              onPressed: _genRoom,
            ),
            IconButton(
              icon: Icon(Icons.copy_rounded, color: AppConstatnts.colorTeal),
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: _room.text)),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildMainButton() => Container(
    width: double.infinity,
    height: 58,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      // gradient: LinearGradient(
      //   colors: [AppConstatnts.colorPink, AppConstatnts.colorTeal],
      //   begin: Alignment.centerLeft,
      //   end: Alignment.centerRight,
      // ),
      boxShadow: [
        BoxShadow(
          color: AppConstatnts.colorPink.withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: () async {
        if (_name.text.isNotEmpty && _room.text.isNotEmpty) {
          await Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (c, a1, a2) => ChatScreen(
                userName: _name.text,
                roomId: _room.text,
                isCreating: !isJoining,
              ),
              transitionsBuilder: (c, anim, a2, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
          if (!isJoining) {
            _genRoom();
          }
        }
      },
      child: Text(
        isJoining ? "JOIN ROOM" : "START NEW ROOM",
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
      ),
    ),
  );
}
