import 'dart:developer';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

const urlRegexContent =
    "((http|https)://)(www.)?[a-zA-Z0-9@:%._\\+~#?&//=-]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%._\\+~#?&//=]*)";

List<String>? _getUrls(String? text) {
  if (text == null) return null;
  final urlRegex = RegExp(
    urlRegexContent,
    multiLine: true,
  );
  final matches = urlRegex.allMatches(text);
  return matches.map((match) => match.group(0) ?? '').toList();
}

// model define
class User {
  final String? property;
  final String? email;
  final String? imageUrl;
  final String? uid;

  User({
    this.property,
    this.email,
    this.imageUrl,
    this.uid,
  });
}

class MessageModel {
  final String? message;
  final User? sender;

  MessageModel({
    this.message,
    this.sender,
  });

  static List<MessageModel> mock = [
    MessageModel(
      message:
          'Can you tell me about your experience in mobile app development?',
      sender: User(
        property: 'John Doe',
        imageUrl: 'https://avatar.iran.liara.run/public/2',
        uid: 'user_1',
      ),
    ),
    MessageModel(
      message:
          "Yes, I have been working as a mobile developer for three years, specializing in iOS and Android app development. I've developed several successful apps, including e-commerce and social media platforms.",
      sender: User(
        property: 'King Kong',
        imageUrl: 'https://avatar.iran.liara.run/public/3',
        uid: 'user_2',
      ),
    ),
    MessageModel(
      message:
          "That's impressive. What programming languages do you usually work with?",
      sender: User(
        property: 'John Doe',
        imageUrl: 'https://avatar.iran.liara.run/public/2',
        uid: 'user_1',
      ),
    ),
    MessageModel(
      message:
          "I primarily work with Java, Swift, and Kotlin. I also have experience with React Native for cross-platform development.",
      sender: User(
        property: 'King Kong',
        imageUrl: 'https://avatar.iran.liara.run/public/3',
        uid: 'user_2',
      ),
    ),
  ];
}

final User _currentUser = User(
  property: 'King Kong',
  imageUrl: 'https://avatar.iran.liara.run/public/3',
  uid: 'user_2',
);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<MessageModel> _messages = MessageModel.mock;
  List<String> urls = [];

  @override
  void initState() {
    super.initState();

    _controller.addListener(_inputListener);
  }

  _inputListener() {
    EasyDebounce.debounce("input_listener", const Duration(milliseconds: 200),
        () {
      final text = _controller.text;
      if (text.isEmpty) {
        if (mounted) {
          setState(() {
            urls = [];
          });
        }
        return;
      }
      urls = _getUrls(text) ?? [];
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Chat Screen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMe = message.sender?.uid == _currentUser.uid;
                    return _MessageItem(
                      message: message,
                      isMe: isMe,
                      key: ValueKey(message),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: urls.length,
                    itemBuilder: (context, index) => _UrlPreview(
                      urls[index],
                      key: ValueKey(urls[index]),
                    ),
                  ),
                )
              ],
            ),
          ),
          _MessageInput(
            controller: _controller,
            sendMessage: () {
              if (_controller.text.isNotEmpty) {
                final message = MessageModel(
                  message: _controller.text,
                  sender: _currentUser,
                );
                setState(() {
                  _messages.add(message);
                  _controller.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    EasyDebounce.cancel('input_listener');
    _controller.removeListener(_inputListener);
    _controller.dispose();
    super.dispose();
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController _controller;
  final void Function() sendMessage;

  const _MessageInput({
    super.key,
    required TextEditingController controller,
    required this.sendMessage,
  }) : _controller = controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  cursorHeight: 18,
                  decoration: const InputDecoration(
                    hintText: 'Enter your message',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: sendMessage,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Transform.rotate(
                    angle: 5.5,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({
    super.key,
    required this.message,
    required this.isMe,
  });

  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe)
          CircleAvatar(
            backgroundImage: NetworkImage(message.sender!.imageUrl!),
          ),
        const SizedBox(width: 8),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 16 : 0),
              topRight: Radius.circular(isMe ? 0 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
          ),
          child: Text(
            message.message!,
            style: TextStyle(
              color: isMe
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _UrlPreview extends StatefulWidget {
  const _UrlPreview(this.url, {super.key});
  final String url;

  @override
  State<_UrlPreview> createState() => __UrlPreviewState();
}

class __UrlPreviewState extends State<_UrlPreview> {
  String? title;
  String? description;
  String? imageUrl;

  bool isLoading = true;

  @override
  void initState() {
    _getData();
    super.initState();
  }

  _getData() async {
    try {
      final res = await http.get(Uri.parse(widget.url));
      final document = parse(res.body);
      title = document.querySelector("title")?.text ?? "";
      description = document
              .querySelector("meta[property='og:description']")
              ?.attributes['content'] ??
          '';

      imageUrl = document
              .querySelector("meta[property='og:image']")
              ?.attributes['content'] ??
          '';
      log("url detected: $title, $description, $imageUrl");
    } catch (e) {
      log("get data got error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              image: (imageUrl?.isNotEmpty ?? false)
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          _buildContent()
        ],
      ),
    );
  }

  Widget _buildContent() {
    final child = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${title ?? ""}".trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            description ?? "",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );

    const loading =
        Expanded(child: Center(child: CupertinoActivityIndicator()));

    return isLoading ? loading : child;
  }
}
