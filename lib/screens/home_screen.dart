import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/api_service.dart';
import '../widgets/now_playing_bar.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AudioPlayer _player = AudioPlayer();

  List<Song> _songs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  int? _currentIndex;
  Duration _position = Duration.zero;
  Duration? _totalDuration;
  ConcatenatingAudioSource? _playlist;

  late StreamSubscription<Duration> _positionSub;
  late StreamSubscription<PlayerState> _playerStateSub;
  late StreamSubscription<Duration?> _durationSub;
  late StreamSubscription<int?> _indexSub;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _listenToPlayer();
  }

  Future<void> _loadSongs({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final songs = await _apiService.fetchSongs(search: search);
      if (!mounted) return;

      if (songs.isEmpty) {
        setState(() {
          _isLoading = false;
          _songs = [];
          _errorMessage = 'No songs found.';
        });
        return;
      }

      final sources = songs
          .map((s) => AudioSource.uri(Uri.parse(s.audioUrl)))
          .toList();

      final playlist = ConcatenatingAudioSource(children: sources);

      await _player.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      setState(() {
        _songs = songs;
        _isLoading = false;
        _currentIndex = 0;
        _playlist = playlist;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading songs: $e';
      });
    }
  }

  void _listenToPlayer() {
    _positionSub = _player.positionStream.listen((pos) {
      setState(() => _position = pos);
    });

    _durationSub = _player.durationStream.listen((d) {
      setState(() => _totalDuration = d);
    });

    _indexSub = _player.currentIndexStream.listen((index) {
      if (!mounted) return;
      setState(() => _currentIndex = index);
    });

    _playerStateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero, index: 0);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _playerStateSub.cancel();
    _durationSub.cancel();
    _indexSub.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playSongAtIndex(int index) async {
    if (index < 0 || index >= _songs.length) return;
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  void _togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() {});
  }

  void _playNext() {
    final current = _currentIndex ?? 0;
    final next = current + 1;
    if (next < _songs.length) {
      _playSongAtIndex(next);
    }
  }

  void _playPrevious() {
    final current = _currentIndex ?? 0;
    final prev = current - 1;
    if (prev >= 0) {
      _playSongAtIndex(prev);
    }
  }

  void _seekTo(double seconds) {
    _player.seek(Duration(seconds: seconds.toInt()));
  }

  Future<void> _openChatbot() async {
    final Song? selected = await Navigator.of(context).push<Song>(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );

    if (selected == null) return;

    final existingIndex = _songs.indexWhere((s) => s.id == selected.id);
    if (existingIndex != -1) {
      _playSongAtIndex(existingIndex);
      return;
    }

    if (_playlist == null) {
      final newPlaylist = ConcatenatingAudioSource(
        children: [AudioSource.uri(Uri.parse(selected.audioUrl))],
      );
      await _player.setAudioSource(newPlaylist, initialIndex: 0);
      setState(() {
        _songs = [selected];
        _playlist = newPlaylist;
        _currentIndex = 0;
      });
      _player.play();
    } else {
      await _playlist!.add(AudioSource.uri(Uri.parse(selected.audioUrl)));
      setState(() => _songs = [..._songs, selected]);
      _playSongAtIndex(_songs.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _player.playing;
    final hasSong =
        _currentIndex != null && _currentIndex! >= 0 && _currentIndex! < _songs.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text('Soniqverse'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSongs(
              search: _searchQuery.isEmpty ? null : _searchQuery,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _openChatbot,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search songs, moods, artists...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) => _searchQuery = value,
              onSubmitted: (value) {
                _searchQuery = value;
                _loadSongs(search: value);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatbot,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Ask Soniq Bot'),
      ),
      body: _buildBody(),
      bottomNavigationBar: hasSong
          ? NowPlayingBar(
        song: _songs[_currentIndex!],
        isPlaying: isPlaying,
        position: _position,
        total: _totalDuration ?? _songs[_currentIndex!].duration,
        onPlayPause: _togglePlayPause,
        onNext: _playNext,
        onPrevious: _playPrevious,
        onSeek: _seekTo,
      )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        final isCurrent = index == _currentIndex;

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song.coverUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 56,
                height: 56,
                color: Colors.grey[800],
                child: const Icon(Icons.music_note),
              ),
            ),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle:
          Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: isCurrent
              ? const Icon(Icons.equalizer, color: Colors.green)
              : const Icon(Icons.play_arrow),
          onTap: () => _playSongAtIndex(index),
        );
      },
    );
  }
}
