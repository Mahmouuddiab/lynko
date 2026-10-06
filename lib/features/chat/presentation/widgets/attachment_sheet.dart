import 'package:flutter/material.dart';

enum AttachmentAction { photo, camera, video, recordVideo, file, location }

Future<AttachmentAction?> showAttachmentSheet(BuildContext context) {
  const items = [
    (AttachmentAction.photo, Icons.photo_library, 'Photo'),
    (AttachmentAction.camera, Icons.camera_alt, 'Camera'),
    (AttachmentAction.video, Icons.video_library, 'Video'),
    (AttachmentAction.recordVideo, Icons.videocam, 'Record'),
    (AttachmentAction.file, Icons.insert_drive_file, 'File'),
    (AttachmentAction.location, Icons.location_on, 'Location'),
  ];

  return showModalBottomSheet<AttachmentAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            for (final (action, icon, label) in items)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(ctx, action),
                child: SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      CircleAvatar(radius: 28, child: Icon(icon)),
                      const SizedBox(height: 6),
                      Text(label, style: Theme.of(ctx).textTheme.labelMedium),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}