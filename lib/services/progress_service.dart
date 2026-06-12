import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// PROGRESS SERVICE
// ─────────────────────────────────────────────

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  Future<Map<String, dynamic>> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'xp': prefs.getInt('ps_xp') ?? 0,
      'streak': prefs.getInt('ps_streak') ?? 0,
      'best_streak': prefs.getInt('ps_best_streak') ?? 0,
      'last_practice': prefs.getString('ps_last_practice'),
      'sandbox_count': prefs.getInt('ps_sandbox_count') ?? 0,
    };
  }

  Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('ps_xp') ?? 0;
    await prefs.setInt('ps_xp', current + amount);
  }

  Future<void> updateStreak({
    required int streak,
    required int bestStreak,
    required String lastPractice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ps_streak', streak);
    await prefs.setInt('ps_best_streak', bestStreak);
    await prefs.setString('ps_last_practice', lastPractice);
  }

  Future<void> incrementSandboxCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('ps_sandbox_count') ?? 0;
    await prefs.setInt('ps_sandbox_count', current + 1);
  }

  Future<void> markLessonCompleted({
    required String lessonId,
    required int score,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('ps_completed_lessons');
    Map<String, dynamic> map = {};
    if (existing != null) {
      map = Map<String, dynamic>.from(jsonDecode(existing) as Map);
    }
    map[lessonId] = {
      'completed_at': DateTime.now().toIso8601String(),
      'score': score,
    };
    await prefs.setString('ps_completed_lessons', jsonEncode(map));
  }

  Future<bool> isLessonCompleted(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('ps_completed_lessons');
    if (existing == null) return false;
    final map = Map<String, dynamic>.from(jsonDecode(existing) as Map);
    return map.containsKey(lessonId);
  }

  Future<List<Map<String, dynamic>>> getCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('ps_completed_lessons');
    if (existing == null) return [];
    final map = Map<String, dynamic>.from(jsonDecode(existing) as Map);
    final result = map.entries.map((e) {
      final v = e.value as Map<String, dynamic>;
      return {
        'lesson_id': e.key,
        'completed_at': v['completed_at'],
        'score': v['score'],
      };
    }).toList();
    result.sort((a, b) => (b['completed_at'] as String).compareTo(a['completed_at'] as String));
    return result;
  }

  Future<int?> getLessonScore(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('ps_completed_lessons');
    if (existing == null) return null;
    final map = Map<String, dynamic>.from(jsonDecode(existing) as Map);
    if (!map.containsKey(lessonId)) return null;
    return (map[lessonId] as Map<String, dynamic>)['score'] as int?;
  }

  Future<void> unlockAchievement(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('ps_achievements');
    Map<String, dynamic> map = {};
    if (existing != null) {
      map = Map<String, dynamic>.from(jsonDecode(existing) as Map);
    }
    if (!map.containsKey(achievementId)) {
      map[achievementId] = DateTime.now().toIso8601String();
      await prefs.setString('ps_achievements', jsonEncode(map));
    }
  }

  Future<bool> hasAchievement(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('ps_achievements');
    if (existing == null) return false;
    final map = Map<String, dynamic>.from(jsonDecode(existing) as Map);
    return map.containsKey(achievementId);
  }

  Future<List<Map<String, dynamic>>> getAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('ps_achievements');
    if (existing == null) return [];
    final map = Map<String, dynamic>.from(jsonDecode(existing) as Map);
    final result = map.entries.map((e) => {
      'achievement_id': e.key,
      'unlocked_at': e.value as String,
    }).toList();
    result.sort((a, b) => (a['unlocked_at'] as String).compareTo(b['unlocked_at'] as String));
    return result;
  }

  Future<void> close() async {}
}

// ─────────────────────────────────────────────
// SANDBOX SERVICE
// ─────────────────────────────────────────────

class SandboxService {
  static final SandboxService _instance = SandboxService._internal();
  factory SandboxService() => _instance;
  SandboxService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  final Map<String, List<Map<String, dynamic>>> _tables = {};

  Future<void> initialize() async {
    if (_initialized) return;
    _populateTables();
    _initialized = true;
  }

