import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/api_service.dart';

enum ChatRole { user, bot }

class ChatMessage {
  final ChatRole role;
  final String text;

  ChatMessage({required this.role, required this.text});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  List<Song> _suggestedSongs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
  }

  void _addInitialMessage() {
    _messages.add(
      ChatMessage(
        role: ChatRole.bot,
        text:
        "Hey, I'm Soniq Bot 🤖🎧\n\nTell me how you feel or what you want to listen to.\n\nTry things like:\n• \"happy songs\"\n• \"sad vibes\"\n• \"focus music\"\n• \"party tracks\"\n• \"chill lofi\"",
      ),
    );
  }

  Future<void> _handleUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, text: text.trim()));
      _isLoading = true;
    });
    _controller.clear();

    final mood = _detectMood(text);
    final searchTerm = mood ?? text.trim();

    try {
      final songs = await _apiService.fetchSongs(search: searchTerm);
      if (!mounted) return;

      setState(() {
        _suggestedSongs = songs;
        _messages.add(
          ChatMessage(
            role: ChatRole.bot,
            text: songs.isEmpty
                ? "I couldn't find anything for \"$searchTerm\" 😔\nTry another mood or keyword."
                : "I found ${songs.length} tracks for \"$searchTerm\".\nTap one below to play it in Soniqverse 🎶",
          ),
        );
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            role: ChatRole.bot,
            text:
            "Oops, something went wrong while fetching songs.\nPlease try again in a moment.",
          ),
        );
      });
      _scrollToBottom();
    }
  }

  String? _detectMood(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('happy') || lower.contains('joy')) return 'happy';
    if (lower.contains('sad') || lower.contains('cry') || lower.contains('broken')) return 'sad';
    if (lower.contains('party') || lower.contains('dance')) return 'party';
    if (lower.contains('gym') || lower.contains('workout')) return 'gym';
    if (lower.contains('focus') || lower.contains('study')) return 'focus';
    if (lower.contains('chill') || lower.contains('relax')) return 'chill';
    if (lower.contains('sleep')) return 'sleep';
    return null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == ChatRole.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? const Color(0xFF1DB954) : const Color(0xFF262626);
    final textColor = isUser ? Colors.black : Colors.white;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          msg.text,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  Widget _buildMoodsChips() {
    final moods = [
      'happy',
      'sad',
      'focus',
      'party',
      'chill',
      'sleep',
      'gym',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: moods
            .map(
              (m) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(m),
              onPressed: () => _handleUserMessage('$m music'),
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildSuggestedSongs() {
    if (_suggestedSongs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Text(
            'Suggestions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestedSongs.length,
          itemBuilder: (context, index) {
            final song = _suggestedSongs[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  song.coverUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note),
                    );
                  },
                ),
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                Navigator.of(context).pop(song);
              },
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soniq Bot'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          _buildMoodsChips(),
          const Divider(height: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._messages.map(_buildMessageBubble),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  _buildSuggestedSongs(),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask for mood, genre, or songs...',
                        filled: true,
                        fillColor: const Color(0xFF1F1F1F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleUserMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _handleUserMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
