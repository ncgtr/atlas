import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

const String groqApiKey = 'gsk_YOUR_GROQ_API_KEY';
const String modelName = 'meta-llama/llama-4-scout-17b-16e-instruct';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await acrylic.Window.initialize();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(428, 592),
    minimumSize: Size(300, 400),
    maximumSize: Size(700, 900),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    title: "Atlas",
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setResizable(true);
    await windowManager.setAlwaysOnTop(true);

    await acrylic.Window.setEffect(effect: acrylic.WindowEffect.transparent);
    await acrylic.Window.setWindowBackgroundColorToClear();

    await _positionWindowBottomRight();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AtlasStateProvider(),
      child: const AtlasApp(),
    ),
  );
}

Future<void> _positionWindowBottomRight() async {
  Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
  Size windowSize = await windowManager.getSize();

  double posX = primaryDisplay.visiblePosition!.dx + primaryDisplay.visibleSize!.width - windowSize.width - 24;
  double posY = primaryDisplay.visiblePosition!.dy + primaryDisplay.visibleSize!.height - windowSize.height - 24;

  await windowManager.setPosition(Offset(posX, posY));
}

class AtlasApp extends StatefulWidget {
  const AtlasApp({super.key});

  @override
  State<AtlasApp> createState() => _AtlasAppState();
}

class _AtlasAppState extends State<AtlasApp> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _initSystemTray();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  void _initSystemTray() async {
    await trayManager.setIcon('assets/sprites/atlas.ico');
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show', label: 'Open Atlas'),
        MenuItem(key: 'exit', label: 'Quit Application'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  Future<void> _toggleWindowVisibility() async {
    if (await windowManager.isVisible()) {
      await windowManager.setSkipTaskbar(true);
      await windowManager.hide();
    } else {
      await _positionWindowBottomRight();
      await windowManager.setSkipTaskbar(false);
      await windowManager.show();
      await windowManager.focus();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    await _toggleWindowVisibility();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show') {
      await _positionWindowBottomRight();
      await windowManager.setSkipTaskbar(false);
      await windowManager.show();
      await windowManager.focus();
    } else if (menuItem.key == 'exit') {
      io.exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'GoogleSans',
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const AtlasChatScreen(),
    );
  }
}

class AtlasChatScreen extends StatefulWidget {
  const AtlasChatScreen({super.key});