  void _populateTables() {
    _tables['departamentos'] = [
      {'id': 1, 'nombre': 'Ventas',     'presupuesto': 85000000.0, 'ciudad': 'Santiago'},
      {'id': 2, 'nombre': 'IT',          'presupuesto': 60000000.0, 'ciudad': 'Santiago'},
      {'id': 3, 'nombre': 'RRHH',        'presupuesto': 35000000.0, 'ciudad': 'Temuco'},
      {'id': 4, 'nombre': 'Finanzas',    'presupuesto': 50000000.0, 'ciudad': 'Santiago'},
      {'id': 5, 'nombre': 'Logistica',   'presupuesto': 45000000.0, 'ciudad': 'Concepcion'},
      {'id': 6, 'nombre': 'Marketing',   'presupuesto': 40000000.0, 'ciudad': 'Valparaiso'},
    ];

    _tables['empleados'] = [
      {'id': 1,  'nombre': 'Camila',    'apellido': 'Rojas',      'departamento_id': 1, 'cargo': 'Ejecutivo de Ventas',    'salario': 1200000.0, 'fecha_contrato': '2019-03-15', 'activo': 1},
      {'id': 2,  'nombre': 'Felipe',    'apellido': 'Munoz',      'departamento_id': 1, 'cargo': 'Supervisor de Ventas',   'salario': 1800000.0, 'fecha_contrato': '2017-07-01', 'activo': 1},
      {'id': 3,  'nombre': 'Valentina', 'apellido': 'Soto',       'departamento_id': 2, 'cargo': 'Desarrolladora Senior',  'salario': 2500000.0, 'fecha_contrato': '2020-01-10', 'activo': 1},
      {'id': 4,  'nombre': 'Sebastian', 'apellido': 'Perez',      'departamento_id': 2, 'cargo': 'Analista de Datos',      'salario': 1900000.0, 'fecha_contrato': '2021-04-20', 'activo': 1},
      {'id': 5,  'nombre': 'Ignacia',   'apellido': 'Lagos',      'departamento_id': 3, 'cargo': 'Jefa de RRHH',           'salario': 2200000.0, 'fecha_contrato': '2016-09-05', 'activo': 1},
      {'id': 6,  'nombre': 'Tomas',     'apellido': 'Fuentes',    'departamento_id': 3, 'cargo': 'Asistente RRHH',         'salario': 900000.0,  'fecha_contrato': '2022-11-14', 'activo': 1},
      {'id': 7,  'nombre': 'Constanza', 'apellido': 'Herrera',    'departamento_id': 4, 'cargo': 'Contadora',              'salario': 2100000.0, 'fecha_contrato': '2018-06-22', 'activo': 1},
      {'id': 8,  'nombre': 'Rodrigo',   'apellido': 'Alvarez',    'departamento_id': 4, 'cargo': 'Analista Financiero',    'salario': 1750000.0, 'fecha_contrato': '2019-08-30', 'activo': 1},
      {'id': 9,  'nombre': 'Javiera',   'apellido': 'Mendez',     'departamento_id': 5, 'cargo': 'Coordinadora Logistica', 'salario': 1600000.0, 'fecha_contrato': '2020-03-01', 'activo': 1},
      {'id': 10, 'nombre': 'Nicolas',   'apellido': 'Sanchez',    'departamento_id': 5, 'cargo': 'Operador de Bodega',     'salario': 850000.0,  'fecha_contrato': '2021-07-19', 'activo': 1},
      {'id': 11, 'nombre': 'Daniela',   'apellido': 'Torres',     'departamento_id': 6, 'cargo': 'Disenadora Grafica',     'salario': 1400000.0, 'fecha_contrato': '2020-09-08', 'activo': 1},
      {'id': 12, 'nombre': 'Matias',    'apellido': 'Vargas',     'departamento_id': 6, 'cargo': 'Community Manager',      'salario': 1100000.0, 'fecha_contrato': '2022-02-14', 'activo': 1},
      {'id': 13, 'nombre': 'Antonia',   'apellido': 'Morales',    'departamento_id': 1, 'cargo': 'Ejecutivo de Ventas',    'salario': 1250000.0, 'fecha_contrato': '2021-05-25', 'activo': 1},
      {'id': 14, 'nombre': 'Cristobal', 'apellido': 'Espinoza',   'departamento_id': 2, 'cargo': 'Administrador de Sistemas', 'salario': 2800000.0, 'fecha_contrato': '2015-11-03', 'activo': 1},
      {'id': 15, 'nombre': 'Isidora',   'apellido': 'Pinto',      'departamento_id': 4, 'cargo': 'Gerente de Finanzas',    'salario': 4500000.0, 'fecha_contrato': '2013-04-17', 'activo': 1},
      {'id': 16, 'nombre': 'Andres',    'apellido': 'Castro',     'departamento_id': 1, 'cargo': 'Gerente de Ventas',      'salario': 5000000.0, 'fecha_contrato': '2012-08-01', 'activo': 1},
      {'id': 17, 'nombre': 'Carla',     'apellido': 'Jimenez',    'departamento_id': 5, 'cargo': 'Chofer de Reparto',      'salario': 800000.0,  'fecha_contrato': '2023-01-09', 'activo': 1},
      {'id': 18, 'nombre': 'Pablo',     'apellido': 'Rios',       'departamento_id': 2, 'cargo': 'Desarrollador Junior',   'salario': 1300000.0, 'fecha_contrato': '2023-03-20', 'activo': 1},
      {'id': 19, 'nombre': 'Francisca', 'apellido': 'Gomez',      'departamento_id': 3, 'cargo': 'Psicologa Laboral',      'salario': 1950000.0, 'fecha_contrato': '2019-10-15', 'activo': 1},
      {'id': 20, 'nombre': 'Eduardo',   'apellido': 'Silva',      'departamento_id': 6, 'cargo': 'Gerente de Marketing',   'salario': 3800000.0, 'fecha_contrato': '2016-02-28', 'activo': 1},
      {'id': 21, 'nombre': 'Alejandra', 'apellido': 'Nunez',      'departamento_id': 1, 'cargo': 'Ejecutivo de Ventas',    'salario': 1150000.0, 'fecha_contrato': '2022-06-01', 'activo': 0},
      {'id': 22, 'nombre': 'Ricardo',   'apellido': 'Flores',     'departamento_id': 5, 'cargo': 'Jefe de Logistica',      'salario': 2900000.0, 'fecha_contrato': '2014-12-10', 'activo': 1},
      {'id': 23, 'nombre': 'Monica',    'apellido': 'Gutierrez',  'departamento_id': 4, 'cargo': 'Auditora Interna',       'salario': 2400000.0, 'fecha_contrato': '2018-03-05', 'activo': 1},
      {'id': 24, 'nombre': 'Jorge',     'apellido': 'Ramos',      'departamento_id': 2, 'cargo': 'Arquitecto de Software', 'salario': 3200000.0, 'fecha_contrato': '2017-09-18', 'activo': 1},
      {'id': 25, 'nombre': 'Loreto',    'apellido': 'Vega',       'departamento_id': 6, 'cargo': 'Analista de Marketing',  'salario': 1350000.0, 'fecha_contrato': '2021-11-22', 'activo': 1},
    ];

    _tables['productos'] = [
      {'id': 1,  'codigo': 'FERT-001', 'nombre': 'Urea 46%',                   'categoria': 'Fertilizante',  'precio': 18500.0,  'stock': 500},
      {'id': 2,  'codigo': 'FERT-002', 'nombre': 'Nitrato de Amonio',           'categoria': 'Fertilizante',  'precio': 22000.0,  'stock': 350},
      {'id': 3,  'codigo': 'FERT-003', 'nombre': 'Superfosfato Triple',         'categoria': 'Fertilizante',  'precio': 27500.0,  'stock': 280},
      {'id': 4,  'codigo': 'FERT-004', 'nombre': 'Sulfato de Potasio',          'categoria': 'Fertilizante',  'precio': 32000.0,  'stock': 210},
      {'id': 5,  'codigo': 'FERT-005', 'nombre': 'NPK 15-15-15',               'categoria': 'Fertilizante',  'precio': 24500.0,  'stock': 420},
      {'id': 6,  'codigo': 'FERT-006', 'nombre': 'Sulfato de Zinc',            'categoria': 'Fertilizante',  'precio': 15000.0,  'stock': 180},
      {'id': 7,  'codigo': 'SEM-001',  'nombre': 'Semilla Trigo Invernal',      'categoria': 'Semilla',       'precio': 8500.0,   'stock': 1200},
      {'id': 8,  'codigo': 'SEM-002',  'nombre': 'Semilla Maiz Hibrido',        'categoria': 'Semilla',       'precio': 45000.0,  'stock': 600},
      {'id': 9,  'codigo': 'SEM-003',  'nombre': 'Semilla Raps Canola',         'categoria': 'Semilla',       'precio': 12000.0,  'stock': 800},
      {'id': 10, 'codigo': 'SEM-004',  'nombre': 'Semilla Avena Blanquita',     'categoria': 'Semilla',       'precio': 6500.0,   'stock': 950},
      {'id': 11, 'codigo': 'SEM-005',  'nombre': 'Semilla Papa Desiree',        'categoria': 'Semilla',       'precio': 9800.0,   'stock': 700},
      {'id': 12, 'codigo': 'PEST-001', 'nombre': 'Glifosato 48% SL',           'categoria': 'Herbicida',     'precio': 7200.0,   'stock': 850},
      {'id': 13, 'codigo': 'PEST-002', 'nombre': 'Mancozeb 80% WP',            'categoria': 'Fungicida',     'precio': 11500.0,  'stock': 430},
      {'id': 14, 'codigo': 'PEST-003', 'nombre': 'Clorpirifos 48% EC',         'categoria': 'Insecticida',   'precio': 14200.0,  'stock': 310},
      {'id': 15, 'codigo': 'PEST-004', 'nombre': 'Atrazina 50% SC',            'categoria': 'Herbicida',     'precio': 9600.0,   'stock': 520},
      {'id': 16, 'codigo': 'PEST-005', 'nombre': 'Propiconazol 25% EC',        'categoria': 'Fungicida',     'precio': 18700.0,  'stock': 260},
      {'id': 17, 'codigo': 'PEST-006', 'nombre': 'Imidacloprid 35% SC',        'categoria': 'Insecticida',   'precio': 22000.0,  'stock': 190},
      {'id': 18, 'codigo': 'PEST-007', 'nombre': 'Fluazinam 50% SC',           'categoria': 'Fungicida',     'precio': 31500.0,  'stock': 140},
      {'id': 19, 'codigo': 'RIEGO-001','nombre': 'Cinta de Riego Goteo 16mm',  'categoria': 'Riego',         'precio': 3200.0,   'stock': 2000},
      {'id': 20, 'codigo': 'RIEGO-002','nombre': 'Aspersor de Impacto 1/2"',   'categoria': 'Riego',         'precio': 4800.0,   'stock': 750},
      {'id': 21, 'codigo': 'FERT-007', 'nombre': 'Acido Humico Liquido',       'categoria': 'Bioestimulante','precio': 28000.0,  'stock': 320},
      {'id': 22, 'codigo': 'FERT-008', 'nombre': 'Alga Marina Concentrado',    'categoria': 'Bioestimulante','precio': 35000.0,  'stock': 210},
      {'id': 23, 'codigo': 'SEM-006',  'nombre': 'Semilla Cebada Cervecera',   'categoria': 'Semilla',       'precio': 7800.0,   'stock': 880},
      {'id': 24, 'codigo': 'PEST-008', 'nombre': 'Metribuzin 70% WP',          'categoria': 'Herbicida',     'precio': 16500.0,  'stock': 290},
      {'id': 25, 'codigo': 'FERT-009', 'nombre': 'Calcio Boro Foliar',         'categoria': 'Fertilizante',  'precio': 19800.0,  'stock': 370},
      {'id': 26, 'codigo': 'RIEGO-003','nombre': 'Filtro Disco 2" 120 Mesh',   'categoria': 'Riego',         'precio': 38000.0,  'stock': 95},
      {'id': 27, 'codigo': 'PEST-009', 'nombre': 'Azoxistrobina 25% SC',       'categoria': 'Fungicida',     'precio': 42000.0,  'stock': 160},
      {'id': 28, 'codigo': 'SEM-007',  'nombre': 'Semilla Girasol Alto Oleico','categoria': 'Semilla',       'precio': 16000.0,  'stock': 540},
      {'id': 29, 'codigo': 'FERT-010', 'nombre': 'Magnesio EDTA Quelatado',    'categoria': 'Fertilizante',  'precio': 23500.0,  'stock': 250},
      {'id': 30, 'codigo': 'PEST-010', 'nombre': 'Abamectina 1.8% EC',         'categoria': 'Insecticida',   'precio': 26000.0,  'stock': 175},
    ];

    _tables['proveedores'] = [
      {'id': 1,  'nombre': 'Anasac Chile S.A.',            'rut': '76.075.832-4', 'ciudad': 'Santiago'},
      {'id': 2,  'nombre': 'Coagra S.A.',                   'rut': '79.521.460-1', 'ciudad': 'Santiago'},
      {'id': 3,  'nombre': 'Basf Chile Ltda.',              'rut': '96.553.400-K', 'ciudad': 'Santiago'},
      {'id': 4,  'nombre': 'Bayer CropScience S.A.',        'rut': '96.613.560-1', 'ciudad': 'Santiago'},
      {'id': 5,  'nombre': 'Syngenta Chile S.A.',           'rut': '76.341.520-7', 'ciudad': 'Santiago'},
      {'id': 6,  'nombre': 'Semillas Pioneer S.A.',         'rut': '82.730.400-2', 'ciudad': 'Los Angeles'},
      {'id': 7,  'nombre': 'Fertiberia Chile Ltda.',        'rut': '76.892.140-5', 'ciudad': 'Antofagasta'},
      {'id': 8,  'nombre': 'Netafim Chile S.A.',            'rut': '77.220.680-9', 'ciudad': 'Santiago'},
      {'id': 9,  'nombre': 'Compo Expert Chile Ltda.',      'rut': '76.431.900-3', 'ciudad': 'Concepcion'},
      {'id': 10, 'nombre': 'Corteva Agriscience Chile S.A.','rut': '76.950.220-8', 'ciudad': 'Santiago'},
    ];

    _tables['ventas'] = [
      {'id': 1,  'fecha': '2023-01-10', 'empleado_id': 1,  'producto_id': 1,  'cantidad': 50,  'precio_unitario': 18500.0,  'total': 925000.0},
      {'id': 2,  'fecha': '2023-01-15', 'empleado_id': 2,  'producto_id': 7,  'cantidad': 100, 'precio_unitario': 8500.0,   'total': 850000.0},
      {'id': 3,  'fecha': '2023-01-20', 'empleado_id': 13, 'producto_id': 12, 'cantidad': 80,  'precio_unitario': 7200.0,   'total': 576000.0},
      {'id': 4,  'fecha': '2023-02-03', 'empleado_id': 1,  'producto_id': 5,  'cantidad': 60,  'precio_unitario': 24500.0,  'total': 1470000.0},
      {'id': 5,  'fecha': '2023-02-14', 'empleado_id': 16, 'producto_id': 8,  'cantidad': 20,  'precio_unitario': 45000.0,  'total': 900000.0},
      {'id': 6,  'fecha': '2023-02-22', 'empleado_id': 2,  'producto_id': 3,  'cantidad': 45,  'precio_unitario': 27500.0,  'total': 1237500.0},
      {'id': 7,  'fecha': '2023-03-05', 'empleado_id': 13, 'producto_id': 14, 'cantidad': 30,  'precio_unitario': 14200.0,  'total': 426000.0},
      {'id': 8,  'fecha': '2023-03-18', 'empleado_id': 1,  'producto_id': 2,  'cantidad': 70,  'precio_unitario': 22000.0,  'total': 1540000.0},
      {'id': 9,  'fecha': '2023-03-25', 'empleado_id': 21, 'producto_id': 19, 'cantidad': 200, 'precio_unitario': 3200.0,   'total': 640000.0},
      {'id': 10, 'fecha': '2023-04-04', 'empleado_id': 2,  'producto_id': 13, 'cantidad': 40,  'precio_unitario': 11500.0,  'total': 460000.0},
      {'id': 11, 'fecha': '2023-04-12', 'empleado_id': 16, 'producto_id': 15, 'cantidad': 55,  'precio_unitario': 9600.0,   'total': 528000.0},
      {'id': 12, 'fecha': '2023-04-20', 'empleado_id': 13, 'producto_id': 9,  'cantidad': 90,  'precio_unitario': 12000.0,  'total': 1080000.0},
      {'id': 13, 'fecha': '2023-05-06', 'empleado_id': 1,  'producto_id': 21, 'cantidad': 25,  'precio_unitario': 28000.0,  'total': 700000.0},
      {'id': 14, 'fecha': '2023-05-15', 'empleado_id': 2,  'producto_id': 4,  'cantidad': 35,  'precio_unitario': 32000.0,  'total': 1120000.0},
      {'id': 15, 'fecha': '2023-05-28', 'empleado_id': 21, 'producto_id': 25, 'cantidad': 28,  'precio_unitario': 19800.0,  'total': 554400.0},
      {'id': 16, 'fecha': '2023-06-08', 'empleado_id': 13, 'producto_id': 17, 'cantidad': 18,  'precio_unitario': 22000.0,  'total': 396000.0},
      {'id': 17, 'fecha': '2023-06-16', 'empleado_id': 16, 'producto_id': 7,  'cantidad': 150, 'precio_unitario': 8500.0,   'total': 1275000.0},
      {'id': 18, 'fecha': '2023-06-24', 'empleado_id': 1,  'producto_id': 27, 'cantidad': 12,  'precio_unitario': 42000.0,  'total': 504000.0},
      {'id': 19, 'fecha': '2023-07-03', 'empleado_id': 2,  'producto_id': 10, 'cantidad': 120, 'precio_unitario': 6500.0,   'total': 780000.0},
      {'id': 20, 'fecha': '2023-07-11', 'empleado_id': 13, 'producto_id': 22, 'cantidad': 15,  'precio_unitario': 35000.0,  'total': 525000.0},
    ];
  }

