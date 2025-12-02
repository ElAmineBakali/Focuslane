// lib/screens/meditation/models/meditation_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

String yyyymm(DateTime d) => "${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}";

/// ====== Sessions ======
enum SessionType { guided, timer, breath }

class MeditationSession {
  final String id;
  final String title;
  final SessionType type;
  final int durationSec;
  final DateTime date;
  final String? notes;
  final List<String> tags;
  final int? moodBefore; // 1..5
  final int? moodAfter;  // 1..5
  final String? location;
  final bool streakKept;

  MeditationSession({
    required this.id,
    required this.title,
    required this.type,
    required this.durationSec,
    required this.date,
    this.notes,
    this.tags = const [],
    this.moodBefore,
    this.moodAfter,
    this.location,
    this.streakKept = false,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type.name,
    'durationSec': durationSec,
    'date': Timestamp.fromDate(date),
    'notes': notes,
    'tags': tags,
    'moodBefore': moodBefore,
    'moodAfter': moodAfter,
    'location': location,
    'streakKept': streakKept,
  };

  static MeditationSession fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return MeditationSession(
      id: s.id,
      title: (d['title'] ?? '') as String,
      type: SessionType.values.firstWhere((e) => e.name == (d['type'] ?? 'timer')),
      durationSec: (d['durationSec'] ?? 0) as int,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: d['notes'],
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      moodBefore: (d['moodBefore'] as num?)?.toInt(),
      moodAfter: (d['moodAfter'] as num?)?.toInt(),
      location: d['location'],
      streakKept: d['streakKept'] == true,
    );
  }
}

/// ====== Programs ======
class MeditationProgram {
  final String id;
  final String name;
  final String description;
  final String level; // beginner|intermediate|advanced
  final String? emoji;
  final String? coverColor;
  final bool isActive;

  MeditationProgram({
    required this.id,
    required this.name,
    required this.description,
    this.level = 'beginner',
    this.emoji,
    this.coverColor,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'level': level,
    'emoji': emoji,
    'coverColor': coverColor,
    'isActive': isActive,
  };

  static MeditationProgram fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return MeditationProgram(
      id: s.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      level: d['level'] ?? 'beginner',
      emoji: d['emoji'],
      coverColor: d['coverColor'],
      isActive: d['isActive'] ?? true,
    );
  }
}

class ProgramDay {
  final String id;
  final int dayNumber;
  final String title;
  final String goal;
  final int recommendedDurationSec;
  final String status; // pending|done|skipped
  final String? guidedAudioId; // 👈 NUEVO (audio guiado opcional para este día)


  ProgramDay({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.goal,
    required this.recommendedDurationSec,
    this.status = 'pending',
    this.guidedAudioId, // 👈 nuevo
  });

  Map<String, dynamic> toMap() => {
    'dayNumber': dayNumber,
    'title': title,
    'goal': goal,
    'recommendedDurationSec': recommendedDurationSec,
    'status': status,
    'guidedAudioId': guidedAudioId, // 👈 nuevo
  };

  static ProgramDay fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return ProgramDay(
      id: s.id,
      dayNumber: (d['dayNumber'] ?? 1) as int,
      title: d['title'] ?? '',
      goal: d['goal'] ?? '',
      recommendedDurationSec: (d['recommendedDurationSec'] ?? 600) as int,
      status: d['status'] ?? 'pending',
      guidedAudioId: d['guidedAudioId'] as String?, // 👈 nuevo
    );
  }
}

/// ====== Breath presets ======
class BreathPreset {
  final String id;
  final String name;
  final int inhale;
  final int hold;
  final int exhale;
  final int hold2;
  final int cycles;
  final bool vibration;
  final String visualStyle; // dot|wave|circle

  BreathPreset({
    required this.id,
    required this.name,
    this.inhale = 4,
    this.hold = 4,
    this.exhale = 4,
    this.hold2 = 0,
    this.cycles = 6,
    this.vibration = true,
    this.visualStyle = 'circle',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'inhale': inhale,
    'hold': hold,
    'exhale': exhale,
    'hold2': hold2,
    'cycles': cycles,
    'vibration': vibration,
    'visualStyle': visualStyle,
  };

  static BreathPreset fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return BreathPreset(
      id: s.id,
      name: d['name'] ?? '',
      inhale: (d['inhale'] ?? 4) as int,
      hold: (d['hold'] ?? 4) as int,
      exhale: (d['exhale'] ?? 4) as int,
      hold2: (d['hold2'] ?? 0) as int,
      cycles: (d['cycles'] ?? 6) as int,
      vibration: d['vibration'] ?? true,
      visualStyle: d['visualStyle'] ?? 'circle',
    );
  }
}

/// ====== Reminders ======
class MeditationReminder {
  final String id;
  final String timeOfDay; // "08:30"
  final List<int> daysOfWeek; // 1..7
  final bool enabled;

  MeditationReminder({
    required this.id,
    required this.timeOfDay,
    this.daysOfWeek = const [1,2,3,4,5,6,7],
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
    'timeOfDay': timeOfDay,
    'daysOfWeek': daysOfWeek,
    'enabled': enabled,
  };

  static MeditationReminder fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return MeditationReminder(
      id: s.id,
      timeOfDay: d['timeOfDay'] ?? '08:30',
      daysOfWeek: (d['daysOfWeek'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [1,2,3,4,5,6,7],
      enabled: d['enabled'] ?? true,
    );
  }
}

/// ====== Tags ======
class SimpleTag {
  final String id;
  final String name;
  final String? color;

  SimpleTag({ required this.id, required this.name, this.color });

  Map<String, dynamic> toMap() => { 'name': name, 'color': color };

  static SimpleTag fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return SimpleTag(
      id: s.id,
      name: d['name'] ?? '',
      color: d['color'],
    );
  }
}

/// ====== Guided Audio (biblioteca) ======
class GuidedAudio {
  final String id;
  final String title;
  final int durationSec;
  final String url; // puede ser asset o URL
  final List<String> tags;
  final String? description;

  GuidedAudio({
    required this.id,
    required this.title,
    required this.durationSec,
    required this.url,
    this.tags = const [],
    this.description,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'durationSec': durationSec,
    'url': url,
    'tags': tags,
    'description': description,
  };

  static GuidedAudio fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return GuidedAudio(
      id: s.id,
      title: d['title'] ?? '',
      durationSec: (d['durationSec'] ?? 600) as int,
      url: d['url'] ?? '',
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      description: d['description'],
    );
  }
}