  @override
  State<AtlasChatScreen> createState() => _AtlasChatScreenState();
}

class _AtlasChatScreenState extends State<AtlasChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _autoScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        if (pos.maxScrollExtent - pos.pixels < 40) {
          _autoScrollEnabled = true;
        } else if (pos.isScrollingNotifier.value) {
          _autoScrollEnabled = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
  if (_scrollController.hasClients && _autoScrollEnabled) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AtlasStateProvider>(context);

    if (state.messages.isNotEmpty && _autoScrollEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    bool isInputEmpty = _controller.text.trim().isEmpty;
    final displayMessages = state.messages.where((m) => m['role'] != 'system').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF222222), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onPanStart: (details) => windowManager.startDragging(),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4, right: 8),
                  child: Row(
                    children: [
                      Image.asset('assets/sprites/atlas.png', width: 20, height: 20),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Atlas',
                              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400, color: Colors.white70, fontFamily: 'GoogleSans'),
                            ),
                            TextSpan(text: ' '),
                            TextSpan(
                              text: 'Llama 4 Scout',
                              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w400, color: Colors.white30, fontFamily: 'GoogleSans'),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.white30),
                        onPressed: () async {
                          await windowManager.setSkipTaskbar(true);
                          await windowManager.hide();
                        },
                        hoverColor: Colors.white10,
                        splashRadius: 16,
                      )
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.04, 0.96, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SelectionArea(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.trackpad},
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: displayMessages.length,
                          itemBuilder: (context, index) {
                            final msg = displayMessages[index];
                            final isUser = msg['role'] == 'user';

                            return SlidingChatBubble(
                              key: ValueKey(msg.hashCode),
                              child: Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: MarkdownBody(
                                    data: msg['content'] ?? '',
                                    styleSheet: MarkdownStyleSheet(
                                      p: TextStyle(
                                        fontSize: 15.0,
                                        height: 1.5,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                      code: const TextStyle(
                                        backgroundColor: Colors.black26,
                                        color: Colors.white70,
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                            if (!HardwareKeyboard.instance.isShiftPressed) {
                              _autoScrollEnabled = true;
                              _sendMessage(state);
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 140,
                          ),
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            minLines: 1,
                            strutStyle: const StrutStyle(fontSize: 15.0, height: 1.2, forceStrutHeight: true),
                            style: const TextStyle(fontSize: 15.0, color: Colors.white, height: 1.2),
                            cursorColor: Colors.white54,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Ask anything',
                              hintStyle: const TextStyle(color: Colors.white24, fontSize: 15.0),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              isDense: false,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF444444), width: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    GestureDetector(
                      onTap: () {
                        _autoScrollEnabled = true;
                        _sendMessage(state);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isInputEmpty ? const Color(0xFF18181C) : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isInputEmpty ? const Color(0xFF222226) : const Color(0xFFF0F0F0),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_upward,
                          size: 18,
                          color: isInputEmpty ? Colors.white30 : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage(AtlasStateProvider state) {
    if (_controller.text.trim().isEmpty) return;
    final prompt = _controller.text.trim();
    _controller.clear();
    state.sendPrompt(prompt);
  }
}

class SlidingChatBubble extends StatefulWidget {
  final Widget child;
  const SlidingChatBubble({super.key, required this.child});

  @override
  State<SlidingChatBubble> createState() => _SlidingChatBubbleState();
}

class _SlidingChatBubbleState extends State<SlidingChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}

class AtlasStateProvider extends ChangeNotifier {
  final List<Map<String, String>> _messages = [
    {
      'role': 'system',
      'content': 'You are Atlas, a concise desktop assistant running over Meta\'s Llama 4 Scout via Groq. You are running in the \'Atlas\' desktop app/environment. You have NO native access to local files, system terminals, or real-time web engines. Answers must not be overly long when not required or specifically requested. Blanket Factuality Directive: If the user requests data regarding *any* real-world public figures, singers, creators, regional music albums, historic timelines, or unverified factual metrics, you are strictly forbidden from guessing, assuming, or constructing fictional narratives. Instead, if you lack absolute complete pre-trained knowledge, you must state exactly: "I do not have verified real-time database profiles for that topic."'
    }
  ];

  List<Map<String, String>> get messages => _messages;

  Future<void> sendPrompt(String text) async {
    _messages.add({'role': 'user', 'content': text});
    _messages.add({'role': 'assistant', 'content': ''});
    notifyListeners();

    try {
      final request = http.Request('POST', Uri.parse('https://api.groq.com/openai/v1/chat/completions'));
      request.headers.addAll({
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      });

      request.body = jsonEncode({
        'model': modelName,
        'messages': _messages.sublist(0, _messages.length - 1),
        'stream': true,
        'temperature': 1,
        'max_completion_tokens': 1024,
        'top_p': 1,
      });

      final response = await http.Client().send(request);

      response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();
          if (dataStr == '[DONE]') return;

          try {
            final Map<String, dynamic> parsed = jsonDecode(dataStr);
            final String chunk = parsed['choices'][0]['delta']['content'] ?? '';
            _messages[_messages.length - 1]['content'] = (_messages[_messages.length - 1]['content'] ?? '') + chunk;
            notifyListeners();
          } catch (_) {}
        }
      });
    } catch (e) {
      _messages[_messages.length - 1]['content'] = 'Connection Error. Please check parameters.';
      notifyListeners();
    }
  }
}