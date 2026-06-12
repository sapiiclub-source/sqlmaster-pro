import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// ─────────────────────────────────────────────
// PROGRESS SERVICE
// ─────────────────────────────────────────────

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _openProgressDb();
    return _db!;
  }

  Future<Database> _openProgressDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'progress.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_progress (
            id INTEGER PRIMARY KEY,
            xp INT NOT NULL DEFAULT 0,
            streak INT NOT NULL DEFAULT 0,
            best_streak INT NOT NULL DEFAULT 0,
            last_practice TEXT,
            sandbox_count INT NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE completed_lessons (
            lesson_id TEXT PRIMARY KEY,
            completed_at TEXT NOT NULL,
            score INT NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE achievements (
            achievement_id TEXT PRIMARY KEY,
            unlocked_at TEXT NOT NULL
          )
        ''');
        // Seed initial row
        await db.insert('user_progress', {
          'id': 1,
          'xp': 0,
          'streak': 0,
          'best_streak': 0,
          'last_practice': null,
          'sandbox_count': 0,
        });
      },
    );
  }

  // ── user_progress ──────────────────────────

  Future<Map<String, dynamic>> getProgress() async {
    final db = await _database;
    final rows = await db.query('user_progress', where: 'id = 1');
    if (rows.isEmpty) {
      return {
        'xp': 0,
        'streak': 0,
        'best_streak': 0,
        'last_practice': null,
        'sandbox_count': 0,
      };
    }
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> addXp(int amount) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE user_progress SET xp = xp + ? WHERE id = 1',
      [amount],
    );
  }

  Future<void> updateStreak({required int streak, required int bestStreak, required String lastPractice}) async {
    final db = await _database;
    await db.update(
      'user_progress',
      {
        'streak': streak,
        'best_streak': bestStreak,
        'last_practice': lastPractice,
      },
      where: 'id = 1',
    );
  }

  Future<void> incrementSandboxCount() async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE user_progress SET sandbox_count = sandbox_count + 1 WHERE id = 1',
    );
  }

  // ── completed_lessons ──────────────────────

  Future<void> markLessonCompleted({
    required String lessonId,
    required int score,
  }) async {
    final db = await _database;
    await db.insert(
      'completed_lessons',
      {
        'lesson_id': lessonId,
        'completed_at': DateTime.now().toIso8601String(),
        'score': score,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isLessonCompleted(String lessonId) async {
    final db = await _database;
    final rows = await db.query(
      'completed_lessons',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
    return rows.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getCompletedLessons() async {
    final db = await _database;
    return await db.query('completed_lessons', orderBy: 'completed_at DESC');
  }

  Future<int?> getLessonScore(String lessonId) async {
    final db = await _database;
    final rows = await db.query(
      'completed_lessons',
      columns: ['score'],
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
    if (rows.isEmpty) return null;
    return rows.first['score'] as int?;
  }

  // ── achievements ───────────────────────────

  Future<void> unlockAchievement(String achievementId) async {
    final db = await _database;
    await db.insert(
      'achievements',
      {
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> hasAchievement(String achievementId) async {
    final db = await _database;
    final rows = await db.query(
      'achievements',
      where: 'achievement_id = ?',
      whereArgs: [achievementId],
    );
    return rows.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAchievements() async {
    final db = await _database;
    return await db.query('achievements', orderBy: 'unlocked_at ASC');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

// ─────────────────────────────────────────────
// SANDBOX SERVICE
// ─────────────────────────────────────────────

class SandboxService {
  static final SandboxService _instance = SandboxService._internal();
  factory SandboxService() => _instance;
  SandboxService._internal();

  Database? _db;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _openSandboxDb();
    return _db!;
  }

  Future<Database> _openSandboxDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'sandbox.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _populateTables(db);
      },
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;
    final db = await _database;
    // Verify tables exist; if not, recreate (handles wiped DB scenario)
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='empleados'",
    );
    if (tables.isEmpty) {
      await _createTables(db);
      await _populateTables(db);
    }
    _initialized = true;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS departamentos (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        presupuesto REAL NOT NULL,
        ciudad TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS empleados (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        apellido TEXT NOT NULL,
        departamento_id INTEGER NOT NULL,
        cargo TEXT NOT NULL,
        salario REAL NOT NULL,
        fecha_contrato TEXT NOT NULL,
        activo INT NOT NULL DEFAULT 1,
        FOREIGN KEY (departamento_id) REFERENCES departamentos(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS productos (
        id INTEGER PRIMARY KEY,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        precio REAL NOT NULL,
        stock INT NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS proveedores (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        rut TEXT NOT NULL,
        ciudad TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventas (
        id INTEGER PRIMARY KEY,
        fecha TEXT NOT NULL,
        empleado_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INT NOT NULL,
        precio_unitario REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (empleado_id) REFERENCES empleados(id),
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
  }

  Future<void> _populateTables(Database db) async {
    final batch = db.batch();

    // ── departamentos (6) ──────────────────────
    final List<Map<String, dynamic>> depts = [
      {'id': 1, 'nombre': 'Ventas',     'presupuesto': 85000000.0, 'ciudad': 'Santiago'},
      {'id': 2, 'nombre': 'IT',          'presupuesto': 60000000.0, 'ciudad': 'Santiago'},
      {'id': 3, 'nombre': 'RRHH',        'presupuesto': 35000000.0, 'ciudad': 'Temuco'},
      {'id': 4, 'nombre': 'Finanzas',    'presupuesto': 50000000.0, 'ciudad': 'Santiago'},
      {'id': 5, 'nombre': 'Logistica',   'presupuesto': 45000000.0, 'ciudad': 'Concepcion'},
      {'id': 6, 'nombre': 'Marketing',   'presupuesto': 40000000.0, 'ciudad': 'Valparaiso'},
    ];
    for (final d in depts) {
      batch.insert('departamentos', d, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // ── empleados (25) ─────────────────────────
    final List<Map<String, dynamic>> emps = [
      {'id': 1,  'nombre': 'Camila',    'apellido': 'Rojas',      'departamento_id': 1, 'cargo': 'Ejecutivo de Ventas',   'salario': 1200000.0, 'fecha_contrato': '2019-03-15', 'activo': 1},
      {'id': 2,  'nombre': 'Felipe',    'apellido': 'Munoz',      'departamento_id': 1, 'cargo': 'Supervisor de Ventas',  'salario': 1800000.0, 'fecha_contrato': '2017-07-01', 'activo': 1},
      {'id': 3,  'nombre': 'Valentina', 'apellido': 'Soto',       'departamento_id': 2, 'cargo': 'Desarrolladora Senior', 'salario': 2500000.0, 'fecha_contrato': '2020-01-10', 'activo': 1},
      {'id': 4,  'nombre': 'Sebastian', 'apellido': 'Perez',      'departamento_id': 2, 'cargo': 'Analista de Datos',     'salario': 1900000.0, 'fecha_contrato': '2021-04-20', 'activo': 1},
      {'id': 5,  'nombre': 'Ignacia',   'apellido': 'Lagos',      'departamento_id': 3, 'cargo': 'Jefa de RRHH',          'salario': 2200000.0, 'fecha_contrato': '2016-09-05', 'activo': 1},
      {'id': 6,  'nombre': 'Tomas',     'apellido': 'Fuentes',    'departamento_id': 3, 'cargo': 'Asistente RRHH',        'salario': 900000.0,  'fecha_contrato': '2022-11-14', 'activo': 1},
      {'id': 7,  'nombre': 'Constanza', 'apellido': 'Herrera',    'departamento_id': 4, 'cargo': 'Contadora',             'salario': 2100000.0, 'fecha_contrato': '2018-06-22', 'activo': 1},
      {'id': 8,  'nombre': 'Rodrigo',   'apellido': 'Alvarez',    'departamento_id': 4, 'cargo': 'Analista Financiero',   'salario': 1750000.0, 'fecha_contrato': '2019-08-30', 'activo': 1},
      {'id': 9,  'nombre': 'Javiera',   'apellido': 'Mendez',     'departamento_id': 5, 'cargo': 'Coordinadora Logistica','salario': 1600000.0, 'fecha_contrato': '2020-03-01', 'activo': 1},
      {'id': 10, 'nombre': 'Nicolas',   'apellido': 'Sanchez',    'departamento_id': 5, 'cargo': 'Operador de Bodega',    'salario': 850000.0,  'fecha_contrato': '2021-07-19', 'activo': 1},
      {'id': 11, 'nombre': 'Daniela',   'apellido': 'Torres',     'departamento_id': 6, 'cargo': 'Disenadora Grafica',   'salario': 1400000.0, 'fecha_contrato': '2020-09-08', 'activo': 1},
      {'id': 12, 'nombre': 'Matias',    'apellido': 'Vargas',     'departamento_id': 6, 'cargo': 'Community Manager',    'salario': 1100000.0, 'fecha_contrato': '2022-02-14', 'activo': 1},
      {'id': 13, 'nombre': 'Antonia',   'apellido': 'Morales',    'departamento_id': 1, 'cargo': 'Ejecutivo de Ventas',   'salario': 1250000.0, 'fecha_contrato': '2021-05-25', 'activo': 1},
      {'id': 14, 'nombre': 'Cristobal', 'apellido': 'Espinoza',   'departamento_id': 2, 'cargo': 'Administrador de Sistemas','salario': 2800000.0,'fecha_contrato': '2015-11-03','activo': 1},
      {'id': 15, 'nombre': 'Isidora',   'apellido': 'Pinto',      'departamento_id': 4, 'cargo': 'Gerente de Finanzas',  'salario': 4500000.0, 'fecha_contrato': '2013-04-17', 'activo': 1},
      {'id': 16, 'nombre': 'Andres',    'apellido': 'Castro',     'departamento_id': 1, 'cargo': 'Gerente de Ventas',    'salario': 5000000.0, 'fecha_contrato': '2012-08-01', 'activo': 1},
      {'id': 17, 'nombre': 'Carla',     'apellido': 'Jimenez',    'departamento_id': 5, 'cargo': 'Chofer de Reparto',    'salario': 800000.0,  'fecha_contrato': '2023-01-09', 'activo': 1},
      {'id': 18, 'nombre': 'Pablo',     'apellido': 'Rios',       'departamento_id': 2, 'cargo': 'Desarrollador Junior', 'salario': 1300000.0, 'fecha_contrato': '2023-03-20', 'activo': 1},
      {'id': 19, 'nombre': 'Francisca', 'apellido': 'Gomez',      'departamento_id': 3, 'cargo': 'Psicologa Laboral',    'salario': 1950000.0, 'fecha_contrato': '2019-10-15', 'activo': 1},
      {'id': 20, 'nombre': 'Eduardo',   'apellido': 'Silva',      'departamento_id': 6, 'cargo': 'Gerente de Marketing', 'salario': 3800000.0, 'fecha_contrato': '2016-02-28', 'activo': 1},
      {'id': 21, 'nombre': 'Alejandra', 'apellido': 'Nunez',      'departamento_id': 1, 'cargo': 'Ejecutivo de Ventas',   'salario': 1150000.0, 'fecha_contrato': '2022-06-01', 'activo': 0},
      {'id': 22, 'nombre': 'Ricardo',   'apellido': 'Flores',     'departamento_id': 5, 'cargo': 'Jefe de Logistica',    'salario': 2900000.0, 'fecha_contrato': '2014-12-10', 'activo': 1},
      {'id': 23, 'nombre': 'Monica',    'apellido': 'Gutierrez',  'departamento_id': 4, 'cargo': 'Auditora Interna',     'salario': 2400000.0, 'fecha_contrato': '2018-03-05', 'activo': 1},
      {'id': 24, 'nombre': 'Jorge',     'apellido': 'Ramos',      'departamento_id': 2, 'cargo': 'Arquitecto de Software','salario': 3200000.0,'fecha_contrato': '2017-09-18', 'activo': 1},
      {'id': 25, 'nombre': 'Loreto',    'apellido': 'Vega',       'departamento_id': 6, 'cargo': 'Analista de Marketing','salario': 1350000.0, 'fecha_contrato': '2021-11-22', 'activo': 1},
    ];
    for (final e in emps) {
      batch.insert('empleados', e, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // ── productos (30) ────────────────────────
    final List<Map<String, dynamic>> prods = [
      {'id': 1,  'codigo': 'FERT-001', 'nombre': 'Urea 46%',                      'categoria': 'Fertilizante', 'precio': 18500.0,  'stock': 500},
      {'id': 2,  'codigo': 'FERT-002', 'nombre': 'Nitrato de Amonio',              'categoria': 'Fertilizante', 'precio': 22000.0,  'stock': 350},
      {'id': 3,  'codigo': 'FERT-003', 'nombre': 'Superfosfato Triple',            'categoria': 'Fertilizante', 'precio': 27500.0,  'stock': 280},
      {'id': 4,  'codigo': 'FERT-004', 'nombre': 'Sulfato de Potasio',             'categoria': 'Fertilizante', 'precio': 32000.0,  'stock': 210},
      {'id': 5,  'codigo': 'FERT-005', 'nombre': 'NPK 15-15-15',                  'categoria': 'Fertilizante', 'precio': 24500.0,  'stock': 420},
      {'id': 6,  'codigo': 'FERT-006', 'nombre': 'Sulfato de Zinc',               'categoria': 'Fertilizante', 'precio': 15000.0,  'stock': 180},
      {'id': 7,  'codigo': 'SEM-001',  'nombre': 'Semilla Trigo Invernal',         'categoria': 'Semilla',      'precio': 8500.0,   'stock': 1200},
      {'id': 8,  'codigo': 'SEM-002',  'nombre': 'Semilla Maiz Hibrido',           'categoria': 'Semilla',      'precio': 45000.0,  'stock': 600},
      {'id': 9,  'codigo': 'SEM-003',  'nombre': 'Semilla Raps Canola',            'categoria': 'Semilla',      'precio': 12000.0,  'stock': 800},
      {'id': 10, 'codigo': 'SEM-004',  'nombre': 'Semilla Avena Blanquita',        'categoria': 'Semilla',      'precio': 6500.0,   'stock': 950},
      {'id': 11, 'codigo': 'SEM-005',  'nombre': 'Semilla Papa Desiree',           'categoria': 'Semilla',      'precio': 9800.0,   'stock': 700},
      {'id': 12, 'codigo': 'PEST-001', 'nombre': 'Glifosato 48% SL',              'categoria': 'Herbicida',    'precio': 7200.0,   'stock': 850},
      {'id': 13, 'codigo': 'PEST-002', 'nombre': 'Mancozeb 80% WP',               'categoria': 'Fungicida',    'precio': 11500.0,  'stock': 430},
      {'id': 14, 'codigo': 'PEST-003', 'nombre': 'Clorpirifos 48% EC',            'categoria': 'Insecticida',  'precio': 14200.0,  'stock': 310},
      {'id': 15, 'codigo': 'PEST-004', 'nombre': 'Atrazina 50% SC',               'categoria': 'Herbicida',    'precio': 9600.0,   'stock': 520},
      {'id': 16, 'codigo': 'PEST-005', 'nombre': 'Propiconazol 25% EC',           'categoria': 'Fungicida',    'precio': 18700.0,  'stock': 260},
      {'id': 17, 'codigo': 'PEST-006', 'nombre': 'Imidacloprid 35% SC',           'categoria': 'Insecticida',  'precio': 22000.0,  'stock': 190},
      {'id': 18, 'codigo': 'PEST-007', 'nombre': 'Fluazinam 50% SC',              'categoria': 'Fungicida',    'precio': 31500.0,  'stock': 140},
      {'id': 19, 'codigo': 'RIEGO-001','nombre': 'Cinta de Riego Goteo 16mm',     'categoria': 'Riego',        'precio': 3200.0,   'stock': 2000},
      {'id': 20, 'codigo': 'RIEGO-002','nombre': 'Aspersor de Impacto 1/2"',      'categoria': 'Riego',        'precio': 4800.0,   'stock': 750},
      {'id': 21, 'codigo': 'FERT-007', 'nombre': 'Acido Humico Liquido',          'categoria': 'Bioestimulante','precio': 28000.0, 'stock': 320},
      {'id': 22, 'codigo': 'FERT-008', 'nombre': 'Alga Marina Concentrado',       'categoria': 'Bioestimulante','precio': 35000.0, 'stock': 210},
      {'id': 23, 'codigo': 'SEM-006',  'nombre': 'Semilla Cebada Cervecera',      'categoria': 'Semilla',      'precio': 7800.0,   'stock': 880},
      {'id': 24, 'codigo': 'PEST-008', 'nombre': 'Metribuzin 70% WP',             'categoria': 'Herbicida',    'precio': 16500.0,  'stock': 290},
      {'id': 25, 'codigo': 'FERT-009', 'nombre': 'Calcio Boro Foliar',            'categoria': 'Fertilizante', 'precio': 19800.0,  'stock': 370},
      {'id': 26, 'codigo': 'RIEGO-003','nombre': 'Filtro Disco 2" 120 Mesh',      'categoria': 'Riego',        'precio': 38000.0,  'stock': 95},
      {'id': 27, 'codigo': 'PEST-009', 'nombre': 'Azoxistrobina 25% SC',          'categoria': 'Fungicida',    'precio': 42000.0,  'stock': 160},
      {'id': 28, 'codigo': 'SEM-007',  'nombre': 'Semilla Girasol Alto Oleico',   'categoria': 'Semilla',      'precio': 16000.0,  'stock': 540},
      {'id': 29, 'codigo': 'FERT-010', 'nombre': 'Magnesio EDTA Quelatado',       'categoria': 'Fertilizante', 'precio': 23500.0,  'stock': 250},
      {'id': 30, 'codigo': 'PEST-010', 'nombre': 'Abamectina 1.8% EC',            'categoria': 'Insecticida',  'precio': 26000.0,  'stock': 175},
    ];
    for (final p in prods) {
      batch.insert('productos', p, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // ── proveedores (10) ──────────────────────
    final List<Map<String, dynamic>> provs = [
      {'id': 1,  'nombre': 'Anasac Chile S.A.',          'rut': '76.075.832-4', 'ciudad': 'Santiago'},
      {'id': 2,  'nombre': 'Coagra S.A.',                 'rut': '79.521.460-1', 'ciudad': 'Santiago'},
      {'id': 3,  'nombre': 'Basf Chile Ltda.',            'rut': '96.553.400-K', 'ciudad': 'Santiago'},
      {'id': 4,  'nombre': 'Bayer CropScience S.A.',      'rut': '96.613.560-1', 'ciudad': 'Santiago'},
      {'id': 5,  'nombre': 'Syngenta Chile S.A.',         'rut': '76.341.520-7', 'ciudad': 'Santiago'},
      {'id': 6,  'nombre': 'Semillas Pioneer S.A.',       'rut': '82.730.400-2', 'ciudad': 'Los Angeles'},
      {'id': 7,  'nombre': 'Fertiberia Chile Ltda.',      'rut': '76.892.140-5', 'ciudad': 'Antofagasta'},
      {'id': 8,  'nombre': 'Netafim Chile S.A.',          'rut': '77.220.680-9', 'ciudad': 'Santiago'},
      {'id': 9,  'nombre': 'Compo Expert Chile Ltda.',    'rut': '76.431.900-3', 'ciudad': 'Concepcion'},
      {'id': 10, 'nombre': 'Corteva Agriscience Chile S.A.','rut':'76.950.220-8','ciudad': 'Santiago'},
    ];
    for (final pv in provs) {
      batch.insert('proveedores', pv, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // ── ventas (80) ───────────────────────────
    final List<Map<String, dynamic>> sales = [
      {'id': 1,  'fecha': '2023-01-10', 'empleado_id': 1,  'producto_id': 1,  'cantidad': 50, 'precio_unitario': 18500.0,  'total': 925000.0},
      {'id': 2,  'fecha': '2023-01-15', 'empleado_id': 2,  'producto_id': 7,  'cantidad': 100,'precio_unitario': 8500.0,   'total': 850000.0},
      {'id': 3,  'fecha': '2023-01-20', 'empleado_id': 13, 'producto_id': 12, 'cantidad': 80, 'precio_unitario': 7200.0,   'total': 576000.0},
      {'id': 4,  'fecha': '2023-02-03', 'empleado_id': 1,  'producto_id': 5,  'cantidad': 60, 'precio_unitario': 24500.0,  'total': 1470000.0},
      {'id': 5,  'fecha': '2023-02-14', 'empleado_id': 16, 'producto_id': 8,  'cantidad': 20, 'precio_unitario': 45000.0,  'total': 900000.0},
      {'id': 6,  'fecha': '2023-02-22', 'empleado_id': 2,  'producto_id': 3,  'cantidad': 45, 'precio_unitario': 27500.0,  'total': 1237500.0},
      {'id': 7,  'fecha': '2023-03-05', 'empleado_id': 13, 'producto_id': 14, 'cantidad': 30, 'precio_unitario': 14200.0,  'total': 426000.0},
      {'id': 8,  'fecha': '2023-03-18', 'empleado_id': 1,  'producto_id': 2,  'cantidad': 70, 'precio_unitario': 22000.0,  'total': 1540000.0},
      {'id': 9,  'fecha': '2023-03-25', 'empleado_id': 21, 'producto_id': 19, 'cantidad': 200,'precio_unitario': 3200.0,   'total': 640000.0},
      {'id': 10, 'fecha': '2023-04-04', 'empleado_id': 2,  'producto_id': 13, 'cantidad': 40, 'precio_unitario': 11500.0,  'total': 460000.0},
      {'id': 11, 'fecha': '2023-04-12', 'empleado_id': 16, 'producto_id': 15, 'cantidad': 55, 'precio_unitario': 9600.0,   'total': 528000.0},
      {'id': 12, 'fecha': '2023-04-20', 'empleado_id': 13, 'producto_id': 9,  'cantidad': 90, 'precio_unitario': 12000.0,  'total': 1080000.0},
      {'id': 13, 'fecha': '2023-05-06', 'empleado_id': 1,  'producto_id': 21, 'cantidad': 25, 'precio_unitario': 28000.0,  'total': 700000.0},
      {'id': 14, 'fecha': '2023-05-15', 'empleado_id': 2,  'producto_id': 4,  'cantidad': 35, 'precio_unitario': 32000.0,  'total': 1120000.0},
      {'id': 15, 'fecha': '2023-05-28', 'empleado_id': 21, 'producto_id': 25, 'cantidad': 28, 'precio_unitario': 19800.0,  'total': 554400.0},
      {'id': 16, 'fecha': '2023-06-08', 'empleado_id': 13, 'producto_id': 17, 'cantidad': 18, 'precio_unitario': 22000.0,  'total': 396000.0},
      {'id': 17, 'fecha': '2023-06-16', 'empleado_id': 16, 'producto_id': 7,  'cantidad': 150,'precio_unitario': 8500.0,   'total': 1275000.0},
      {'id': 18, 'fecha': '2023-06-24', 'empleado_id': 1,  'producto_id': 27, 'cantidad': 12, 'precio_unitario': 42000.0,  'total': 504000.0},
      {'id': 19, 'fecha': '2023-07-03', 'empleado_id': 2,  'producto_id': 10, 'cantidad': 120,'precio_unitario': 6500.0,   'total': 780000.0},
      {'id': 20, 'fecha': '2023-07-11', 'empleado_id': 13, 'producto_id': 22, 'cantidad': 15, 'precio_unitario': 35000.0,  'total': 525000.0},
      {'id': 21, 'fecha': '2023-07-22', 'empleado_id': 21, 'producto_id': 1,  'cantidad': 65, 'precio_unitario': 18500.0,  'total': 1202500.0},
      {'id': 22, 'fecha': '2023-08-02', 'empleado_id': 16, 'producto_id': 30, 'cantidad': 20, 'precio_unitario': 26000.0,  'total': 520000.0},
      {'id': 23, 'fecha': '2023-08-14', 'empleado_id': 1,  'producto_id': 11, 'cantidad': 80, 'precio_unitario': 9800.0,   'total': 784000.0},
      {'id': 24, 'fecha': '2023-08-25', 'empleado_id': 2,  'producto_id': 6,  'cantidad': 40, 'precio_unitario': 15000.0,  'total': 600000.0},
      {'id': 25, 'fecha': '2023-09-04', 'empleado_id': 13, 'producto_id': 16, 'cantidad': 22, 'precio_unitario': 18700.0,  'total': 411400.0},
      {'id': 26, 'fecha': '2023-09-13', 'empleado_id': 21, 'producto_id': 23, 'cantidad': 110,'precio_unitario': 7800.0,   'total': 858000.0},
      {'id': 27, 'fecha': '2023-09-25', 'empleado_id': 16, 'producto_id': 20, 'cantidad': 60, 'precio_unitario': 4800.0,   'total': 288000.0},
      {'id': 28, 'fecha': '2023-10-05', 'empleado_id': 1,  'producto_id': 24, 'cantidad': 30, 'precio_unitario': 16500.0,  'total': 495000.0},
      {'id': 29, 'fecha': '2023-10-17', 'empleado_id': 2,  'producto_id': 18, 'cantidad': 14, 'precio_unitario': 31500.0,  'total': 441000.0},
      {'id': 30, 'fecha': '2023-10-28', 'empleado_id': 13, 'producto_id': 28, 'cantidad': 75, 'precio_unitario': 16000.0,  'total': 1200000.0},
      {'id': 31, 'fecha': '2023-11-06', 'empleado_id': 16, 'producto_id': 5,  'cantidad': 50, 'precio_unitario': 24500.0,  'total': 1225000.0},
      {'id': 32, 'fecha': '2023-11-18', 'empleado_id': 21, 'producto_id': 12, 'cantidad': 90, 'precio_unitario': 7200.0,   'total': 648000.0},
      {'id': 33, 'fecha': '2023-11-29', 'empleado_id': 1,  'producto_id': 29, 'cantidad': 18, 'precio_unitario': 23500.0,  'total': 423000.0},
      {'id': 34, 'fecha': '2023-12-08', 'empleado_id': 2,  'producto_id': 26, 'cantidad': 8,  'precio_unitario': 38000.0,  'total': 304000.0},
      {'id': 35, 'fecha': '2023-12-20', 'empleado_id': 13, 'producto_id': 2,  'cantidad': 55, 'precio_unitario': 22000.0,  'total': 1210000.0},
      {'id': 36, 'fecha': '2024-01-08', 'empleado_id': 16, 'producto_id': 8,  'cantidad': 25, 'precio_unitario': 45000.0,  'total': 1125000.0},
      {'id': 37, 'fecha': '2024-01-17', 'empleado_id': 1,  'producto_id': 14, 'cantidad': 38, 'precio_unitario': 14200.0,  'total': 539600.0},
      {'id': 38, 'fecha': '2024-01-26', 'empleado_id': 2,  'producto_id': 3,  'cantidad': 48, 'precio_unitario': 27500.0,  'total': 1320000.0},
      {'id': 39, 'fecha': '2024-02-05', 'empleado_id': 13, 'producto_id': 7,  'cantidad': 130,'precio_unitario': 8500.0,   'total': 1105000.0},
      {'id': 40, 'fecha': '2024-02-15', 'empleado_id': 21, 'producto_id': 1,  'cantidad': 72, 'precio_unitario': 18500.0,  'total': 1332000.0},
      {'id': 41, 'fecha': '2024-02-24', 'empleado_id': 16, 'producto_id': 15, 'cantidad': 62, 'precio_unitario': 9600.0,   'total': 595200.0},
      {'id': 42, 'fecha': '2024-03-04', 'empleado_id': 1,  'producto_id': 13, 'cantidad': 44, 'precio_unitario': 11500.0,  'total': 506000.0},
      {'id': 43, 'fecha': '2024-03-15', 'empleado_id': 2,  'producto_id': 21, 'cantidad': 30, 'precio_unitario': 28000.0,  'total': 840000.0},
      {'id': 44, 'fecha': '2024-03-25', 'empleado_id': 13, 'producto_id': 10, 'cantidad': 95, 'precio_unitario': 6500.0,   'total': 617500.0},
      {'id': 45, 'fecha': '2024-04-03', 'empleado_id': 16, 'producto_id': 4,  'cantidad': 40, 'precio_unitario': 32000.0,  'total': 1280000.0},
      {'id': 46, 'fecha': '2024-04-12', 'empleado_id': 21, 'producto_id': 17, 'cantidad': 22, 'precio_unitario': 22000.0,  'total': 484000.0},
      {'id': 47, 'fecha': '2024-04-22', 'empleado_id': 1,  'producto_id': 27, 'cantidad': 15, 'precio_unitario': 42000.0,  'total': 630000.0},
      {'id': 48, 'fecha': '2024-05-02', 'empleado_id': 2,  'producto_id': 9,  'cantidad': 100,'precio_unitario': 12000.0,  'total': 1200000.0},
      {'id': 49, 'fecha': '2024-05-13', 'empleado_id': 13, 'producto_id': 6,  'cantidad': 45, 'precio_unitario': 15000.0,  'total': 675000.0},
      {'id': 50, 'fecha': '2024-05-23', 'empleado_id': 16, 'producto_id': 22, 'cantidad': 18, 'precio_unitario': 35000.0,  'total': 630000.0},
      {'id': 51, 'fecha': '2024-06-03', 'empleado_id': 21, 'producto_id': 5,  'cantidad': 58, 'precio_unitario': 24500.0,  'total': 1421000.0},
      {'id': 52, 'fecha': '2024-06-14', 'empleado_id': 1,  'producto_id': 30, 'cantidad': 24, 'precio_unitario': 26000.0,  'total': 624000.0},
      {'id': 53, 'fecha': '2024-06-24', 'empleado_id': 2,  'producto_id': 11, 'cantidad': 85, 'precio_unitario': 9800.0,   'total': 833000.0},
      {'id': 54, 'fecha': '2024-07-04', 'empleado_id': 13, 'producto_id': 24, 'cantidad': 32, 'precio_unitario': 16500.0,  'total': 528000.0},
      {'id': 55, 'fecha': '2024-07-15', 'empleado_id': 16, 'producto_id': 18, 'cantidad': 16, 'precio_unitario': 31500.0,  'total': 504000.0},
      {'id': 56, 'fecha': '2024-07-25', 'empleado_id': 21, 'producto_id': 2,  'cantidad': 68, 'precio_unitario': 22000.0,  'total': 1496000.0},
      {'id': 57, 'fecha': '2024-08-05', 'empleado_id': 1,  'producto_id': 19, 'cantidad': 180,'precio_unitario': 3200.0,   'total': 576000.0},
      {'id': 58, 'fecha': '2024-08-16', 'empleado_id': 2,  'producto_id': 25, 'cantidad': 35, 'precio_unitario': 19800.0,  'total': 693000.0},
      {'id': 59, 'fecha': '2024-08-26', 'empleado_id': 13, 'producto_id': 16, 'cantidad': 26, 'precio_unitario': 18700.0,  'total': 486200.0},
      {'id': 60, 'fecha': '2024-09-05', 'empleado_id': 16, 'producto_id': 23, 'cantidad': 120,'precio_unitario': 7800.0,   'total': 936000.0},
      {'id': 61, 'fecha': '2024-09-16', 'empleado_id': 21, 'producto_id': 28, 'cantidad': 80, 'precio_unitario': 16000.0,  'total': 1280000.0},
      {'id': 62, 'fecha': '2024-09-26', 'empleado_id': 1,  'producto_id': 29, 'cantidad': 20, 'precio_unitario': 23500.0,  'total': 470000.0},
      {'id': 63, 'fecha': '2024-10-07', 'empleado_id': 2,  'producto_id': 26, 'cantidad': 10, 'precio_unitario': 38000.0,  'total': 380000.0},
      {'id': 64, 'fecha': '2024-10-18', 'empleado_id': 13, 'producto_id': 20, 'cantidad': 70, 'precio_unitario': 4800.0,   'total': 336000.0},
      {'id': 65, 'fecha': '2024-10-28', 'empleado_id': 16, 'producto_id': 12, 'cantidad': 95, 'precio_unitario': 7200.0,   'total': 684000.0},
      {'id': 66, 'fecha': '2024-11-07', 'empleado_id': 21, 'producto_id': 3,  'cantidad': 52, 'precio_unitario': 27500.0,  'total': 1430000.0},
      {'id': 67, 'fecha': '2024-11-18', 'empleado_id': 1,  'producto_id': 8,  'cantidad': 30, 'precio_unitario': 45000.0,  'total': 1350000.0},
      {'id': 68, 'fecha': '2024-11-28', 'empleado_id': 2,  'producto_id': 7,  'cantidad': 140,'precio_unitario': 8500.0,   'total': 1190000.0},
      {'id': 69, 'fecha': '2024-12-06', 'empleado_id': 13, 'producto_id': 1,  'cantidad': 60, 'precio_unitario': 18500.0,  'total': 1110000.0},
      {'id': 70, 'fecha': '2024-12-17', 'empleado_id': 16, 'producto_id': 5,  'cantidad': 55, 'precio_unitario': 24500.0,  'total': 1347500.0},
      {'id': 71, 'fecha': '2023-03-10', 'empleado_id': 2,  'producto_id': 15, 'cantidad': 48, 'precio_unitario': 9600.0,   'total': 460800.0},
      {'id': 72, 'fecha': '2023-05-20', 'empleado_id': 1,  'producto_id': 22, 'cantidad': 12, 'precio_unitario': 35000.0,  'total': 420000.0},
      {'id': 73, 'fecha': '2023-07-30', 'empleado_id': 13, 'producto_id': 17, 'cantidad': 20, 'precio_unitario': 22000.0,  'total': 440000.0},
      {'id': 74, 'fecha': '2023-09-08', 'empleado_id': 16, 'producto_id': 27, 'cantidad': 10, 'precio_unitario': 42000.0,  'total': 420000.0},
      {'id': 75, 'fecha': '2023-11-02', 'empleado_id': 21, 'producto_id': 30, 'cantidad': 18, 'precio_unitario': 26000.0,  'total': 468000.0},
      {'id': 76, 'fecha': '2024-01-30', 'empleado_id': 2,  'producto_id': 6,  'cantidad': 50, 'precio_unitario': 15000.0,  'total': 750000.0},
      {'id': 77, 'fecha': '2024-04-08', 'empleado_id': 1,  'producto_id': 29, 'cantidad': 22, 'precio_unitario': 23500.0,  'total': 517000.0},
      {'id': 78, 'fecha': '2024-06-30', 'empleado_id': 13, 'producto_id': 26, 'cantidad': 7,  'precio_unitario': 38000.0,  'total': 266000.0},
      {'id': 79, 'fecha': '2024-09-01', 'empleado_id': 16, 'producto_id': 18, 'cantidad': 12, 'precio_unitario': 31500.0,  'total': 378000.0},
      {'id': 80, 'fecha': '2024-11-10', 'empleado_id': 21, 'producto_id': 4,  'cantidad': 38, 'precio_unitario': 32000.0,  'total': 1216000.0},
    ];
    for (final s in sales) {
      batch.insert('ventas', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }

  // ── executeQuery ───────────────────────────

  Future<Map<String, dynamic>> executeQuery(String sql) async {
    final trimmed = sql.trim();
    final upperFirst = trimmed.split(RegExp(r'\s+')).first.toUpperCase();

    if (upperFirst != 'SELECT') {
      return {
        'success': false,
        'columns': <String>[],
        'rows': <List<dynamic>>[],
        'rowCount': 0,
        'executionMs': 0,
        'error': upperFirst == 'DROP' || upperFirst == 'DELETE' || upperFirst == 'UPDATE' || upperFirst == 'INSERT' || upperFirst == 'ALTER' || upperFirst == 'CREATE'
            ? 'Solo se permiten consultas SELECT en el sandbox. Las operaciones de modificacion ($upperFirst) no estan permitidas para proteger los datos de practica.'
            : 'Solo se permiten consultas SELECT en el sandbox.',
      };
    }

    await initialize();
    final db = await _database;
    final stopwatch = Stopwatch()..start();

    try {
      final results = await db.rawQuery(trimmed);
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
      final rows = results
          .map((row) => columns.map((col) => row[col]).toList())
          .toList();

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
      String msg = e.toString();
      // Strip "DatabaseException(" wrapper for cleaner display
      if (msg.startsWith('DatabaseException(') && msg.endsWith(')')) {
        msg = msg.substring('DatabaseException('.length, msg.length - 1);
      }
      return {
        'success': false,
        'columns': <String>[],
        'rows': <List<dynamic>>[],
        'rowCount': 0,
        'executionMs': stopwatch.elapsedMilliseconds,
        'error': msg,
      };
    }
  }

  // ── getTableSchemas ────────────────────────

  Future<Map<String, List<Map<String, dynamic>>>> getTableSchemas() async {
    await initialize();
    final db = await _database;
    const tables = ['empleados', 'departamentos', 'productos', 'ventas', 'proveedores'];
    final Map<String, List<Map<String, dynamic>>> schemas = {};

    for (final table in tables) {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      schemas[table] = info
          .map((col) => {
                'cid': col['cid'],
                'name': col['name'],
                'type': col['type'],
                'notnull': col['notnull'],
                'dflt_value': col['dflt_value'],
                'pk': col['pk'],
              })
          .toList();
    }

    return schemas;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
      _initialized = false;
    }
  }
}