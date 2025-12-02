import 'package:cloud_firestore/cloud_firestore.dart';

class NoteAttachment {
  final String url;
  final String? name;
  final int? size;
  const NoteAttachment({required this.url, this.name, this.size});
  Map<String, dynamic> toMap() => {'url': url, 'name': name, 'size': size};
  factory NoteAttachment.fromMap(Map<String, dynamic> m) => NoteAttachment(
    url: (m['url'] ?? '') as String,
    name: m['name'] as String?,
    size: (m['size'] as num?)?.toInt(),
  );
}

/// Modelo de nota con contenido rico (texto Quill, imágenes, portada)
class Note {
  final String id;
  final String title;
  // Compatibilidad: si existe `delta` se usa editor rico; si no, `content` plano.
  final String content; // texto plano heredado
  final List<FormatSpan> spans; // legado para marcas simples
  final List<dynamic>? delta; // Quill Delta (lista de ops)
  final List<String> tags;
  final bool isPinned;
  final String? colorHex;
  final String? coverUrl; // portada (imagen/dibujo)
  final String? style; // estilo visual de tarjeta
  final List<NoteAttachment> attachments; // imágenes/archivos
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? date;
  final List<String> linkedTaskIds;
  final int order;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.spans = const [],
    this.delta,
    this.tags = const [],
    this.isPinned = false,
    this.colorHex,
    this.coverUrl,
    this.style,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.date,
    this.linkedTaskIds = const [],
    this.order = 0,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<FormatSpan>? spans,
    List<dynamic>? delta,
    List<String>? tags,
    bool? isPinned,
    String? colorHex,
    String? coverUrl,
    String? style,
    List<NoteAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? date,
    List<String>? linkedTaskIds,
    int? order,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    spans: spans ?? this.spans,
    delta: delta ?? this.delta,
    tags: tags ?? this.tags,
    isPinned: isPinned ?? this.isPinned,
    colorHex: colorHex ?? this.colorHex,
    coverUrl: coverUrl ?? this.coverUrl,
    style: style ?? this.style,
    attachments: attachments ?? this.attachments,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    date: date ?? this.date,
    linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
    order: order ?? this.order,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'content': content,
    'spans': spans.map((s) => s.toMap()).toList(),
    'delta': delta,
    'tags': tags,
    'isPinned': isPinned,
    'colorHex': colorHex,
    'coverUrl': coverUrl,
    'style': style,
    'attachments': attachments.map((a) => a.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'date': date != null ? Timestamp.fromDate(date!) : null,
    'linkedTaskIds': linkedTaskIds,
    'order': order,
  };

  factory Note.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});

    DateTime tsToDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final spansRaw = data['spans'];
    final spans =
        (spansRaw is List)
            ? spansRaw
                .map((e) => FormatSpan.fromMap(Map<String, dynamic>.from(e)))
                .toList()
            : <FormatSpan>[];
    final delta =
        (data['delta'] is List) ? List<dynamic>.from(data['delta']) : null;
    final attachmentsRaw = data['attachments'];
    final attachments =
        (attachmentsRaw is List)
            ? attachmentsRaw
                .map(
                  (e) => NoteAttachment.fromMap(Map<String, dynamic>.from(e)),
                )
                .toList()
            : <NoteAttachment>[];

    return Note(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      content: (data['content'] ?? '') as String,
      delta: delta,
      spans: spans,
      tags:
          (data['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      isPinned: (data['isPinned'] ?? false) as bool,
      colorHex: data['colorHex'] as String?,
      coverUrl: data['coverUrl'] as String?,
      style: data['style'] as String?,
      attachments: attachments,
      createdAt: tsToDate(data['createdAt']),
      updatedAt: tsToDate(data['updatedAt']),
      date: data['date'] != null ? tsToDate(data['date']) : null,
      linkedTaskIds:
          (data['linkedTaskIds'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Segmento de texto con formato
class FormatSpan {
  final int start; // offset en content
  final int length;
  final bool bold;
  final bool italic;
  final bool underline;

  const FormatSpan({
    required this.start,
    required this.length,
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });

  Map<String, dynamic> toMap() => {
    'start': start,
    'length': length,
    'bold': bold,
    'italic': italic,
    'underline': underline,
  };

  factory FormatSpan.fromMap(Map<String, dynamic> m) => FormatSpan(
    start: (m['start'] as num?)?.toInt() ?? 0,
    length: (m['length'] as num?)?.toInt() ?? 0,
    bold: (m['bold'] ?? false) as bool,
    italic: (m['italic'] ?? false) as bool,
    underline: (m['underline'] ?? false) as bool,
  );

  FormatSpan copyWith({
    int? start,
    int? length,
    bool? bold,
    bool? italic,
    bool? underline,
  }) => FormatSpan(
    start: start ?? this.start,
    length: length ?? this.length,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
  );
}
