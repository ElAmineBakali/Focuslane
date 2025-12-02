import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:mi_dashboard_personal/blocks/toast/app_toast.dart';

/// Servicio de almacenamiento usando Supabase Storage (gratuito)
/// Reemplaza Firebase Storage manteniendo la misma API
class SupabaseMediaService {
  static final _storage = Supabase.instance.client.storage;
  static const String _bucketName = 'notes-media';

  static Future<String> uploadFile(File file, {String folder = 'notes'}) async {
    final id = const Uuid().v4();
    final ext = p.extension(file.path).toLowerCase();
    final path = '$folder/$id$ext';
    
    try {
      final bytes = await file.readAsBytes();
      await _storage.from(_bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );
      final url = _storage.from(_bucketName).getPublicUrl(path);
      return url;
    } catch (e) {
      rethrow;
    }
  }

  /// Pick de archivo e inmediatamente subirlo a Supabase
  Future<String?> pickAndUpload(context, {String pathPrefix = 'notes'}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return null;
      }
      final f = result.files.first;
      
      if (f.bytes != null) {
        try {
          final url = await uploadBytes(f.bytes!, fileName: f.name, pathPrefix: pathPrefix);
          return url;
        } catch (e) {
          AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
          return null;
        }
      }
      if (f.path != null) {
        final url = await uploadFile(File(f.path!), folder: pathPrefix);
        return url;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Sube bytes directamente a Supabase
  Future<String> uploadBytes(Uint8List data, {required String fileName, String pathPrefix = 'notes'}) async {
    try {
      final maxImageBytes = 500 * 1024;
      final isImage = ['.png', '.jpg', '.jpeg', '.gif', '.webp']
          .contains(p.extension(fileName.toLowerCase()));
      if (isImage && data.length > maxImageBytes) {
        final decoded = img.decodeImage(data);
        if (decoded != null) {
          int quality = 85;
          Uint8List? compressed;
          while (quality >= 40) {
            final out = img.encodeJpg(decoded, quality: quality);
            compressed = Uint8List.fromList(out);
            if (compressed.length <= maxImageBytes) break;
            quality -= 10;
          }
          if (compressed != null && compressed.length <= maxImageBytes) {
            data = compressed;
            if (!p.extension(fileName.toLowerCase()).contains('jpg')) {
              fileName = p.setExtension(fileName, '.jpg');
            }
          } else {
            throw Exception('La imagen supera el límite de 500KB incluso tras comprimir');
          }
        } else {
          throw Exception('Formato de imagen no soportado para comprimir (>500KB)');
        }
      }

      final id = const Uuid().v4();
      final ext = p.extension(fileName.isNotEmpty ? fileName : 'file').toLowerCase();
      final path = '$pathPrefix/$id$ext';
      
      await _storage.from(_bucketName).uploadBinary(
        path,
        data,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );
      
      final url = _storage.from(_bucketName).getPublicUrl(path);
      return url;
    } catch (e) {
      rethrow;
    }
  }
}
