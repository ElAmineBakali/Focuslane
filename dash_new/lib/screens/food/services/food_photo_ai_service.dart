import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/services/ai_backend_client.dart';

class CaloriesAiMacros {
  final double protein;
  final double carbs;
  final double fat;

  const CaloriesAiMacros({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  CaloriesAiMacros scaled(double factor) {
    return CaloriesAiMacros(
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
    );
  }
}

class CaloriesAiItem {
  final String name;
  final String portion;
  final double calories;

  const CaloriesAiItem({
    required this.name,
    required this.portion,
    required this.calories,
  });

  CaloriesAiItem scaled(double factor) {
    return CaloriesAiItem(
      name: name,
      portion: portion,
      calories: calories * factor,
    );
  }

  factory CaloriesAiItem.fromJson(Map<String, dynamic> json) {
    return CaloriesAiItem(
      name: (json['name'] ?? '').toString(),
      portion: (json['portion'] ?? '').toString(),
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CaloriesAiResult {
  final double calories;
  final CaloriesAiMacros macros;
  final List<CaloriesAiItem> items;
  final double confidence;
  final String model;
  final String mimeType;
  final int bytesLength;
  final String? inputHash;

  const CaloriesAiResult({
    required this.calories,
    required this.macros,
    required this.items,
    required this.confidence,
    required this.model,
    required this.mimeType,
    required this.bytesLength,
    this.inputHash,
  });

  CaloriesAiResult scaled(double factor) {
    return CaloriesAiResult(
      calories: calories * factor,
      macros: macros.scaled(factor),
      items: items.map((item) => item.scaled(factor)).toList(),
      confidence: confidence,
      model: model,
      mimeType: mimeType,
      bytesLength: bytesLength,
      inputHash: inputHash,
    );
  }

  factory CaloriesAiResult.fromJson(
    Map<String, dynamic> json, {
    required String mimeType,
    required int bytesLength,
  }) {
    final macrosJson =
        (json['macros'] as Map?)?.cast<String, dynamic>() ?? const {};
    final itemsRaw = (json['items'] as List?) ?? const [];
    return CaloriesAiResult(
      calories: (json['estimatedCalories'] as num?)?.toDouble() ?? 0,
      macros: CaloriesAiMacros(
        protein: (macrosJson['protein'] as num?)?.toDouble() ?? 0,
        carbs: (macrosJson['carbs'] as num?)?.toDouble() ?? 0,
        fat: (macrosJson['fat'] as num?)?.toDouble() ?? 0,
      ),
      items: itemsRaw
          .whereType<Map>()
          .map((e) => CaloriesAiItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0),
      model: (json['model'] ?? '').toString().isEmpty
          ? 'unknown'
          : (json['model'] as String),
      mimeType: mimeType,
      bytesLength: bytesLength,
      inputHash: (json['inputHash'] as String?),
    );
  }
}

class FoodPhotoAiException implements Exception {
  final String message;

  const FoodPhotoAiException(this.message);

  @override
  String toString() => message;
}

class FoodPhotoAiService {
  FoodPhotoAiService({AiBackendClient? client})
      : _client = client ?? AiBackendClient();

  final AiBackendClient _client;
  static const int _targetBytes = 800 * 1024;
  static const int _maxBytes = 2 * 1024 * 1024;

  Future<CaloriesAiResult> estimateFromImage(XFile file) async {
    final originalBytes = await file.readAsBytes();
    final originalMime = _mimeFromFile(file.path, file.mimeType);

    if (originalBytes.length > _maxBytes) {
      if (kDebugMode) {
        debugPrint(
          '[FoodPhotoAI] picked bytes=${originalBytes.length} resizedBytes=0 mimeOriginal=$originalMime mimeUpload=image/jpeg',
        );
      }
      throw const FoodPhotoAiException(
        'La imagen supera el máximo permitido de 2MB.',
      );
    }

    final compressed = await compute(
      _compressForAiIsolate,
      <String, dynamic>{
        'bytes': originalBytes,
        'targetBytes': _targetBytes,
        'maxBytes': _maxBytes,
      },
    );

    if (kDebugMode) {
      debugPrint(
        '[FoodPhotoAI] picked bytes=${originalBytes.length} resizedBytes=${compressed.length} mimeOriginal=$originalMime mimeUpload=image/jpeg',
      );
    }

    if (compressed.length > _maxBytes) {
      if (kDebugMode) {
        debugPrint(
          '[FoodPhotoAI] abort oversized resizedBytes=${compressed.length} maxBytes=$_maxBytes',
        );
      }
      throw const FoodPhotoAiException(
        'La imagen supera el máximo permitido de 2MB.',
      );
    }

    final response = await _client.caloriesFromPhoto(
      imageBase64: base64Encode(compressed),
      mimeType: 'image/jpeg',
    );

    final result = CaloriesAiResult.fromJson(
      response,
      mimeType: originalMime,
      bytesLength: compressed.length,
    );

    if (kDebugMode) {
      debugPrint(
        '[FoodPhotoAI] api ok model=${result.model} conf=${result.confidence.toStringAsFixed(2)}',
      );
    }

    return result;
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

Uint8List _compressForAiIsolate(Map<String, dynamic> payload) {
  final bytes = payload['bytes'] as Uint8List;
  final targetBytes = payload['targetBytes'] as int;
  final maxBytes = payload['maxBytes'] as int;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    if (bytes.length <= maxBytes) return bytes;
    throw const FoodPhotoAiException(
      'La imagen supera el máximo permitido de 2MB.',
    );
  }

  img.Image working = img.bakeOrientation(decoded);
  if (working.width > 896) {
    working = img.copyResize(working, width: 896);
  }

  var quality = working.width >= 896 ? 74 : 78;
  Uint8List encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));

  while (encoded.length > targetBytes && quality > 58) {
    quality -= 4;
    encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
  }

  while (encoded.length > maxBytes && working.width > 420) {
    final resizedWidth = (working.width * 0.82).round();
    working = img.copyResize(working, width: resizedWidth);
    quality = 68;
    encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
  }

  return encoded;
}
