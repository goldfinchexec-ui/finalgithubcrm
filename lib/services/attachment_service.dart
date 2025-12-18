import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PickedAttachment {
  final String name;
  final String mimeType;
  final Uint8List bytes;

  const PickedAttachment({required this.name, required this.mimeType, required this.bytes});

  String toDataUrl() => 'data:$mimeType;base64,${base64Encode(bytes)}';

  bool get isImage => mimeType.startsWith('image/');
}

class AttachmentService {
  const AttachmentService();

  Future<PickedAttachment?> pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: false, type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp']);
      final file = result?.files.first;
      if (file == null) return null;
      final bytes = file.bytes;
      if (bytes == null) return null;

      final ext = (file.extension ?? '').toLowerCase();
      final mime = switch (ext) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };
      return PickedAttachment(name: file.name, mimeType: mime, bytes: bytes);
    } catch (e) {
      debugPrint('AttachmentService.pick error: $e');
      return null;
    }
  }

  Future<void> openInBrowser(String dataUrl) async {
    try {
      final uri = Uri.parse(dataUrl);
      // On web inside Dreamflow's sandboxed preview, top-level navigations can be blocked.
      // Force opening in a new tab using _blank to avoid being blocked by Chrome.
      bool ok = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!ok) {
        // Fallback: try string-based API
        ok = await launchUrlString(
          uri.toString(),
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      }
      if (!ok) debugPrint('AttachmentService.openInBrowser: launchUrl returned false');
    } catch (e) {
      debugPrint('AttachmentService.openInBrowser error: $e');
    }
  }

  /// Opens a URL and hints the browser to download the file instead of previewing.
  ///
  /// For Firebase Storage signed URLs, we can add a response-content-disposition
  /// query param to force download with a filename. If the URL isn't from
  /// Firebase Storage, we still try adding the parameter generically.
  Future<void> openForDownload(String url, {String? filename}) async {
    try {
      final uri = Uri.parse(url);
      final fname = filename ?? (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file');
      // Preserve existing query params and add content disposition to force download
      final newQuery = Map<String, String>.from(uri.queryParameters)
        ..putIfAbsent('response-content-disposition', () => 'attachment; filename="$fname"');
      final dlUri = uri.replace(queryParameters: newQuery);
      debugPrint('[attachment] openForDownload -> $dlUri');
      bool ok = await launchUrl(
        dlUri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!ok) {
        ok = await launchUrlString(
          dlUri.toString(),
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      }
      if (!ok) debugPrint('AttachmentService.openForDownload: launchUrl returned false');
    } catch (e, st) {
      debugPrint('AttachmentService.openForDownload error: $e');
      debugPrint(st.toString());
    }
  }

  /// Uploads a picked attachment to Firebase Storage and returns a public download URL.
  ///
  /// Path format: attachments/{uid or anon}/{timestamp}_{sanitized_filename}
  Future<String?> uploadAndGetUrl(PickedAttachment file) async {
    try {
      debugPrint('[attachment] Start upload: name=${file.name}, mime=${file.mimeType}, bytes=${file.bytes.length}');
      final storage = FirebaseStorage.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = _sanitizeFilename(file.name);
      final path = 'attachments/$uid/${ts}_$sanitizedName';

      final ref = storage.ref().child(path);
      final metadata = SettableMetadata(contentType: file.mimeType);
      final task = await ref.putData(file.bytes, metadata);
      debugPrint('[attachment] Upload task state: ${task.state} (${task.bytesTransferred}/${task.totalBytes})');
      if (task.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        debugPrint('[attachment] Download URL: $url');
        return url;
      }
      debugPrint('AttachmentService.uploadAndGetUrl: task state ${task.state}');
      return null;
    } catch (e, st) {
      debugPrint('AttachmentService.uploadAndGetUrl error: $e');
      debugPrint(st.toString());
      return null;
    }
  }

  String _sanitizeFilename(String name) {
    // Remove path separators and trim; replace spaces with underscores
    final withoutDirs = name.split('/').last.split('\\').last;
    return withoutDirs.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
