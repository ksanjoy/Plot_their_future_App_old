import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_theme.dart';

class WeddingVideoPlayerDialog extends StatefulWidget {
  final String? videoUrl;
  final String title;
  final String? coverImageUrl;

  const WeddingVideoPlayerDialog({
    super.key,
    this.videoUrl,
    required this.title,
    this.coverImageUrl,
  });

  static void show(BuildContext context, {String? videoUrl, String? title, String? coverImageUrl}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) => WeddingVideoPlayerDialog(
        videoUrl: videoUrl,
        title: title ?? 'Wedding Invitation & Video Reel',
        coverImageUrl: coverImageUrl,
      ),
    );
  }

  @override
  State<WeddingVideoPlayerDialog> createState() => _WeddingVideoPlayerDialogState();
}

class _WeddingVideoPlayerDialogState extends State<WeddingVideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() async {
    final rawUrl = widget.videoUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(rawUrl));
      } else {
        final cleanPath = rawUrl.replaceFirst('file://', '');
        final file = File(cleanPath);
        if (await file.exists()) {
          _controller = VideoPlayerController.file(file);
        } else {
          // Attempt network parse if path might be a URL without scheme, else fail gracefully
          if (rawUrl.contains('://')) {
            _controller = VideoPlayerController.networkUrl(Uri.parse(rawUrl));
          } else {
            setState(() => _hasError = true);
            return;
          }
        }
      }

      await _controller!.initialize();
      _controller!.setLooping(true);
      await _controller!.play();

      _controller!.addListener(() {
        if (mounted) {
          final isPlayingNow = _controller!.value.isPlaying;
          if (_isPlaying != isPlayingNow) {
            setState(() => _isPlaying = isPlayingNow);
          }
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('[WeddingVideoPlayer] Initialization error: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 440,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF131110),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFC58B24), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.crimsonMaroon.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.movie_creation_outlined, color: Color(0xFFEADBBE), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF3E5AB),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Video player / Fallback preview
            Flexible(
              child: ClipRRect(
                child: _buildVideoContent(),
              ),
            ),

            // Bottom controls
            if (_isInitialized && _controller != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: Colors.black.withOpacity(0.4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scrub slider
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller!,
                      builder: (context, value, _) {
                        final pos = value.position.inMilliseconds.toDouble();
                        final dur = value.duration.inMilliseconds.toDouble();
                        return Row(
                          children: [
                            Text(
                              _formatDuration(value.position),
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: const Color(0xFFC58B24),
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: const Color(0xFFF3E5AB),
                                ),
                                child: Slider(
                                  value: pos.clamp(0.0, dur > 0 ? dur : 1.0),
                                  min: 0.0,
                                  max: dur > 0 ? dur : 1.0,
                                  onChanged: (v) {
                                    _controller!.seekTo(Duration(milliseconds: v.toInt()));
                                  },
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(value.duration),
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        );
                      },
                    ),

                    // Controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: const Color(0xFFF3E5AB),
                                size: 30,
                              ),
                              onPressed: () {
                                if (_isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white70,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isMuted = !_isMuted;
                                  _controller!.setVolume(_isMuted ? 0.0 : 1.0);
                                });
                              },
                            ),
                          ],
                        ),
                        Text(
                          'HD Wedding Reel',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFC58B24),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isInitialized && _controller != null) {
      return GestureDetector(
        onTap: () {
          if (_isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        },
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : (16 / 9),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),
              if (!_isPlaying)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Color(0xFFF3E5AB), size: 36),
                ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        height: 240,
        padding: const EdgeInsets.all(20),
        color: Colors.black26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Color(0xFFC58B24), size: 40),
            const SizedBox(height: 12),
            Text(
              'Wedding Video Reel Not Available',
              style: GoogleFonts.cinzel(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'The uploaded video file could not be accessed from this device storage.',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Loading State
    return Container(
      height: 240,
      color: Colors.black12,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFC58B24), strokeWidth: 2.5),
            SizedBox(height: 12),
            Text(
              'Loading Wedding Video...',
              style: TextStyle(color: Color(0xFFF3E5AB), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