  // ── executeQuery ───────────────────────────

  Future<Map<String, dynamic>> executeQuery(String sql) async {
    final trimmed = sql.trim();
    final upperFirst = trimmed.split(RegExp(r'\s+')).first.toUpperCase();

    if (upperFirst != 'SELECT') {
      final dmlOps = {'DROP', 'DELETE', 'UPDATE', 'INSERT', 'ALTER', 'CREATE'};
      final msg = dmlOps.contains(upperFirst)
          ? 'Solo se permiten consultas SELECT en el sandbox. Las operaciones de modificacion ($upperFirst) no estan permitidas para proteger los datos de practica.'
          : 'Solo se permiten consultas SELECT en el sandbox.';
      return {
        'success': false,
        'columns': <String>[],
        'rows': <List<dynamic>>[],
        'rowCount': 0,
        'executionMs': 0,
        'error': msg,
      };
    }

    await initialize();
    final stopwatch = Stopwatch()..start();

    try {
      final results = _executeSelectInMemory(trimmed);
      stopwatch.stop();

      if (results.isEmpty) {
        return {
          'success': true,
          'columns': <String>[],
          'rows': <List<dynamic>>[],
          'rowCount': 0,
          'executionMs': stopwatch.elapsedMilliseconds,
          'error': null,
        };
      }

      final columns = results.first.keys.toList();
      final rows = results.map((row) => columns.map((col) => row[col]).toList()).toList();

      return {
        'success': true,
        'columns': columns,
        'rows': rows,
        'rowCount': rows.length,
        'executionMs': stopwatch.elapsedMilliseconds,
        'error': null,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'columns': <String>[],
        'rows': <List<dynamic>>[],
        'rowCount': 0,
        'executionMs': stopwatch.elapsedMilliseconds,
        'error': e.toString(),
      };
    }
  }

