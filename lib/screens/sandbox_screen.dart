import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../services/progress_service.dart';

class SandboxScreen extends StatefulWidget {
  final AppState state;
  const SandboxScreen({super.key, required this.state});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final TextEditingController _sqlController = TextEditingController();
  final SandboxService _sandboxService = SandboxService();

  List<String> _columnNames = [];
  List<List<dynamic>> _rows = [];
  String? _error;
  bool _isExecuting = false;
  int _executionMs = 0;

  static const List<Map<String, String>> _exampleQueries = [
    {'label': 'SELECT básico', 'sql': 'SELECT * FROM empleados LIMIT 10;'},
    {'label': 'JOIN empleados', 'sql': 'SELECT e.nombre, d.nombre AS depto\nFROM empleados e\nINNER JOIN departamentos d ON e.departamento_id = d.id;'},
    {'label': 'GROUP BY depto', 'sql': 'SELECT d.nombre, COUNT(*) AS total, AVG(e.salario) AS salario_prom\nFROM empleados e\nJOIN departamentos d ON e.departamento_id = d.id\nGROUP BY d.nombre\nORDER BY total DESC;'},
    {'label': 'Ventas 2024', 'sql': "SELECT fecha, SUM(total) AS total_dia\nFROM ventas\nWHERE fecha LIKE '2024%'\nGROUP BY fecha\nORDER BY fecha;"},
    {'label': 'Top 5 productos', 'sql': 'SELECT nombre, precio, stock\nFROM productos\nORDER BY precio DESC\nLIMIT 5;'},
    {'label': 'CTE ejemplo', 'sql': 'WITH ventas_por_emp AS (\n  SELECT empleado_id, SUM(total) AS total\n  FROM ventas\n  GROUP BY empleado_id\n)\nSELECT e.nombre, v.total\nFROM ventas_por_emp v\nJOIN empleados e ON v.empleado_id = e.id\nORDER BY v.total DESC;'},
  ];

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  // ─── Execute ───────────────────────────────────────────────────────────────

  Future<void> _executeQuery() async {
    final query = _sqlController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isExecuting = true;
      _error = null;
      _columnNames = [];
      _rows = [];
    });

    try {
      final result = await _sandboxService.executeQuery(query);
      setState(() {
        if (result['success'] == true) {
          _columnNames = List<String>.from(result['columns'] as List);
          _rows = List<List<dynamic>>.from(
              (result['rows'] as List).map((r) => List<dynamic>.from(r as List)));
          _executionMs = result['executionMs'] as int? ?? 0;
        } else {
          _error = result['error'] as String? ?? 'Error desconocido';
        }
        _isExecuting = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExecuting = false;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _sqlController.clear();
      _error = null;
      _columnNames = [];
      _rows = [];
    });
  }

  // ─── Bottom sheet: schemas ─────────────────────────────────────────────────

  void _showSchemas() async {
    final schemas = await _sandboxService.getTableSchemas();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.95,
          minChildSize: 0.35,
          expand: false,
          builder: (_, sc) => SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Esquemas de tablas',
                    style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Tablas disponibles en el Sandbox SQLite',
                    style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                ...schemas.entries.map((entry) => Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(children: [
                              const Text('🗄️', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(entry.key,
                                  style: GoogleFonts.nunito(
                                      color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.w800)),
                            ]),
                          ),
                          ...entry.value.map((col) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                child: Row(children: [
                                  Expanded(
                                      child: Text(col['name']?.toString() ?? '',
                                          style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13))),
                                  Text(col['type']?.toString() ?? '',
                                      style: GoogleFonts.robotoMono(
                                          color: Colors.amber.shade300, fontSize: 12)),
                                ]),
                              )),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Builders ─────────────────────────────────────────────────────────────

  Widget _buildEditor() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Editor SQL',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
          const SizedBox(height: 10),
          TextField(
            controller: _sqlController,
            style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'SELECT * FROM empleados LIMIT 10;',
              hintStyle: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white24)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.cyanAccent, width: 2)),
              contentPadding: const EdgeInsets.all(14),
            ),
            maxLines: null,
            minLines: 6,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text('Ejecutar',
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800)),
              onPressed: _isExecuting ? null : _executeQuery,
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _clearAll,
              child: Text('Limpiar',
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isExecuting) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2),
            const SizedBox(height: 12),
            Text('Ejecutando query...',
                style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      );
    }

    if (_error != null) return _buildError(_error!);
    if (_columnNames.isNotEmpty) return _buildTable();

    return SizedBox(
      height: 180,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📋', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text('Los resultados aparecerán aquí',
              style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Escribe una query y presiona Ejecutar',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                '${_rows.length} fila${_rows.length == 1 ? '' : 's'} · ${_executionMs}ms',
                style: GoogleFonts.nunito(
                    color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
        SizedBox(
          height: 260,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.cyanAccent.withOpacity(0.1)),
                border: TableBorder.all(
                    color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                columnSpacing: 20,
                horizontalMargin: 14,
                headingRowHeight: 40,
                dataRowMaxHeight: 40,
                columns: _columnNames
                    .map((col) => DataColumn(
                          label: Text(col,
                              style: GoogleFonts.nunito(
                                  color: Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ))
                    .toList(),
                rows: _rows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.all(
                        idx.isEven ? AppColors.surface : AppColors.background),
                    cells: row
                        .map((cell) => DataCell(Text(
                              cell?.toString() ?? 'NULL',
                              style: GoogleFonts.robotoMono(
                                color: cell == null ? Colors.white30 : Colors.white70,
                                fontSize: 12,
                              ),
                            )))
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Text('Error en la query',
              style: GoogleFonts.nunito(
                  color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(error,
              style: GoogleFonts.robotoMono(
                  color: Colors.red.shade300, fontSize: 12, height: 1.5)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Revisa la sintaxis, los nombres de tablas y columnas disponibles.',
                style: GoogleFonts.nunito(
                    color: Colors.amber.shade300, fontSize: 12, height: 1.5)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildExamples() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('Ejemplos rápidos',
              style: GoogleFonts.nunito(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _exampleQueries.map((e) {
            return ActionChip(
              label: Text(e['label']!,
                  style: GoogleFonts.nunito(
                      color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600)),
              backgroundColor: Colors.cyanAccent.withOpacity(0.08),
              side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
              onPressed: () => setState(() => _sqlController.text = e['sql']!),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('Sandbox SQL',
              style: GoogleFonts.nunito(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              icon: const Icon(Icons.table_chart_outlined, color: Colors.cyanAccent),
              tooltip: 'Ver esquemas de tablas',
              onPressed: _showSchemas,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditor(),
              const SizedBox(height: 12),
              _buildResults(),
              _buildExamples(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
