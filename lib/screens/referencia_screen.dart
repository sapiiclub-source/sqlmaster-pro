import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../state/app_state.dart';

class ReferenciaScreen extends StatefulWidget {
  final AppState state;
  const ReferenciaScreen({Key? key, required this.state}) : super(key: key);

  @override
  State<ReferenciaScreen> createState() => _ReferenciaScreenState();
}

class _ReferenciaScreenState extends State<ReferenciaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _tabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Copiado!', style: GoogleFonts.inter()),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              code,
              style: GoogleFonts.firaCode(
                color: const Color(0xFF79C0FF),
                fontSize: 13,
              ),
            ),
          ),
          InkWell(
            onTap: () => _copyToClipboard(code),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1 DATA
  // ─────────────────────────────────────────────
  List<Map<String, String>> get _commands => [
    {
      'name': 'SELECT',
      'desc': 'Selecciona columnas de una tabla',
      'syntax': 'SELECT columna1, columna2\nFROM tabla;',
      'example': 'SELECT nombre, edad\nFROM clientes;',
      'detail': 'Recupera datos de una o más columnas. Usa * para todas las columnas.',
    },
    {
      'name': 'FROM',
      'desc': 'Especifica la tabla origen de los datos',
      'syntax': 'SELECT ...\nFROM nombre_tabla;',
      'example': 'SELECT *\nFROM empleados;',
      'detail': 'Define la tabla (o vistas/subconsultas) de la que se extraen los datos.',
    },
    {
      'name': 'WHERE',
      'desc': 'Filtra filas según una condición',
      'syntax': 'SELECT ...\nFROM tabla\nWHERE condicion;',
      'example': 'SELECT *\nFROM clientes\nWHERE ciudad = \'Lima\';',
      'detail': 'Aplica filtros antes de cualquier agrupación. Opera fila por fila.',
    },
    {
      'name': 'AND / OR / NOT',
      'desc': 'Operadores lógicos para combinar condiciones',
      'syntax': 'WHERE cond1 AND cond2\nWHERE cond1 OR cond2\nWHERE NOT cond1',
      'example': 'SELECT * FROM pedidos\nWHERE estado = \'activo\'\n  AND monto > 100;',
      'detail': 'AND requiere que ambas condiciones sean verdaderas. OR requiere al menos una. NOT invierte la condición.',
    },
    {
      'name': 'ORDER BY',
      'desc': 'Ordena el resultado por una o más columnas',
      'syntax': 'SELECT ...\nFROM tabla\nORDER BY col1 [ASC|DESC];',
      'example': 'SELECT nombre, salario\nFROM empleados\nORDER BY salario DESC;',
      'detail': 'ASC es el orden por defecto (ascendente). Puede ordenar por múltiples columnas separadas por coma.',
    },
    {
      'name': 'GROUP BY',
      'desc': 'Agrupa filas con el mismo valor en columnas',
      'syntax': 'SELECT col, AGG(col2)\nFROM tabla\nGROUP BY col;',
      'example': 'SELECT departamento, COUNT(*)\nFROM empleados\nGROUP BY departamento;',
      'detail': 'Se usa con funciones de agregación (COUNT, SUM, AVG, MAX, MIN).',
    },
    {
      'name': 'HAVING',
      'desc': 'Filtra grupos después de GROUP BY',
      'syntax': 'SELECT col, AGG(col2)\nFROM tabla\nGROUP BY col\nHAVING condicion;',
      'example': 'SELECT depto, SUM(salario)\nFROM empleados\nGROUP BY depto\nHAVING SUM(salario) > 50000;',
      'detail': 'A diferencia de WHERE, HAVING filtra después de agrupar. Permite condiciones sobre agregados.',
    },
    {
      'name': 'DISTINCT',
      'desc': 'Elimina filas duplicadas del resultado',
      'syntax': 'SELECT DISTINCT columna\nFROM tabla;',
      'example': 'SELECT DISTINCT ciudad\nFROM clientes;',
      'detail': 'Retorna solo valores únicos. Puede aplicarse a múltiples columnas (combinación única).',
    },
    {
      'name': 'TOP / LIMIT / ROWNUM',
      'desc': 'Limita el número de filas retornadas',
      'syntax': '-- SQL Server:\nSELECT TOP N ...\n-- MySQL/PG:\nSELECT ... LIMIT N\n-- Oracle:\nWHERE ROWNUM <= N',
      'example': '-- SQL Server:\nSELECT TOP 10 * FROM ventas\nORDER BY fecha DESC;',
      'detail': 'Cada motor de BD tiene su propia sintaxis para limitar filas.',
    },
    {
      'name': 'INNER JOIN',
      'desc': 'Combina filas con coincidencia en ambas tablas',
      'syntax': 'SELECT ...\nFROM a\nINNER JOIN b ON a.id = b.id;',
      'example': 'SELECT p.nombre, c.ciudad\nFROM pedidos p\nINNER JOIN clientes c\n  ON p.cliente_id = c.id;',
      'detail': 'Solo incluye filas donde existe coincidencia en ambas tablas. Es el JOIN más común.',
    },
    {
      'name': 'LEFT JOIN',
      'desc': 'Retorna todas las filas de la tabla izquierda',
      'syntax': 'SELECT ...\nFROM a\nLEFT JOIN b ON a.id = b.id;',
      'example': 'SELECT c.nombre, p.total\nFROM clientes c\nLEFT JOIN pedidos p\n  ON c.id = p.cliente_id;',
      'detail': 'Incluye todas las filas de la tabla izquierda aunque no haya coincidencia en la derecha (NULL).',
    },
    {
      'name': 'RIGHT JOIN',
      'desc': 'Retorna todas las filas de la tabla derecha',
      'syntax': 'SELECT ...\nFROM a\nRIGHT JOIN b ON a.id = b.id;',
      'example': 'SELECT e.nombre, d.nombre\nFROM empleados e\nRIGHT JOIN departamentos d\n  ON e.depto_id = d.id;',
      'detail': 'Incluye todas las filas de la tabla derecha aunque no haya coincidencia en la izquierda.',
    },
    {
      'name': 'FULL OUTER JOIN',
      'desc': 'Retorna filas de ambas tablas, con NULL donde no hay coincidencia',
      'syntax': 'SELECT ...\nFROM a\nFULL OUTER JOIN b ON a.id = b.id;',
      'example': 'SELECT a.id, b.id\nFROM tabla_a a\nFULL OUTER JOIN tabla_b b\n  ON a.id = b.id;',
      'detail': 'Combina LEFT y RIGHT JOIN. Filas sin coincidencia muestran NULL en las columnas del otro lado.',
    },
    {
      'name': 'UNION / UNION ALL',
      'desc': 'Combina resultados de dos consultas',
      'syntax': 'SELECT col FROM a\nUNION\nSELECT col FROM b;',
      'example': 'SELECT nombre FROM clientes_activos\nUNION ALL\nSELECT nombre FROM clientes_inactivos;',
      'detail': 'UNION elimina duplicados; UNION ALL los conserva (más rápido). Requiere mismo número y tipo de columnas.',
    },
    {
      'name': 'INSERT INTO',
      'desc': 'Inserta nuevas filas en una tabla',
      'syntax': 'INSERT INTO tabla (col1, col2)\nVALUES (val1, val2);',
      'example': 'INSERT INTO empleados (nombre, salario)\nVALUES (\'Ana García\', 35000);',
      'detail': 'Se pueden insertar múltiples filas con varios VALUES o mediante una subconsulta SELECT.',
    },
    {
      'name': 'UPDATE SET',
      'desc': 'Modifica valores en filas existentes',
      'syntax': 'UPDATE tabla\nSET col1 = val1\nWHERE condicion;',
      'example': 'UPDATE empleados\nSET salario = salario * 1.10\nWHERE depto = \'Ventas\';',
      'detail': 'Sin WHERE actualiza TODAS las filas. Siempre verificar con SELECT antes de ejecutar.',
    },
    {
      'name': 'DELETE FROM',
      'desc': 'Elimina filas de una tabla',
      'syntax': 'DELETE FROM tabla\nWHERE condicion;',
      'example': 'DELETE FROM pedidos\nWHERE estado = \'cancelado\'\n  AND fecha < \'2023-01-01\';',
      'detail': 'Sin WHERE elimina TODAS las filas. Usar TRUNCATE para eliminar todo más eficientemente.',
    },
    {
      'name': 'CREATE TABLE',
      'desc': 'Crea una nueva tabla en la base de datos',
      'syntax': 'CREATE TABLE nombre (\n  col1 TIPO CONSTRAINT,\n  col2 TIPO\n);',
      'example': 'CREATE TABLE productos (\n  id INT PRIMARY KEY,\n  nombre VARCHAR(100) NOT NULL,\n  precio DECIMAL(10,2)\n);',
      'detail': 'Define la estructura (esquema) de una tabla con sus columnas, tipos y restricciones.',
    },
    {
      'name': 'ALTER TABLE',
      'desc': 'Modifica la estructura de una tabla existente',
      'syntax': 'ALTER TABLE tabla\nADD columna TIPO;\nALTER TABLE tabla\nDROP COLUMN columna;',
      'example': 'ALTER TABLE clientes\nADD email VARCHAR(200);\n\nALTER TABLE clientes\nALTER COLUMN telefono VARCHAR(20);',
      'detail': 'Permite agregar, eliminar o modificar columnas y restricciones sin recrear la tabla.',
    },
    {
      'name': 'DROP TABLE',
      'desc': 'Elimina una tabla completa de la base de datos',
      'syntax': 'DROP TABLE nombre_tabla;',
      'example': 'DROP TABLE IF EXISTS temp_ventas;',
      'detail': 'Elimina la tabla y TODOS sus datos permanentemente. Acción irreversible en la mayoría de SGBD.',
    },
    {
      'name': 'WITH (CTE)',
      'desc': 'Define una tabla temporal con nombre (Common Table Expression)',
      'syntax': 'WITH cte AS (\n  SELECT ...\n)\nSELECT * FROM cte;',
      'example': 'WITH ventas_top AS (\n  SELECT vendedor, SUM(total) AS total\n  FROM ventas\n  GROUP BY vendedor\n)\nSELECT * FROM ventas_top\nWHERE total > 100000;',
      'detail': 'Mejora la legibilidad. Puede ser recursivo (WITH RECURSIVE) para jerarquías.',
    },
    {
      'name': 'CASE WHEN',
      'desc': 'Expresión condicional similar a if/else',
      'syntax': 'CASE\n  WHEN cond1 THEN val1\n  WHEN cond2 THEN val2\n  ELSE val_default\nEND',
      'example': 'SELECT nombre,\n  CASE\n    WHEN salario > 50000 THEN \'Alto\'\n    WHEN salario > 30000 THEN \'Medio\'\n    ELSE \'Bajo\'\n  END AS nivel\nFROM empleados;',
      'detail': 'Puede usarse en SELECT, WHERE, ORDER BY y GROUP BY. ELSE es opcional (retorna NULL si no hay match).',
    },
    {
      'name': 'ROW_NUMBER()',
      'desc': 'Asigna número de fila único dentro de una partición',
      'syntax': 'ROW_NUMBER() OVER\n  (PARTITION BY col\n   ORDER BY col2)',
      'example': 'SELECT nombre,\n  ROW_NUMBER() OVER\n    (PARTITION BY depto\n     ORDER BY salario DESC) AS rn\nFROM empleados;',
      'detail': 'Función de ventana. Numera desde 1 sin empates. Ideal para obtener el top-N por grupo.',
    },
    {
      'name': 'RANK() / DENSE_RANK()',
      'desc': 'Asigna rango con/sin saltos en empates',
      'syntax': 'RANK() OVER (ORDER BY col)\nDENSE_RANK() OVER (ORDER BY col)',
      'example': 'SELECT nombre, salario,\n  RANK() OVER (ORDER BY salario DESC) AS rank,\n  DENSE_RANK() OVER (ORDER BY salario DESC) AS drank\nFROM empleados;',
      'detail': 'RANK salta números en empate (1,2,2,4). DENSE_RANK no salta (1,2,2,3).',
    },
    {
      'name': 'PARTITION BY',
      'desc': 'Divide el conjunto de datos para funciones de ventana',
      'syntax': 'FUNCION() OVER\n  (PARTITION BY col\n   ORDER BY col2)',
      'example': 'SELECT depto,\n  nombre,\n  AVG(salario) OVER\n    (PARTITION BY depto) AS avg_depto\nFROM empleados;',
      'detail': 'No reduce filas como GROUP BY. Cada partición se procesa independientemente.',
    },
    {
      'name': 'EXISTS / NOT EXISTS',
      'desc': 'Verifica si una subconsulta retorna resultados',
      'syntax': 'WHERE EXISTS\n  (SELECT 1 FROM ...\n   WHERE condicion)',
      'example': 'SELECT nombre FROM clientes c\nWHERE EXISTS (\n  SELECT 1 FROM pedidos p\n  WHERE p.cliente_id = c.id\n);',
      'detail': 'Más eficiente que IN para subconsultas grandes ya que para al encontrar la primera coincidencia.',
    },
    {
      'name': 'IN / NOT IN',
      'desc': 'Filtra si un valor está (o no) en una lista o subconsulta',
      'syntax': 'WHERE col IN (v1, v2, v3)\nWHERE col IN (SELECT ...)',
      'example': 'SELECT * FROM empleados\nWHERE depto IN (\'IT\', \'Ventas\', \'RRHH\');',
      'detail': 'Con NULL en la lista, NOT IN puede retornar resultados inesperados. Preferir NOT EXISTS.',
    },
    {
      'name': 'LIKE',
      'desc': 'Filtra texto con patrones usando comodines',
      'syntax': 'WHERE col LIKE \'patron\'',
      'example': 'SELECT * FROM productos\nWHERE nombre LIKE \'%arroz%\';\n\n-- Empieza con:\nWHERE codigo LIKE \'A%\';',
      'detail': '% = cualquier secuencia de caracteres. _ = exactamente un carácter. Sensible a mayúsculas según collation.',
    },
    {
      'name': 'BETWEEN',
      'desc': 'Filtra valores dentro de un rango (inclusivo)',
      'syntax': 'WHERE col BETWEEN val1 AND val2',
      'example': 'SELECT * FROM ventas\nWHERE fecha BETWEEN \'2024-01-01\'\n  AND \'2024-12-31\';\n\nSELECT * FROM productos\nWHERE precio BETWEEN 10 AND 50;',
      'detail': 'Equivale a col >= val1 AND col <= val2. Funciona con números, fechas y texto.',
    },
    {
      'name': 'IS NULL / IS NOT NULL',
      'desc': 'Verifica si un valor es NULL',
      'syntax': 'WHERE col IS NULL\nWHERE col IS NOT NULL',
      'example': 'SELECT * FROM empleados\nWHERE fecha_baja IS NULL;\n\nSELECT * FROM pedidos\nWHERE observaciones IS NOT NULL;',
      'detail': 'NULL no es igual a nada, ni siquiera a NULL. Siempre usar IS NULL, nunca = NULL.',
    },
    {
      'name': 'COALESCE',
      'desc': 'Retorna el primer valor no NULL de una lista',
      'syntax': 'COALESCE(val1, val2, ..., default)',
      'example': 'SELECT nombre,\n  COALESCE(telefono_movil,\n           telefono_fijo,\n           \'Sin teléfono\') AS contacto\nFROM clientes;',
      'detail': 'Estándar SQL. Equivale a NVL en Oracle o ISNULL en SQL Server para dos argumentos.',
    },
    {
      'name': 'CAST / CONVERT',
      'desc': 'Convierte un valor a otro tipo de dato',
      'syntax': 'CAST(valor AS tipo)\nCONVERT(tipo, valor)  -- SS\nTO_CHAR(fecha, fmt)   -- Oracle',
      'example': '-- SQL Server:\nSELECT CAST(precio AS VARCHAR(20))\nFROM productos;\n\n-- Oracle:\nSELECT TO_CHAR(fecha, \'DD/MM/YYYY\')\nFROM ventas;',
      'detail': 'CAST es estándar SQL. CONVERT es específico de SQL Server con más opciones de formato.',
    },
  ];

  // ─────────────────────────────────────────────
  // TAB 2 DATA
  // ─────────────────────────────────────────────
  List<Map<String, String>> get _comparisons => [
    {'concept': 'Fecha actual', 'ss': 'GETDATE()', 'ora': 'SYSDATE'},
    {'concept': 'Paginación', 'ss': 'OFFSET n ROWS\nFETCH NEXT n ROWS ONLY', 'ora': 'ROWNUM <= N\n/ FETCH FIRST N ROWS ONLY'},
    {'concept': 'Concatenar texto', 'ss': 'col1 + col2', 'ora': 'col1 || col2'},
    {'concept': 'Autoincremento', 'ss': 'IDENTITY(1,1)', 'ora': 'SEQUENCE + TRIGGER'},
    {'concept': 'ISNULL (2 args)', 'ss': 'ISNULL(col, 0)', 'ora': 'NVL(col, 0)'},
    {'concept': 'COALESCE', 'ss': 'COALESCE(a, b, c)', 'ora': 'COALESCE(a, b, c)\n/ NVL(a, b)'},
    {'concept': 'Top N filas', 'ss': 'SELECT TOP N ...', 'ora': 'WHERE ROWNUM <= N'},
    {'concept': 'IF condicional', 'ss': 'IF ... ELSE ...', 'ora': 'IF ... THEN ... END IF (PL/SQL)'},
    {'concept': 'Bloque de código', 'ss': 'BEGIN ... END (T-SQL)', 'ora': 'DECLARE\nBEGIN\nEND; (PL/SQL)'},
    {'concept': 'Tipo texto variable', 'ss': 'VARCHAR / NVARCHAR', 'ora': 'VARCHAR2 / NCHAR'},
    {'concept': 'Tipo fecha', 'ss': 'DATETIME / DATE\n(solo fecha)', 'ora': 'DATE\n(incluye hora)'},
    {'concept': 'Manejo errores', 'ss': 'TRY ... CATCH', 'ora': 'EXCEPTION (PL/SQL)'},
    {'concept': 'Crear procedimiento', 'ss': 'CREATE PROCEDURE', 'ora': 'CREATE OR REPLACE\nPROCEDURE'},
    {'concept': 'Longitud string', 'ss': 'LEN(cadena)', 'ora': 'LENGTH(cadena)'},
    {'concept': 'Subcadena', 'ss': 'SUBSTRING(s, inicio, len)', 'ora': 'SUBSTR(s, inicio, len)'},
    {'concept': 'Conversión general', 'ss': 'CONVERT(tipo, val)', 'ora': 'TO_CHAR() / TO_DATE()'},
    {'concept': 'Número a texto', 'ss': 'CAST(n AS VARCHAR)\n/ CONVERT', 'ora': 'TO_CHAR(n)'},
    {'concept': 'Fecha a texto', 'ss': "CONVERT(varchar,\nfecha, 103)", 'ora': "TO_CHAR(fecha,\n'DD/MM/YYYY')"},
    {'concept': 'Comentario línea', 'ss': '-- comentario', 'ora': '-- comentario'},
    {'concept': 'Comentario bloque', 'ss': '/* comentario */', 'ora': '/* comentario */'},
    {'concept': 'Transacción', 'ss': 'BEGIN TRAN\nCOMMIT / ROLLBACK', 'ora': 'COMMIT / ROLLBACK\n(auto-begin)'},
    {'concept': 'Variable local', 'ss': 'DECLARE @var INT\nSET @var = 1', 'ora': 'v_var NUMBER;\nv_var := 1; (PL/SQL)'},
    {'concept': 'Imprimir salida', 'ss': "PRINT 'texto'", 'ora': "DBMS_OUTPUT\n.PUT_LINE('texto')"},
    {'concept': 'Tabla temporal', 'ss': 'CREATE TABLE #tmp\n/ ##tmp (global)', 'ora': 'GTT / WITH (CTE)'},
    {'concept': 'Secuencia', 'ss': 'IDENTITY o\nCREATE SEQUENCE', 'ora': 'CREATE SEQUENCE\nnext_val.NEXTVAL'},
  ];

  // ─────────────────────────────────────────────
  // TAB 3 DATA
  // ─────────────────────────────────────────────
  Map<String, List<Map<String, dynamic>>> get _functions => {
    'Texto': [
      {'name': 'LEN / LENGTH', 'desc': 'Retorna la longitud de una cadena', 'ss': true, 'ora': true, 'syntax': 'LEN(cadena)  -- SS\nLENGTH(cadena)  -- Oracle', 'example': "SELECT LEN('Hola mundo'); -- 10\nSELECT LENGTH('Hola mundo') FROM DUAL; -- 10"},
      {'name': 'SUBSTRING / SUBSTR', 'desc': 'Extrae una porción de texto', 'ss': true, 'ora': true, 'syntax': 'SUBSTRING(cadena, inicio, longitud)\nSUBSTR(cadena, inicio, longitud)', 'example': "SUBSTRING('SQL Server', 1, 3) -- 'SQL'\nSUBSTR('Oracle DB', 1, 6) -- 'Oracle'"},
      {'name': 'UPPER', 'desc': 'Convierte texto a mayúsculas', 'ss': true, 'ora': true, 'syntax': 'UPPER(cadena)', 'example': "SELECT UPPER('hola') -- 'HOLA'"},
      {'name': 'LOWER', 'desc': 'Convierte texto a minúsculas', 'ss': true, 'ora': true, 'syntax': 'LOWER(cadena)', 'example': "SELECT LOWER('HOLA') -- 'hola'"},
      {'name': 'TRIM / LTRIM / RTRIM', 'desc': 'Elimina espacios al inicio y/o final', 'ss': true, 'ora': true, 'syntax': 'TRIM(cadena)\nLTRIM(cadena)\nRTRIM(cadena)', 'example': "TRIM('  hola  ') -- 'hola'\nLTRIM('  hola') -- 'hola'"},
      {'name': 'REPLACE', 'desc': 'Reemplaza ocurrencias de una subcadena', 'ss': true, 'ora': true, 'syntax': 'REPLACE(cadena, buscar, reemplazar)', 'example': "REPLACE('hola mundo', 'mundo', 'SQL') -- 'hola SQL'"},
      {'name': 'CHARINDEX / INSTR', 'desc': 'Busca la posición de una subcadena', 'ss': true, 'ora': true, 'syntax': "CHARINDEX(buscar, cadena)  -- SS\nINSTR(cadena, buscar)  -- Oracle", 'example': "CHARINDEX('SQL', 'Hola SQL') -- 6\nINSTR('Hola SQL', 'SQL') -- 6"},
      {'name': 'CONCAT', 'desc': 'Concatena dos o más cadenas', 'ss': true, 'ora': true, 'syntax': "CONCAT(str1, str2, ...)", 'example': "CONCAT('Hola', ' ', 'Mundo') -- 'Hola Mundo'"},
      {'name': 'STUFF / INSERT', 'desc': 'Inserta una cadena dentro de otra', 'ss': true, 'ora': false, 'syntax': 'STUFF(cadena, inicio, largo, nueva)', 'example': "STUFF('abcdef', 2, 3, 'XY') -- 'aXYef'"},
      {'name': 'FORMAT / TO_CHAR', 'desc': 'Formatea un valor con patrón personalizado', 'ss': true, 'ora': true, 'syntax': "FORMAT(valor, 'patron')  -- SS\nTO_CHAR(valor, 'patron')  -- Oracle", 'example': "FORMAT(1234.5, 'N2') -- '1,234.50'\nTO_CHAR(1234.5, '9,999.99') -- '1,234.50'"},
    ],
    'Fecha': [
      {'name': 'GETDATE / SYSDATE', 'desc': 'Retorna la fecha y hora actual del servidor', 'ss': true, 'ora': true, 'syntax': 'GETDATE()  -- SQL Server\nSYSDATE    -- Oracle', 'example': "SELECT GETDATE(); -- 2024-01-15 10:30:00\nSELECT SYSDATE FROM DUAL;"},
      {'name': 'DATEADD / + INTERVAL', 'desc': 'Suma un intervalo a una fecha', 'ss': true, 'ora': true, 'syntax': "DATEADD(parte, n, fecha)  -- SS\nfecha + n  -- Oracle (días)\nfecha + INTERVAL '1' MONTH  -- Oracle", 'example': "DATEADD(day, 30, GETDATE())\nSYSDATE + 30  -- Oracle"},
      {'name': 'DATEDIFF', 'desc': 'Calcula la diferencia entre dos fechas', 'ss': true, 'ora': false, 'syntax': 'DATEDIFF(parte, fecha1, fecha2)', 'example': "DATEDIFF(day, '2024-01-01', '2024-12-31') -- 365"},
      {'name': 'DATEPART / EXTRACT', 'desc': 'Extrae una parte específica de una fecha', 'ss': true, 'ora': true, 'syntax': 'DATEPART(parte, fecha)  -- SS\nEXTRACT(parte FROM fecha)  -- Oracle/Estándar', 'example': "DATEPART(year, GETDATE()) -- 2024\nEXTRACT(YEAR FROM SYSDATE) -- 2024"},
      {'name': 'CONVERT / TO_DATE', 'desc': 'Convierte texto a fecha', 'ss': true, 'ora': true, 'syntax': "CONVERT(DATE, '20240115', 112)  -- SS\nTO_DATE('15/01/2024','DD/MM/YYYY')  -- Oracle", 'example': "CONVERT(DATE, '2024-01-15')\nTO_DATE('15/01/2024', 'DD/MM/YYYY')"},
      {'name': 'FORMAT (fecha) / TO_CHAR', 'desc': 'Convierte fecha a texto con formato', 'ss': true, 'ora': true, 'syntax': "FORMAT(fecha, 'dd/MM/yyyy')  -- SS\nTO_CHAR(fecha, 'DD/MM/YYYY')  -- Oracle", 'example': "FORMAT(GETDATE(), 'dd/MM/yyyy')\nTO_CHAR(SYSDATE, 'DD/MM/YYYY')"},
      {'name': 'YEAR / MONTH / DAY', 'desc': 'Extrae año, mes o día de una fecha', 'ss': true, 'ora': false, 'syntax': 'YEAR(fecha)\nMONTH(fecha)\nDAY(fecha)', 'example': "YEAR(GETDATE()) -- 2024\nMONTH('2024-06-15') -- 6"},
      {'name': 'TRUNC / CAST DATE', 'desc': 'Trunca la hora de una fecha', 'ss': true, 'ora': true, 'syntax': "CAST(fecha AS DATE)  -- SS (trunca hora)\nTRUNC(fecha)  -- Oracle", 'example': "CAST(GETDATE() AS DATE) -- 2024-01-15\nTRUNC(SYSDATE) -- 15-JAN-24 00:00:00"},
      {'name': 'EOMONTH', 'desc': 'Retorna el último día del mes', 'ss': true, 'ora': false, 'syntax': 'EOMONTH(fecha [, offset_meses])', 'example': "EOMONTH('2024-02-01') -- 2024-02-29"},
      {'name': 'LAST_DAY', 'desc': 'Retorna el último día del mes (Oracle)', 'ss': false, 'ora': true, 'syntax': 'LAST_DAY(fecha)', 'example': "SELECT LAST_DAY(SYSDATE) FROM DUAL;"},
    ],
    'Numérica': [
      {'name': 'ROUND', 'desc': 'Redondea un número a N decimales', 'ss': true, 'ora': true, 'syntax': 'ROUND(numero, decimales)', 'example': "ROUND(3.14159, 2) -- 3.14\nROUND(2.5, 0) -- 3"},
      {'name': 'FLOOR', 'desc': 'Redondea hacia abajo al entero menor', 'ss': true, 'ora': true, 'syntax': 'FLOOR(numero)', 'example': "FLOOR(4.9) -- 4\nFLOOR(-4.1) -- -5"},
      {'name': 'CEILING / CEIL', 'desc': 'Redondea hacia arriba al entero mayor', 'ss': true, 'ora': true, 'syntax': 'CEILING(numero)  -- SS\nCEIL(numero)     -- Oracle', 'example': "CEILING(4.1) -- 5\nCEIL(-4.9) -- -4"},
      {'name': 'ABS', 'desc': 'Retorna el valor absoluto', 'ss': true, 'ora': true, 'syntax': 'ABS(numero)', 'example': "ABS(-42) -- 42\nABS(3.14) -- 3.14"},
      {'name': 'POWER', 'desc': 'Eleva un número a una potencia', 'ss': true, 'ora': true, 'syntax': 'POWER(base, exponente)', 'example': "POWER(2, 10) -- 1024"},
      {'name': 'SQRT', 'desc': 'Calcula la raíz cuadrada', 'ss': true, 'ora': true, 'syntax': 'SQRT(numero)', 'example': "SQRT(144) -- 12\nSQRT(2) -- 1.41421..."},
      {'name': 'MOD / %', 'desc': 'Retorna el resto de una división', 'ss': true, 'ora': true, 'syntax': '10 % 3  -- SQL Server\nMOD(10, 3)  -- Oracle', 'example': "10 % 3 -- 1\nMOD(10, 3) -- 1"},
      {'name': 'CAST AS DECIMAL', 'desc': 'Convierte a tipo decimal con precisión', 'ss': true, 'ora': true, 'syntax': 'CAST(valor AS DECIMAL(p, s))', 'example': "CAST(3 AS DECIMAL(10,2)) -- 3.00"},
      {'name': 'RAND / DBMS_RANDOM', 'desc': 'Genera un número aleatorio', 'ss': true, 'ora': true, 'syntax': 'RAND()  -- SS (0 a 1)\nDBMS_RANDOM.VALUE(a,b)  -- Oracle', 'example': "RAND() -- 0.712...\nDBMS_RANDOM.VALUE(1,100) -- 67.43..."},
      {'name': 'LOG / LN', 'desc': 'Logaritmo natural o en base N', 'ss': true, 'ora': true, 'syntax': 'LOG(numero)  -- SS (base e)\nLOG(base, numero)  -- SS\nLN(numero)  -- Oracle', 'example': "LOG(10) -- 2.302...\nLOG(10, 100) -- 2"},
    ],
    'Agregación': [
      {'name': 'COUNT', 'desc': 'Cuenta el número de filas o valores no NULL', 'ss': true, 'ora': true, 'syntax': 'COUNT(*)\nCOUNT(columna)\nCOUNT(DISTINCT columna)', 'example': "SELECT COUNT(*) FROM empleados;\nSELECT COUNT(DISTINCT depto) FROM empleados;"},
      {'name': 'SUM', 'desc': 'Suma todos los valores de una columna', 'ss': true, 'ora': true, 'syntax': 'SUM(columna)\nSUM(DISTINCT columna)', 'example': "SELECT SUM(salario) FROM empleados;\nSELECT depto, SUM(ventas)\nFROM ventas GROUP BY depto;"},
      {'name': 'AVG', 'desc': 'Calcula el promedio de los valores', 'ss': true, 'ora': true, 'syntax': 'AVG(columna)', 'example': "SELECT AVG(salario) FROM empleados;\n-- Ignora NULL automáticamente"},
      {'name': 'MAX', 'desc': 'Retorna el valor máximo', 'ss': true, 'ora': true, 'syntax': 'MAX(columna)', 'example': "SELECT MAX(fecha) FROM pedidos;\nSELECT MAX(precio) FROM productos;"},
      {'name': 'MIN', 'desc': 'Retorna el valor mínimo', 'ss': true, 'ora': true, 'syntax': 'MIN(columna)', 'example': "SELECT MIN(salario) FROM empleados;\nSELECT depto, MIN(fecha_ingreso) FROM empleados GROUP BY depto;"},
      {'name': 'STRING_AGG / LISTAGG', 'desc': 'Concatena valores de filas en una cadena', 'ss': true, 'ora': true, 'syntax': "STRING_AGG(col, ',')  -- SS\nLISTAGG(col, ',') WITHIN GROUP (ORDER BY col)  -- Oracle", 'example': "SELECT depto,\n  STRING_AGG(nombre, ', ') AS empleados\nFROM empleados GROUP BY depto;"},
      {'name': 'VAR / VARIANCE', 'desc': 'Calcula la varianza estadística', 'ss': true, 'ora': true, 'syntax': 'VAR(columna)  -- SS\nVARIANCE(columna)  -- Oracle', 'example': "SELECT VAR(salario) FROM empleados;"},
      {'name': 'STDEV / STDDEV', 'desc': 'Calcula la desviación estándar', 'ss': true, 'ora': true, 'syntax': 'STDEV(columna)  -- SS\nSTDDEV(columna)  -- Oracle', 'example': "SELECT STDEV(precio) FROM productos;\nSELECT STDDEV(salario) FROM empleados;"},
      {'name': 'FIRST_VALUE / LAST_VALUE', 'desc': 'Retorna primer/último valor de una ventana', 'ss': true, 'ora': true, 'syntax': 'FIRST_VALUE(col) OVER (PARTITION BY ... ORDER BY ...)\nLAST_VALUE(col) OVER (...)', 'example': "SELECT nombre,\n  FIRST_VALUE(salario) OVER\n    (PARTITION BY depto ORDER BY fecha_ingreso)\n    AS primer_salario\nFROM empleados;"},
      {'name': 'LAG / LEAD', 'desc': 'Accede a filas anteriores/siguientes en la ventana', 'ss': true, 'ora': true, 'syntax': 'LAG(col, offset, default) OVER (...)\nLEAD(col, offset, default) OVER (...)', 'example': "SELECT fecha, ventas,\n  LAG(ventas, 1, 0) OVER (ORDER BY fecha) AS ventas_ant\nFROM resumen_ventas;"},
    ],
  };

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text(
            'Referencia Rápida 📖',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            onTap: (i) => setState(() => _tabIndex = i),
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Comandos'),
              Tab(text: 'SS vs Oracle'),
              Tab(text: 'Funciones'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCommandsTab(),
                  _buildComparisonTab(),
                  _buildFunctionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar...',
          hintStyle: GoogleFonts.inter(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF0D1117),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ─── TAB 1: Comandos ───────────────────────────
  Widget _buildCommandsTab() {
    final filtered = _commands.where((cmd) {
      if (_searchQuery.isEmpty) return true;
      return cmd['name']!.toLowerCase().contains(_searchQuery) ||
          cmd['desc']!.toLowerCase().contains(_searchQuery) ||
          cmd['detail']!.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No se encontraron comandos para "$_searchQuery"');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => _buildCommandTile(filtered[i]),
    );
  }

  Widget _buildCommandTile(Map<String, String> cmd) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          ),
          child: Text(
            cmd['name']!,
            style: GoogleFonts.firaCode(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cmd['desc']!,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.white38,
        children: [
          _buildSectionLabel('Sintaxis:'),
          _buildCodeSnippet(cmd['syntax']!),
          const SizedBox(height: 6),
          _buildSectionLabel('Ejemplo:'),
          _buildCodeSnippet(cmd['example']!),
          const SizedBox(height: 6),
          _buildSectionLabel('Descripción:'),
          Text(cmd['detail']!, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // ─── TAB 2: Comparación SS vs Oracle ──────────
  Widget _buildComparisonTab() {
    final filtered = _comparisons.where((row) {
      if (_searchQuery.isEmpty) return true;
      return row['concept']!.toLowerCase().contains(_searchQuery) ||
          row['ss']!.toLowerCase().contains(_searchQuery) ||
          row['ora']!.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No se encontraron comparaciones para "$_searchQuery"');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      itemCount: filtered.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildComparisonHeader();
        return _buildComparisonCard(filtered[i - 1]);
      },
    );
  }

  Widget _buildComparisonHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Concepto',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF0078D4), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text('SQL Server', style: GoogleFonts.inter(color: const Color(0xFF0078D4), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text('Oracle', style: GoogleFonts.inter(color: const Color(0xFFFF6B35), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(Map<String, String> row) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  row['concept']!,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            Container(width: 1, color: Colors.white12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: GestureDetector(
                  onTap: () => _copyToClipboard(row['ss']!),
                  child: Text(
                    row['ss']!,
                    style: GoogleFonts.firaCode(color: const Color(0xFF6DB3F2), fontSize: 11),
                  ),
                ),
              ),
            ),
            Container(width: 1, color: Colors.white12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: GestureDetector(
                  onTap: () => _copyToClipboard(row['ora']!),
                  child: Text(
                    row['ora']!,
                    style: GoogleFonts.firaCode(color: const Color(0xFFFF8C61), fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3: Funciones ──────────────────────────
  Widget _buildFunctionsTab() {
    final categories = _functions.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        final entry = categories[i];
        final filtered = entry.value.where((fn) {
          if (_searchQuery.isEmpty) return true;
          return fn['name'].toString().toLowerCase().contains(_searchQuery) ||
              fn['desc'].toString().toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) return const SizedBox.shrink();

        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            title: Row(
              children: [
                Icon(_categoryIcon(entry.key), color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11),
                  ),
                ),
              ],
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: Colors.white38,
            children: filtered.map((fn) => _buildFunctionTile(fn)).toList(),
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Texto': return Icons.text_fields;
      case 'Fecha': return Icons.calendar_today;
      case 'Numérica': return Icons.calculate;
      case 'Agregación': return Icons.bar_chart;
      default: return Icons.functions;
    }
  }

  Widget _buildFunctionTile(Map<String, dynamic> fn) {
    final hasSS = fn['ss'] as bool;
    final hasOra = fn['ora'] as bool;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      title: Text(
        fn['name'],
        style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 13),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(fn['desc'], style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSS) _buildChip('SS', const Color(0xFF0078D4)),
          if (hasSS && hasOra) const SizedBox(width: 4),
          if (hasOra) _buildChip('ORA', const Color(0xFFFF6B35)),
        ],
      ),
      onTap: () => _showFunctionBottomSheet(fn),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showFunctionBottomSheet(Map<String, dynamic> fn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          minChildSize: 0.35,
          expand: false,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  fn['name'],
                  style: GoogleFonts.firaCode(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(fn['desc'], style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (fn['ss'] as bool) _buildChip('SQL Server', const Color(0xFF0078D4)),
                    if ((fn['ss'] as bool) && (fn['ora'] as bool)) const SizedBox(width: 6),
                    if (fn['ora'] as bool) _buildChip('Oracle', const Color(0xFFFF6B35)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Sintaxis:', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _buildCodeSnippet(fn['syntax']),
                const SizedBox(height: 12),
                Text('Ejemplo:', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _buildCodeSnippet(fn['example']),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Helpers ───────────────────────────────────
  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(msg, style: GoogleFonts.inter(color: Colors.white38, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
