import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Legacy MediaService - migrated to Supabase
/// Use SupabaseMediaService instead for new code
class MediaService {
  static final _storage = Supabase.instance.client.storage;
  static const String _bucketName = 'notes-media';

  static Future<String> uploadFile(File file, {String folder = 'notes'}) async {
    final id = const Uuid().v4();
    final ext = p.extension(file.path).toLowerCase();
    final path = '$folder/$id$ext';
    final bytes = await file.readAsBytes();
    await _storage.from(_bucketName).uploadBinary(path, bytes);
    return _storage.from(_bucketName).getPublicUrl(path);
  }

  Future<String?> pickAndUpload(context, {String pathPrefix = 'notes'}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        // ignore: avoid_print
        print('[MediaService] Usuario canceló la selección');
        return null;
      }
      final f = result.files.first;
      // ignore: avoid_print
      print('[MediaService] Archivo seleccionado: ${f.name} (${f.size} bytes)');

      if (f.bytes != null) {
        // ignore: avoid_print
        print('[MediaService] Subiendo desde bytes...');
        final url = await uploadBytes(
          f.bytes!,
          fileName: f.name,
          pathPrefix: pathPrefix,
        );
        // ignore: avoid_print
        print('[MediaService] URL generada: $url');
        return url;
      }
      if (f.path != null) {
        // ignore: avoid_print
        print('[MediaService] Subiendo desde path...');
        final url = await uploadFile(File(f.path!), folder: pathPrefix);
        // ignore: avoid_print
        print('[MediaService] URL generada: $url');
        return url;
      }
      // ignore: avoid_print
      print('[MediaService] Error: archivo sin bytes ni path');
      return null;
    } catch (e, stack) {
      // ignore: avoid_print
      print('[MediaService] Error en pickAndUpload: $e');
      // ignore: avoid_print
      print(stack);
      rethrow;
    }
  }

  Future<String> uploadBytes(
    Uint8List data, {
    required String fileName,
    String pathPrefix = 'notes',
  }) async {
    try {
      final id = const Uuid().v4();
      final ext =
          p.extension(fileName.isNotEmpty ? fileName : 'file').toLowerCase();
      final path = '$pathPrefix/$id$ext';
      // ignore: avoid_print
      print('[MediaService] Iniciando upload a: $path');
      await _storage.from(_bucketName).uploadBinary(path, data);
      final url = _storage.from(_bucketName).getPublicUrl(path);
      // ignore: avoid_print
      print('[MediaService] Upload completado: $url');
      return url;
    } catch (e, stack) {
      // ignore: avoid_print
      print('[MediaService] Error en uploadBytes: $e');
      // ignore: avoid_print
      print(stack);
      rethrow;
    }
  }
}
