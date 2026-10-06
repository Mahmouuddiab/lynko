import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lynko/features/chat/domain/entity/message_type.dart';
import 'package:video_player/video_player.dart';

class AttachmentException implements Exception {
  final String message;
  AttachmentException(this.message);
  @override
  String toString() => message;
}

class PickedAttachment {
  final String path;
  final String name;
  final int sizeBytes;
  final MessageType type;
  final int? durationSeconds;

  const PickedAttachment({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.type,
    this.durationSeconds,
  });
}

class PickedLocation {
  final double latitude;
  final double longitude;
  const PickedLocation(this.latitude, this.longitude);
}

/// Device-only work: pick a file or read the GPS. Nothing here talks to the server.
class AttachmentPicker {
  static const _maxImageBytes = 10 * 1000 * 1000;
  static const _maxVideoBytes = 100 * 1000 * 1000;
  static const _maxFileBytes = 50 * 1000 * 1000;
  static const fileExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'zip',
  ];

  final _picker = ImagePicker();

  /// Every method returns null when the user cancels the picker.

  Future<PickedAttachment?> image(ImageSource source) async {
    // imageQuality/maxWidth also make iOS convert HEIC to JPEG, which the server accepts.
    final x = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (x == null) return null;

    final size = await File(x.path).length();
    if (size > _maxImageBytes) {
      throw AttachmentException('Image is larger than 10 MB.');
    }
    return PickedAttachment(
      path: x.path,
      name: _withExtension(x.name, x.path),
      sizeBytes: size,
      type: MessageType.image,
    );
  }

  Future<PickedAttachment?> video(ImageSource source) async {
    final x = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 3),
    );
    if (x == null) return null;

    final size = await File(x.path).length();
    if (size > _maxVideoBytes) {
      throw AttachmentException('Video is larger than 100 MB.');
    }
    return PickedAttachment(
      path: x.path,
      name: _withExtension(x.name, x.path),
      sizeBytes: size,
      type: MessageType.video,
      durationSeconds: await _videoSeconds(x.path),
    );
  }

  Future<PickedAttachment?> file() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: fileExtensions,
    );

    if (result.isEmpty) return null;

    final f = result.single;

    if (f.path == null) return null;

    final file = File(f.path!);
    final size = await file.length();

    if (size > _maxFileBytes) {
      throw AttachmentException('File is larger than 50 MB.');
    }

    return PickedAttachment(
      path: f.path!,
      name: f.name,
      sizeBytes: size,
      type: MessageType.file,
    );
  }

  Future<PickedLocation> location() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw AttachmentException('Please turn on location services.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw AttachmentException('Location permission is denied.');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return PickedLocation(pos.latitude, pos.longitude);
    } catch (_) {
      throw AttachmentException('Could not get your location. Try again.');
    }
  }

  String _withExtension(String name, String path) {
    if (name.contains('.')) return name;
    final dot = path.lastIndexOf('.');
    return dot == -1 ? name : '$name${path.substring(dot)}';
  }

  Future<int?> _videoSeconds(String path) async {
    final c = VideoPlayerController.file(File(path));
    try {
      await c.initialize();
      return c.value.duration.inSeconds;
    } catch (_) {
      return null;
    } finally {
      await c.dispose();
    }
  }
}