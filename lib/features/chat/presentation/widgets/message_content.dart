import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lynko/features/chat/domain/entity/message_type.dart';
import 'package:lynko/features/chat/presentation/providers/conversation_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class MessageContent extends StatelessWidget {
  final ChatMessage message;
  final Color color;

  const MessageContent({super.key, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final m = message;
    switch (m.type) {
      case MessageType.text:
        return Text(m.text, style: TextStyle(color: color, fontSize: 15.5, height: 1.3));
      case MessageType.image:
        return _image(context);
      case MessageType.video:
        return _video(context);
      case MessageType.location:
        return _location();
      case MessageType.file:
        return _file();
      case MessageType.voice:
        return Text('🎤 Voice message', style: TextStyle(color: color));
    }
  }

  /// Local file while uploading, network image once the server has it.
  ImageProvider? _imageProvider() {
    final local = message.localPath;
    if (local != null && File(local).existsSync()) return FileImage(File(local));
    final url = message.mediaUrl;
    return url == null ? null : NetworkImage(url);
  }

  Widget _image(BuildContext context) {
    final provider = _imageProvider();
    if (provider == null) {
      return Icon(Icons.broken_image, color: color, size: 48);
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _FullImagePage(image: provider)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: provider,
          width: 220,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : const SizedBox(
            width: 220,
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorBuilder: (_, __, ___) => SizedBox(
            width: 220,
            height: 120,
            child: Icon(Icons.broken_image, color: color),
          ),
        ),
      ),
    );
  }

  Widget _video(BuildContext context) {
    final url = message.mediaUrl;
    return GestureDetector(
      onTap: url == null
          ? null
          : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPlayerPage(url: url)),
      ),
      child: Container(
        width: 220,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.play_circle_fill, size: 52, color: Colors.white),
            if (message.durationSeconds != null)
              Positioned(
                right: 8,
                bottom: 6,
                child: Text(
                  _fmtDuration(message.durationSeconds!),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _location() {
    final lat = message.latitude;
    final lng = message.longitude;
    return InkWell(
      onTap: (lat == null || lng == null)
          ? null
          : () => launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Colors.redAccent, size: 34),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              if (lat != null && lng != null)
                Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
              Text('Tap to open in Maps',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _file() {
    final url = message.mediaUrl;
    return InkWell(
      onTap: url == null
          ? null
          : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: color, size: 34),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'File',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                if (message.fileSizeBytes != null)
                  Text(_fmtBytes(message.fileSizeBytes!),
                      style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  static String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _FullImagePage extends StatelessWidget {
  final ImageProvider image;
  const _FullImagePage({required this.image});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
    body: Center(child: InteractiveViewer(child: Image(image: image))),
  );
}

class VideoPlayerPage extends StatefulWidget {
  final String url;
  const VideoPlayerPage({super.key, required this.url});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _c.play();
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
    body: Center(
      child: _c.value.isInitialized
          ? GestureDetector(
        onTap: () =>
            setState(() => _c.value.isPlaying ? _c.pause() : _c.play()),
        child: AspectRatio(
          aspectRatio: _c.value.aspectRatio,
          child: VideoPlayer(_c),
        ),
      )
          : const CircularProgressIndicator(),
    ),
  );
}