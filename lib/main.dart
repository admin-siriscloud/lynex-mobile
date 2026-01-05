import 'package:chatwoot_sdk/chatwoot_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lynex',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Lynex'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ChatwootClient? _chatwootClient;
  bool _isConnected = false;
  final List<ChatwootMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChatwoot();
  }

  void _initializeChatwoot() {
    final chatwootCallbacks = ChatwootCallbacks(
      onWelcome: () {
        debugPrint("on welcome");
        setState(() => _isConnected = true);
      },
      onPing: () {
        debugPrint("on ping");
      },
      onConfirmedSubscription: () {
        debugPrint("on confirmed subscription");
      },
      onConversationStartedTyping: () {
        debugPrint("on conversation started typing");
      },
      onConversationStoppedTyping: () {
        debugPrint("on conversation stopped typing");
      },
      onPersistedMessagesRetrieved: (persistedMessages) {
        debugPrint("persisted messages retrieved: ${persistedMessages.length}");
        setState(() {
          _messages.clear();
          _messages.addAll(persistedMessages);
          _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      },
      onMessagesRetrieved: (messages) {
        debugPrint("messages retrieved: ${messages.length}");
        setState(() {
          for (var msg in messages) {
            if (!_messages.any((existing) => existing.id == msg.id)) {
              _messages.add(msg);
            }
          }
          _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      },
      onMessageReceived: (chatwootMessage) {
        debugPrint("message received: ${chatwootMessage.content}");
        setState(() {
          if (!_messages.any((existing) => existing.id == chatwootMessage.id)) {
            _messages.insert(0, chatwootMessage);
          }
        });
      },
      onMessageDelivered: (chatwootMessage, echoId) {
        debugPrint("message delivered: $echoId");
      },
      onMessageSent: (chatwootMessage, echoId) {
        debugPrint("message sent: $echoId");
        setState(() {
          if (!_messages.any((existing) => existing.id == chatwootMessage.id)) {
            _messages.insert(0, chatwootMessage);
          }
        });
      },
      onError: (error) {
        debugPrint("Ooops! Something went wrong. Error Cause: ${error.cause}");
      },
    );

    const String baseUrl = "https://alfamedics.lynex.app";
    const String inboxIdentifier = "gLFHk7UAv9WzyiZV1qqHGUnD";

    ChatwootClient.create(
      baseUrl: baseUrl,
      inboxIdentifier: inboxIdentifier,
      user: ChatwootUser(
        identifier: "test@test.com",
        name: "Tester test",
        email: "test@test.com",
      ),
      enablePersistence: true,
      callbacks: chatwootCallbacks,
    ).then((client) {
      _chatwootClient = client;
      client.loadMessages();
    }).onError((error, stackTrace) {
      debugPrint("chatwoot client creation failed with error $error: $stackTrace");
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && _chatwootClient != null) {
      _chatwootClient!.sendMessage(
        content: text,
        echoId: DateTime.now().toIso8601String(),
      );
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon/cat.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            Text(widget.title ?? "Lynex"),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text("No hay mensajes aún"))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message.isMine;
                      
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isMine ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message.content ?? "",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
