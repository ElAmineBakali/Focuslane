// lib/screens/gym/models/exercise_library_data.dart

class ExerciseLibraryItem {
  final String id;
  final String name;
  final String
  category; // "Máquina", "Barra", "Mancuernas", "Peso libre", "Polea", "Calistenia", etc.
  final String
  muscleGroup; // "Pecho", "Espalda", "Hombros", "Bíceps", "Tríceps", "Piernas", "Glúteos", "Core"

  const ExerciseLibraryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
  });
}

/// ✓ Lista base ampliada (70+ ejercicios habituales)
const List<ExerciseLibraryItem> kExerciseLibrary = [
  // Pecho
  ExerciseLibraryItem(
    id: 'bench_bar',
    name: 'Press banca (barra)',
    category: 'Barra',
    muscleGroup: 'Pecho',
  ),
  ExerciseLibraryItem(
    id: 'bench_db',
    name: 'Press banca (mancuernas)',
    category: 'Mancuernas',
    muscleGroup: 'Pecho',
  ),
  ExerciseLibraryItem(
    id: 'incline_bar',
    name: 'Press inclinado (barra)',
    category: 'Barra',
    muscleGroup: 'Pecho',
  ),
  ExerciseLibraryItem(
    id: 'incline_db',
    name: 'Press inclinado (mancuernas)',
    category: 'Mancuernas',
    muscleGroup: 'Pecho',
  ),
  ExerciseLibraryItem(
    id: 'decline_bar',
    name: 'Press declinado (barra)',
    category: 'Barra',
    muscleGroup: 'Pecho',
  ),
  ExerciseLibraryItem(
    id: 'machine_chest',
    name: 'Press pecho (máquina)',
    category: 'Máquina',
    muscleGroup: 'Pecho',
  ),
  ExerciseLibraryItem(
    id: 'fly_db',
    name: 'Aperturas (mancuernas)',
    category: 'Mancuernas',
    muscleGroup: 'Pecho',
  ),
  ExerciseLibraryItem(
    id: 'fly_cable',
    name: 'Aperturas en polea',
    category: 'Polea',
    muscleGroup: 'Pecho',
  ),
  ExerciseLibraryItem(
    id: 'pushups',
    name: 'Flexiones',
    category: 'Calistenia',
    muscleGroup: 'Pecho',
  ),

  // Espalda
  ExerciseLibraryItem(
    id: 'deadlift',
    name: 'Peso muerto',
    category: 'Barra',
    muscleGroup: 'Espalda',
  ),
  ExerciseLibraryItem(
    id: 'rack_pull',
    name: 'Rack pull',
    category: 'Barra',
    muscleGroup: 'Espalda',
  ),
  ExerciseLibraryItem(
    id: 'row_bar',
    name: 'Remo con barra',
    category: 'Barra',
    muscleGroup: 'Espalda',
  ),
  ExerciseLibraryItem(
    id: 'row_db',
    name: 'Remo con mancuernas',
    category: 'Mancuernas',
    muscleGroup: 'Espalda',
  ),
  ExerciseLibraryItem(
    id: 'row_cable',
    name: 'Remo en polea baja',
    category: 'Polea',
    muscleGroup: 'Espalda',
  ),
  ExerciseLibraryItem(
    id: 'lat_pulldown',
    name: 'Jalón al pecho',
    category: 'Máquina',
    muscleGroup: 'Espalda',
  ),
  ExerciseLibraryItem(
    id: 'pullups',
    name: 'Dominadas',
    category: 'Calistenia',
    muscleGroup: 'Espalda',
  ),
  ExerciseLibraryItem(
    id: 'pullover_cable',
    name: 'Pullover en polea',
    category: 'Polea',
    muscleGroup: 'Espalda',
  ),
  ExerciseLibraryItem(
    id: 'tbar_row',
    name: 'Remo T-Bar',
    category: 'Máquina',
    muscleGroup: 'Espalda',
  ),

  // Hombros
  ExerciseLibraryItem(
    id: 'ohp',
    name: 'Press militar (barra)',
    category: 'Barra',
    muscleGroup: 'Hombros',
  ),
  ExerciseLibraryItem(
    id: 'ohp_db',
    name: 'Press militar (mancuernas)',
    category: 'Mancuernas',
    muscleGroup: 'Hombros',
  ),
  ExerciseLibraryItem(
    id: 'lateral_raise',
    name: 'Elevaciones laterales',
    category: 'Mancuernas',
    muscleGroup: 'Hombros',
  ),
  ExerciseLibraryItem(
    id: 'rear_delt_fly',
    name: 'Pájaros (deltoides posterior)',
    category: 'Mancuernas',
    muscleGroup: 'Hombros',
  ),
  ExerciseLibraryItem(
    id: 'face_pull',
    name: 'Face pull',
    category: 'Polea',
    muscleGroup: 'Hombros',
  ),
  ExerciseLibraryItem(
    id: 'arnold_press',
    name: 'Press Arnold',
    category: 'Mancuernas',
    muscleGroup: 'Hombros',
  ),
  ExerciseLibraryItem(
    id: 'upright_row',
    name: 'Remo al mentón',
    category: 'Barra',
    muscleGroup: 'Hombros',
  ),

  // Bíceps
  ExerciseLibraryItem(
    id: 'curl_bar',
    name: 'Curl de bíceps (barra)',
    category: 'Barra',
    muscleGroup: 'Bíceps',
  ),
  ExerciseLibraryItem(
    id: 'curl_db',
    name: 'Curl de bíceps (mancuernas)',
    category: 'Mancuernas',
    muscleGroup: 'Bíceps',
  ),
  ExerciseLibraryItem(
    id: 'incline_curl',
    name: 'Curl inclinado',
    category: 'Mancuernas',
    muscleGroup: 'Bíceps',
  ),
  ExerciseLibraryItem(
    id: 'preacher',
    name: 'Curl en banco scott',
    category: 'Máquina',
    muscleGroup: 'Bíceps',
  ),
  ExerciseLibraryItem(
    id: 'hammer',
    name: 'Curl martillo',
    category: 'Mancuernas',
    muscleGroup: 'Bíceps',
  ),
  ExerciseLibraryItem(
    id: 'cable_curl',
    name: 'Curl en polea',
    category: 'Polea',
    muscleGroup: 'Bíceps',
  ),

  // Tríceps
  ExerciseLibraryItem(
    id: 'close_grip',
    name: 'Press cerrado',
    category: 'Barra',
    muscleGroup: 'Tríceps',
  ),
  ExerciseLibraryItem(
    id: 'skullcrusher',
    name: 'Extensiones tumbado (barra Z)',
    category: 'Barra',
    muscleGroup: 'Tríceps',
  ),
  ExerciseLibraryItem(
    id: 'triceps_pushdown',
    name: 'Extensiones en polea (barra/rope)',
    category: 'Polea',
    muscleGroup: 'Tríceps',
  ),
  ExerciseLibraryItem(
    id: 'overhead_db',
    name: 'Extensión por encima (mancuerna)',
    category: 'Mancuernas',
    muscleGroup: 'Tríceps',
  ),
  ExerciseLibraryItem(
    id: 'bench_dips',
    name: 'Fondos en banco',
    category: 'Calistenia',
    muscleGroup: 'Tríceps',
  ),
  ExerciseLibraryItem(
    id: 'dips',
    name: 'Fondos en paralelas',
    category: 'Calistenia',
    muscleGroup: 'Tríceps',
  ),

  // Piernas / Glúteos
  ExerciseLibraryItem(
    id: 'squat',
    name: 'Sentadilla (barra)',
    category: 'Barra',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'front_squat',
    name: 'Sentadilla frontal',
    category: 'Barra',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'leg_press',
    name: 'Prensa de piernas',
    category: 'Máquina',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'hack_squat',
    name: 'Hack squat',
    category: 'Máquina',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'lunges_db',
    name: 'Zancadas (mancuernas)',
    category: 'Mancuernas',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'bulgarian',
    name: 'Sentadilla búlgara',
    category: 'Mancuernas',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'rdl',
    name: 'Peso muerto rumano',
    category: 'Barra',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'good_morning',
    name: 'Buenos días',
    category: 'Barra',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'leg_extension',
    name: 'Extensión de cuádriceps',
    category: 'Máquina',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'leg_curl',
    name: 'Curl femoral',
    category: 'Máquina',
    muscleGroup: 'Piernas',
  ),
  ExerciseLibraryItem(
    id: 'hip_thrust',
    name: 'Hip thrust',
    category: 'Barra',
    muscleGroup: 'Glúteos',
  ),
  ExerciseLibraryItem(
    id: 'abductor',
    name: 'Abductores',
    category: 'Máquina',
    muscleGroup: 'Glúteos',
  ),
  ExerciseLibraryItem(
    id: 'calf_raise',
    name: 'Elevación de gemelos',
    category: 'Máquina',
    muscleGroup: 'Piernas',
  ),

  // Core
  ExerciseLibraryItem(
    id: 'crunch',
    name: 'Crunch',
    category: 'Peso libre',
    muscleGroup: 'Core',
  ),
  ExerciseLibraryItem(
    id: 'leg_raise',
    name: 'Elevación de piernas',
    category: 'Calistenia',
    muscleGroup: 'Core',
  ),
  ExerciseLibraryItem(
    id: 'plank',
    name: 'Plancha',
    category: 'Calistenia',
    muscleGroup: 'Core',
  ),
  ExerciseLibraryItem(
    id: 'cable_crunch',
    name: 'Crunch en polea',
    category: 'Polea',
    muscleGroup: 'Core',
  ),
  ExerciseLibraryItem(
    id: 'pallof_press',
    name: 'Pallof press',
    category: 'Polea',
    muscleGroup: 'Core',
  ),

  // Extras útiles
  ExerciseLibraryItem(
    id: 'farmer_walk',
    name: 'Farmer walk',
    category: 'Mancuernas',
    muscleGroup: 'Full body',
  ),
  ExerciseLibraryItem(
    id: 'sled_push',
    name: 'Trineo',
    category: 'Máquina',
    muscleGroup: 'Full body',
  ),
  ExerciseLibraryItem(
    id: 'rower',
    name: 'Remo (cardio)',
    category: 'Máquina',
    muscleGroup: 'Cardio',
  ),
  ExerciseLibraryItem(
    id: 'bike',
    name: 'Bicicleta',
    category: 'Máquina',
    muscleGroup: 'Cardio',
  ),
];
