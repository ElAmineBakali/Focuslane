import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:focuslane/core/services/ai_backend_client.dart';

class FinanceReceiptAiItem {
  const FinanceReceiptAiItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  final String name;
  final double qty;
  final double price;
}

class FinanceReceiptAiResult {
  const FinanceReceiptAiResult({
    required this.merchant,
    required this.total,
    required this.currency,
    required this.dateISO,
    required this.items,
    required this.confidence,
    required this.model,
    required this.mimeType,
    required this.bytesLength,
    required this.inputHash,
  });

  final String? merchant;
  final double? total;
  final String? currency;
  final String? dateISO;
  final List<FinanceReceiptAiItem> items;
  final double confidence;
  final String model;
  final String mimeType;
  final int bytesLength;
  final String inputHash;

  DateTime? get parsedDate {
    final raw = dateISO;
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed;
  }

  static FinanceReceiptAiResult fromJson(
    Map<String, dynamic> json, {
    required String mimeType,
    required int bytesLength,
  }) {
    final merchant = _normalizeText(json['merchant']);
    final total = _asNullableDouble(json['total']);
    final currency = _normalizeCurrency(json['currency']);
    final dateISO = _normalizeDateISO(json['dateISO']);

    final itemsRaw = (json['items'] as List?) ?? const [];
    final items =
        itemsRaw
            .whereType<Map>()
            .map((raw) {
              final map = raw.cast<String, dynamic>();
              final name = _normalizeText(map['name']) ?? '';
              final qty = _asNullableDouble(map['qty']) ?? 1;
              final price = _asNullableDouble(map['price']) ?? 0;
              if (name.isEmpty) return null;
              return FinanceReceiptAiItem(
                name: name,
                qty: qty > 0 ? qty : 1,
                price: price >= 0 ? price : 0,
              );
            })
            .whereType<FinanceReceiptAiItem>()
            .toList();

    final confidence =
        ((_asNullableDouble(json['confidence']) ?? 0).clamp(
          0.0,
          1.0,
        )).toDouble();
    final model = _normalizeText(json['model']) ?? 'unknown';

    final stablePayload = {
      'type': 'receipt_scan',
      'merchant': merchant ?? '',
      'total': total?.toStringAsFixed(2) ?? '',
      'currency': currency ?? '',
      'dateISO': dateISO ?? '',
      'mimeType': mimeType,
      'bytesLength': bytesLength,
      'itemsCount': items.length,
    };

    return FinanceReceiptAiResult(
      merchant: merchant,
      total: total,
      currency: currency,
      dateISO: dateISO,
      items: items,
      confidence: confidence,
      model: model,
      mimeType: mimeType,
      bytesLength: bytesLength,
      inputHash: _fnv1aHashHex(jsonEncode(stablePayload)),
    );
  }

  static String? _normalizeText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      return double.tryParse(normalized);
    }
    return null;
  }

  static String? _normalizeCurrency(dynamic value) {
    final text = _normalizeText(value);
    if (text == null) return null;
    final upper = text.toUpperCase();
    return RegExp(r'^[A-Z]{3}$').hasMatch(upper) ? upper : null;
  }

  static String? _normalizeDateISO(dynamic value) {
    final text = _normalizeText(value);
    if (text == null) return null;

    final direct = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (direct != null) {
      return '${direct.group(1)}-${direct.group(2)}-${direct.group(3)}';
    }

    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return parsed.toIso8601String().substring(0, 10);
  }
}

class FinanceReceiptAiException implements Exception {
  const FinanceReceiptAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FinanceReceiptAiService {
  FinanceReceiptAiService({AiBackendClient? client})
    : _client = client ?? AiBackendClient();

  final AiBackendClient _client;

  static const int _targetBytes = 800 * 1024;
  static const int _maxBytes = 2 * 1024 * 1024;

  Future<FinanceReceiptAiResult> scanFromImage(XFile file) async {
    final originalBytes = await file.readAsBytes();
    final originalMime = _mimeFromFile(file.path, file.mimeType);

    if (originalBytes.length > _maxBytes) {
      if (kDebugMode) {
        debugPrint(
          '[FinanceReceiptAI] picked bytes=${originalBytes.length} resizedBytes=0 mimeOriginal=$originalMime mimeUpload=image/jpeg',
        );
      }
      throw const FinanceReceiptAiException(
        'La imagen supera el máximo permitido de 2MB.',
      );
    }

    final compressed = _compressForAi(originalBytes);

    if (kDebugMode) {
      debugPrint(
        '[FinanceReceiptAI] picked bytes=${originalBytes.length} resizedBytes=${compressed.length} mimeOriginal=$originalMime mimeUpload=image/jpeg',
      );
    }

    if (compressed.length > _maxBytes) {
      throw const FinanceReceiptAiException(
        'La imagen supera el máximo permitido de 2MB.',
      );
    }

    final response = await _client.receiptScan(
      imageBase64: base64Encode(compressed),
      mimeType: 'image/jpeg',
    );

    if (kDebugMode) {
      debugPrint('[FinanceReceiptAI] status=200 payload=$response');
    }

    final result = FinanceReceiptAiResult.fromJson(
      response,
      mimeType: originalMime,
      bytesLength: compressed.length,
    );

    final hasRequiredData =
        (result.total != null && result.total! >= 0) ||
        (result.merchant != null && result.merchant!.isNotEmpty);

    if (!hasRequiredData) {
      throw const FinanceReceiptAiException(
        'La respuesta de IA no contiene datos válidos del ticket.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[FinanceReceiptAI] api ok model=${result.model} conf=${result.confidence.toStringAsFixed(2)} merchant=${result.merchant ?? 'null'} total=${result.total?.toStringAsFixed(2) ?? 'null'} currency=${result.currency ?? 'null'} dateISO=${result.dateISO ?? 'null'} items=${result.items.length}',
      );
    }

    return result;
  }

  Uint8List _compressForAi(Uint8List input) {
    final decoded = img.decodeImage(input);
    if (decoded == null) {
      if (input.length <= _maxBytes) return input;
      throw const FinanceReceiptAiException(
        'La imagen supera el máximo permitido de 2MB.',
      );
    }

    img.Image working = img.bakeOrientation(decoded);
    if (working.width > 1024) {
      working = img.copyResize(working, width: 1024);
    }

    var quality = 80;
    Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(working, quality: quality),
    );

    while (encoded.length > _targetBytes && quality > 45) {
      quality -= 5;
      encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }

    while (encoded.length > _maxBytes && working.width > 420) {
      final resizedWidth = (working.width * 0.85).round();
      working = img.copyResize(working, width: resizedWidth);
      encoded = Uint8List.fromList(img.encodeJpg(working, quality: 70));
      while (encoded.length > _targetBytes && quality > 45) {
        quality -= 5;
        encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
      }
    }

    return encoded;
  }

  String _mimeFromFile(String path, String? provided) {
    final mime = (provided ?? '').toLowerCase().trim();
    if (mime == 'image/jpeg' || mime == 'image/png' || mime == 'image/webp') {
      return mime;
    }
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

String _fnv1aHashHex(String input) {
  const fnvPrime = 16777619;
  var hash = 2166136261;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
