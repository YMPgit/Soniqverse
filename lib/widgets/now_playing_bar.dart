import 'package:flutter/material.dart';
import '../models/song.dart';

class NowPlayingBar extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final Duration position;
  final Duration? total;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<double> onSeek;

  const NowPlayingBar({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.total,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
  });

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = total ?? song.duration ?? const Duration(minutes: 3);

    final double maxSeconds = totalDuration.inSeconds.toDouble();
    final double currentSeconds =
    position.inSeconds.clamp(0, totalDuration.inSeconds).toDouble();

    return Material(
      elevation: 8,
      color: const Color(0xFF181818),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipRRect(
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: onPrevious,
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                    ),
                    iconSize: 36,
                    onPressed: onPlayPause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: onNext,
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(fontSize: 11),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentSeconds,
                      max: maxSeconds <= 0 ? 1 : maxSeconds,
                      onChanged: (value) => onSeek(value),
                    ),
                  ),
                  Text(
                    _formatDuration(totalDuration),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
