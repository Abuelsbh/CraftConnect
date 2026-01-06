import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    
    await _controller.initialize();
    
    _controller.addListener(_videoListener);
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
        _duration = _controller.value.duration;
        _position = _controller.value.position;
      });
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
        _position = _controller.value.position;
        _duration = _controller.value.duration;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _seekBackward() {
    final newPosition = _position - const Duration(seconds: 10);
    _controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  void _seekForward() {
    final newPosition = _position + const Duration(seconds: 10);
    _controller.seekTo(newPosition > _duration ? _duration : newPosition);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Video Player
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            
            // Controls Overlay
            if (_showControls && _isInitialized)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Column(
                  children: [
                    // Top Bar
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الفيديو',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white, size: 28.sp),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Center Play/Pause Button
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Rewind Button
                            IconButton(
                              icon: Icon(Icons.replay_10, color: Colors.white, size: 36.sp),
                              onPressed: _seekBackward,
                              tooltip: 'رجوع 10 ثوان',
                            ),
                            SizedBox(width: 24.w),
                            
                            // Play/Pause Button
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: Colors.white,
                                size: 64.sp,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                            SizedBox(width: 24.w),
                            
                            // Forward Button
                            IconButton(
                              icon: Icon(Icons.forward_10, color: Colors.white, size: 36.sp),
                              onPressed: _seekForward,
                              tooltip: 'تقديم 10 ثوان',
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bottom Controls
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          // Progress Bar
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: Colors.white,
                              bufferedColor: Colors.white.withValues(alpha: 0.3),
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          
                          // Time Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