  List<Map<String, dynamic>> _executeSelectInMemory(String sql) {
    final upper = sql.toUpperCase();

    // Detect main table
    String? mainTable;
    for (final t in _tables.keys) {
      if (upper.contains(' ${t.toUpperCase()}') || upper.contains('\n${t.toUpperCase()}')) {
        mainTable = t;
        break;
      }
    }

    if (mainTable == null) {
      throw Exception('Tabla no encontrada. Tablas disponibles: ${_tables.keys.join(', ')}');
    }

    List<Map<String, dynamic>> rows = List.from(_tables[mainTable]!);

    // Handle JOIN with another table (basic support)
    String? joinTable;
    String? joinLeftCol;
    String? joinRightCol;

    final joinMatch = RegExp(
      r'JOIN\s+(\w+)\s+(?:\w+\s+)?ON\s+(\w+)\.(\w+)\s*=\s*(\w+)\.(\w+)',
      caseSensitive: false,
    ).firstMatch(sql);

    if (joinMatch != null) {
      joinTable = joinMatch.group(1)!.toLowerCase();
      final leftAlias = joinMatch.group(2)!.toLowerCase();
      final leftCol = joinMatch.group(3)!.toLowerCase();
      final rightAlias = joinMatch.group(4)!.toLowerCase();
      final rightCol = joinMatch.group(5)!.toLowerCase();

      final joinData = _tables[joinTable];
      if (joinData != null) {
        // Determine which side is which table
        final leftIsMain = leftAlias == mainTable || _tables[mainTable]!.isNotEmpty && _tables[mainTable]!.first.containsKey(leftCol);
        final mainCol = leftIsMain ? leftCol : rightCol;
        final foreignCol = leftIsMain ? rightCol : leftCol;

        rows = rows.map((row) {
          final keyVal = row[mainCol];
          final matched = joinData.firstWhere(
            (jr) => jr[foreignCol] == keyVal,
            orElse: () => {},
          );
          final merged = <String, dynamic>{};
          for (final e in row.entries) merged['${mainTable!}.${e.key}'] = e.value;
          for (final e in matched.entries) merged['${joinTable!}.${e.key}'] = e.value;
          // Also add flat keys for simpler column access
          merged.addAll(row);
          for (final e in matched.entries) {
            if (!merged.containsKey(e.key)) merged[e.key] = e.value;
          }
          return merged;
        }).toList();
      }
    }

    // Apply WHERE clause (basic: single condition with = or > or < or LIKE)
    final whereMatch = RegExp(
      r'WHERE\s+(.+?)(?:\s+ORDER|\s+GROUP|\s+LIMIT|\s+HAVING|$)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(sql);

    if (whereMatch != null) {
      final whereClause = whereMatch.group(1)!.trim();
      rows = _applyWhere(rows, whereClause);
    }

    // Apply ORDER BY
    final orderMatch = RegExp(
      r'ORDER\s+BY\s+(\w+(?:\.\w+)?)\s*(ASC|DESC)?',
      caseSensitive: false,
    ).firstMatch(sql);

    if (orderMatch != null) {
      final orderCol = orderMatch.group(1)!.replaceFirst(RegExp(r'^\w+\.'), '');
      final desc = (orderMatch.group(2) ?? '').toUpperCase() == 'DESC';

      rows.sort((a, b) {
        final av = a[orderCol];
        final bv = b[orderCol];
        if (av == null && bv == null) return 0;
        if (av == null) return desc ? 1 : -1;
        if (bv == null) return desc ? -1 : 1;
        int cmp;
        if (av is num && bv is num) {
          cmp = av.compareTo(bv);
        } else {
          cmp = av.toString().compareTo(bv.toString());
        }
        return desc ? -cmp : cmp;
      });
    }

    // Apply LIMIT
    final limitMatch = RegExp(r'LIMIT\s+(\d+)', caseSensitive: false).firstMatch(sql);
    if (limitMatch != null) {
      final limit = int.parse(limitMatch.group(1)!);
      if (rows.length > limit) rows = rows.sublist(0, limit);
    }

    // Apply SELECT columns (basic: detect * vs column list)
    final selectMatch = RegExp(
      r'SELECT\s+(.+?)\s+FROM',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(sql);

    if (selectMatch != null) {
      final colsPart = selectMatch.group(1)!.trim();
      if (colsPart != '*' && !colsPart.contains('*')) {
        final requestedCols = colsPart
            .split(',')
            .map((c) => c.trim().replaceFirst(RegExp(r'^\w+\.'), '').toLowerCase())
            .toList();

        rows = rows.map((row) {
          final lowered = <String, dynamic>{
            for (final e in row.entries) e.key.toLowerCase(): e.value
          };
          final projected = <String, dynamic>{};
          for (final col in requestedCols) {
            if (lowered.containsKey(col)) {
              projected[col] = lowered[col];
            }
          }
          return projected.isEmpty ? row : projected;
        }).toList();
      }
    }

    return rows;
  }

  List<Map<String, dynamic>> _applyWhere(
    List<Map<String, dynamic>> rows,
    String whereClause,
  ) {
    // Support AND chaining (basic)
    final conditions = whereClause.split(RegExp(r'\bAND\b', caseSensitive: false));

    return rows.where((row) {
      for (final rawCond in conditions) {
        final cond = rawCond.trim();
        if (!_evaluateCondition(row, cond)) return false;
      }
      return true;
    }).toList();
  }

  bool _evaluateCondition(Map<String, dynamic> row, String cond) {
    // LIKE
    final likeMatch = RegExp(
      r"(\w+(?:\.\w+)?)\s+LIKE\s+'([^']*)'",
      caseSensitive: false,
    ).firstMatch(cond);
    if (likeMatch != null) {
      final col = likeMatch.group(1)!.replaceFirst(RegExp(r'^\w+\.'), '').toLowerCase();
      final pattern = likeMatch.group(2)!.replaceAll('%', '.*').replaceAll('_', '.');
      final val = _getColValue(row, col)?.toString() ?? '';
      return RegExp('^$pattern\$', caseSensitive: false).hasMatch(val);
    }

    // >=, <=, !=, =, >, <
    final opMatch = RegExp(
      r"(\w+(?:\.\w+)?)\s*(>=|<=|!=|=|>|<)\s*'?([^'\s]+)'?",
      caseSensitive: false,
    ).firstMatch(cond);
    if (opMatch != null) {
      final col = opMatch.group(1)!.replaceFirst(RegExp(r'^\w+\.'), '').toLowerCase();
      final op = opMatch.group(2)!;
      final rawVal = opMatch.group(3)!;
      final rowVal = _getColValue(row, col);

      if (rowVal == null) return false;

      final numVal = num.tryParse(rawVal);
      final rowNum = rowVal is num ? rowVal : num.tryParse(rowVal.toString());

      if (numVal != null && rowNum != null) {
        switch (op) {
          case '=': return rowNum == numVal;
          case '!=': return rowNum != numVal;
          case '>': return rowNum > numVal;
          case '<': return rowNum < numVal;
          case '>=': return rowNum >= numVal;
          case '<=': return rowNum <= numVal;
        }
      } else {
        final sv = rowVal.toString();
        switch (op) {
          case '=': return sv == rawVal;
          case '!=': return sv != rawVal;
          case '>': return sv.compareTo(rawVal) > 0;
          case '<': return sv.compareTo(rawVal) < 0;
          case '>=': return sv.compareTo(rawVal) >= 0;
          case '<=': return sv.compareTo(rawVal) <= 0;
        }
      }
    }

    return true;
  }

  dynamic _getColValue(Map<String, dynamic> row, String col) {
    if (row.containsKey(col)) return row[col];
    // Try case-insensitive lookup
    for (final k in row.keys) {
      if (k.toLowerCase() == col) return row[k];
    }
    return null;
  }

  // ── getTableSchemas ────────────────────────

  Future<Map<String, List<Map<String, dynamic>>>> getTableSchemas() async {
    await initialize();

    final Map<String, Map<String, String>> schemaDefs = {
      'empleados': {
        'id': 'INTEGER', 'nombre': 'TEXT', 'apellido': 'TEXT',
        'departamento_id': 'INTEGER', 'cargo': 'TEXT',
        'salario': 'REAL', 'fecha_contrato': 'TEXT', 'activo': 'INTEGER',
      },
      'departamentos': {
        'id': 'INTEGER', 'nombre': 'TEXT',
        'presupuesto': 'REAL', 'ciudad': 'TEXT',
      },
      'productos': {
        'id': 'INTEGER', 'codigo': 'TEXT', 'nombre': 'TEXT',
        'categoria': 'TEXT', 'precio': 'REAL', 'stock': 'INTEGER',
      },
      'ventas': {
        'id': 'INTEGER', 'fecha': 'TEXT', 'empleado_id': 'INTEGER',
        'producto_id': 'INTEGER', 'cantidad': 'INTEGER',
        'precio_unitario': 'REAL', 'total': 'REAL',
      },
      'proveedores': {
        'id': 'INTEGER', 'nombre': 'TEXT', 'rut': 'TEXT', 'ciudad': 'TEXT',
      },
    };

    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in schemaDefs.entries) {
      int cid = 0;
      result[entry.key] = entry.value.entries.map((e) => {
        'cid': cid++,
        'name': e.key,
        'type': e.value,
        'notnull': 0,
        'dflt_value': null,
        'pk': e.key == 'id' ? 1 : 0,
      }).toList();
    }

    return result;
  }

  Future<void> close() async {
    _initialized = false;
    _tables.clear();
  }
}
