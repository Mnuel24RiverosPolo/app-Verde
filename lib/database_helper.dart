import 'package:app_conteo/model/producto_model.dart';
import 'package:app_conteo/model/reporteTim_model.dart';
import 'package:app_conteo/model/reporte_model.dart';
import 'package:app_conteo/model/ubicacion_model.dart';
import 'package:excel/excel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reporte.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const sqlUbicacion = '''
    CREATE TABLE ubicacion (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      division TEXT,
      departamento TEXT,
      subdepartamento TEXT,
      clase TEXT,
      subclase TEXT
    )
  ''';
      await db.execute(sqlUbicacion);
    }
    if (oldVersion < 3) {
      const sqlProducto = '''
    CREATE TABLE producto (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subclase TEXT,
      proveedor TEXT,
      sku TEXT,
      ean TEXT,
      descripcion TEXT,
      case_pack INTEGER
    )
  ''';
      await db.execute(sqlProducto);
    }
    if (oldVersion < 4) {
      const sqlReporteTim = '''
        CREATE TABLE reporte_tim (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha_generacion TEXT ,
          tim INTEGER,         
          shipment INTEGER,     
          placa TEXT,            
          local_origen TEXT,    
          local_destino TEXT,   
          fecha_envio TEXT   
        )
        ''';

      await db.execute(sqlReporteTim);
    }
  }

  Future _createDB(Database db, int version) async {
    const sql = '''
      CREATE TABLE reporte (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tim INTEGER,
        olpn TEXT,
        pallet TEXT,
        tipo_inventario TEXT,
        tipo_sku TEXT,
        subdpto TEXT,
        ean TEXT,
        sku TEXT,
        descripcion TEXT,
        case_pack INTEGER,
        unidades REAL,
        cajas REAL,
        recibidos REAL,
        fechavencimiento TEXT,
        faltantes TEXT
      )
    ''';
    await db.execute(sql);

    const sqlUbicacion = '''
    CREATE TABLE ubicacion (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      division TEXT,
      departamento TEXT,
      subdepartamento TEXT,
      clase TEXT,
      subclase TEXT
    )
  ''';
    await db.execute(sqlUbicacion);

    const sqlProducto = '''
    CREATE TABLE producto (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subclase TEXT,
      proveedor TEXT,
      sku TEXT,
      ean TEXT,
      descripcion TEXT,
      case_pack INTEGER
    )
  ''';
    await db.execute(sqlProducto);

    const sqlReporteTim = '''
        CREATE TABLE reporte_tim (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha_generacion TEXT ,
          tim INTEGER,         
          shipment INTEGER,     
          placa TEXT,            
          local_origen TEXT,    
          local_destino TEXT,   
          fecha_envio TEXT   
        )
        ''';

    await db.execute(sqlReporteTim);
  }

  Future<List<Map<String, dynamic>>> searchByEan(String ean) async {
    final db = await instance.database;
    final String query = '''
    SELECT reporte.*
    FROM producto
    INNER JOIN reporte ON producto.sku = reporte.sku
    WHERE producto.ean = ?;
  ''';

    return await db.rawQuery(query, [ean]);
  }

  Future<void> insertReporteTim(ReporteTim reporteTim) async {
    final db = await instance.database;

    // Verificar si el 'tim' ya existe
    final result = await db.query(
      'reporte_tim',
      where: 'tim = ?',
      whereArgs: [reporteTim.tim],
    );

    if (result.isNotEmpty) {
      // El 'tim' ya existe, no se inserta
      print('El tim ${reporteTim.tim} ya existe en la base de datos.');
      return;
    }

    // Insertar si no existe
    await db.insert('reporte_tim', reporteTim.toMap());
    print('ReporteTim con tim ${reporteTim.tim} insertado correctamente.');
  }

  Future<List<ReporteTim>> fetchReporteTim() async {
    final db = await instance.database;
    final maps = await db.query('reporte_tim');
    return maps.map((map) => ReporteTim.fromMap(map)).toList();
  }

  Future<void> insertProducto(Producto producto) async {
    final db = await instance.database;

    // Convertir el objeto Producto a un mapa
    final productoMap = producto.toMap();

    // Insertar el mapa en la tabla 'producto'
    await db.insert(
      'producto',
      productoMap,
      conflictAlgorithm: ConflictAlgorithm.replace, // Evita duplicados
    );
  }

  Future<List<Producto>> getProductos() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('producto');

    return List.generate(maps.length, (i) {
      return Producto.fromMap(maps[i]);
    });
  }

  // Agrega estos métodos
  Future<List<Producto>> getProductosFiltrados(
      {String? descripcion, String? subclase}) async {
    final db = await database;
    var query = 'SELECT * FROM producto';
    final params = <dynamic>[];
    final whereClauses = <String>[];

    if (descripcion != null && descripcion.isNotEmpty) {
      whereClauses.add('descripcion LIKE ?');
      params.add('%$descripcion%');
    }

    if (subclase != null && subclase.isNotEmpty) {
      whereClauses.add('subclase LIKE ?');
      params.add('%$subclase%');
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    final result = await db.rawQuery(query, params);
    return result.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<String>> getSubclasesUnicas() async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT DISTINCT 
      TRIM(
        CASE 
          WHEN INSTR(subclase, '-') > 0 
          THEN SUBSTR(subclase, 1, INSTR(subclase, '-') - 1)
          ELSE subclase
        END
      ) as subclase_base
    FROM producto
    WHERE subclase IS NOT NULL
  ''');

    return result
        .where((row) => row['subclase_base'] != null)
        .map((row) => row['subclase_base'] as String)
        .toList();
  }

  Future<Producto?> getProductobyEan(String ean) async {
    final db = await instance.database;

    // Usamos 'LIKE' para buscar si el ean contiene el valor proporcionado
    final List<Map<String, dynamic>> maps = await db.query(
      'producto',
      where: 'ean LIKE ?', // Usamos LIKE para coincidencias parciales
      whereArgs: [
        '%$ean%'
      ], // El '%' es un comodín que permite que se busque en cualquier parte de la cadena
    );

    if (maps.isNotEmpty) {
      return Producto.fromMap(maps.first);
    }

    return null;
  }

  Future<void> insertUbicacion(Ubicacion ubicacion) async {
    final db = await instance.database;

    // Validar si el registro ya existe
    final List<Map<String, dynamic>> result = await db.query(
      'ubicacion',
      where:
          'division = ? AND departamento = ? AND subdepartamento = ? AND clase = ? AND subclase = ?',
      whereArgs: [
        ubicacion.division,
        ubicacion.departamento,
        ubicacion.subdepartamento,
        ubicacion.clase,
        ubicacion.subclase,
      ],
    );

    // Si no existe, insertar el registro
    if (result.isEmpty) {
      final processedData = ubicacion.toMap();
      await db.insert('ubicacion', processedData);
    } else {
      print('Registro duplicado: ${ubicacion.toMap()}');
    }
  }

  Future<List<Ubicacion>> getUbicaciones() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('ubicacion');

    return List.generate(maps.length, (i) {
      return Ubicacion.fromMap(maps[i]);
    });
  }

  Future<void> insertReport(Reporte reporte) async {
    final db = await instance.database;

    final processedData = reporte.toMap();

    await db.insert('reporte', processedData);
  }

  Future<void> insertReportSinR(Reporte reporte) async {
    final db = await instance.database;

    final result = await db.query(
      'reporte',
      where: 'ean = ?',
      whereArgs: [reporte.ean],
    );
    if (result.isEmpty) {
      final processedData = reporte.toMap();
      await db.insert('reporte', processedData);
      print("Reporte insertado con éxito");
    } else {
      print("El reporte con el ean ${reporte.ean} ya existe.");
    }
  }

  Future<int> updateReporte(Reporte reporte) async {
    final db = await instance.database;

    final Map<String, dynamic> row = reporte.toMap();

    if (reporte.id == null) {
      throw Exception('El ID no puede ser null para la actualización');
    }

    // Realiza la actualización en la base de datos
    return await db.update(
      'reporte',
      row,
      where: 'id = ?',
      whereArgs: [reporte.id],
    );
  }

  Future<bool> updateRecibidos(int id, double nuevosRecibidos) async {
    final db = await instance.database;

    try {
      int result = await db.update(
        'reporte',
        {'recibidos': nuevosRecibidos},
        where: 'id = ?',
        whereArgs: [id],
      );

      // Si result es mayor que 0, la actualización fue exitosa.
      return result > 0;
    } catch (e) {
      // Si ocurre un error, lo capturamos y retornamos false.
      print('Error al actualizar: $e');
      return false;
    }
  }

  Future<List<Reporte>> getReportes() async {
    final db = await instance.database;

    final String query = '''
        SELECT *
        FROM 
          reporte
        ''';

    // Ejecuta la consulta
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    // Convierte los resultados en una lista de Reporte
    return List.generate(maps.length, (i) {
      return Reporte.fromMap(maps[i]);
    });
  }

  Future<List<Reporte>> getReportesByTim(int tim) async {
    final db = await instance.database;

    final String query = '''
        SELECT *
        FROM 
          reporte
        WHERE tim =?
        ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [tim]);

    // Convierte los resultados en una lista de Reporte
    return List.generate(maps.length, (i) {
      return Reporte.fromMap(maps[i]);
    });
  }

  Future<List<int>> getTims() async {
    final db = await instance.database;

    final String query = '''
  SELECT DISTINCT tim
  FROM reporte
  ''';

    // Ejecuta la consulta
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    // Convierte los resultados en una lista de int
    return maps.map((map) => map['tim'] as int).toList();
  }

  // Future<List<Reporte>> getReportes() async {
  //   final db = await instance.database;

  //   final String query = '''
  //       SELECT
  //         r.id,
  //         r.olpn,
  //         r.pallet,
  //         r.tipo_inventario AS tipoInventario,
  //         r.tipo_sku AS tipoSku,
  //         r.subdpto AS subdpto,
  //         p.ean AS ean,
  //         r.sku,
  //         r.descripcion,
  //         r.case_pack AS casePack,
  //         r.unidades,
  //         r.cajas,
  //         r.recibidos,
  //         r.fechavencimiento,
  //         r.faltantes
  //       FROM
  //         reporte r
  //       LEFT JOIN
  //         producto p
  //       ON
  //         r.sku = p.sku
  //       ''';

  //   // Ejecuta la consulta
  //   final List<Map<String, dynamic>> maps = await db.rawQuery(query);

  //   // Convierte los resultados en una lista de Reporte
  //   return List.generate(maps.length, (i) {
  //     return Reporte.fromMap(maps[i]);
  //   });
  // }

  Future<List<String>> getSubDepartments() async {
    final db =
        await database; // Asegúrate de inicializar `database` correctamente.
    const sql = '''
    SELECT DISTINCT subdpto
    FROM reporte
  ''';
    final List<Map<String, dynamic>> result = await db.rawQuery(sql);

    // Convierte el resultado a una lista de cadenas.
    return result.map((row) => row['subdpto'] as String).toList();
  }

  Future<void> deleteAllReports() async {
    final db = await instance.database;
    await db.delete('reporte');
    await db.delete('producto'); //
    await db.delete('ubicacion'); //
    await db.delete('reporte_tim'); //
  }

  Future<void> deleteReportes(int tim) async {
    final db = await instance.database;

    // Eliminar los reportes donde el valor de 'tim' coincida con el TIM especificado
    await db.delete(
      'reporte', // Nombre de la tabla
      where: 'tim = ?', // Condición para la eliminación
      whereArgs: [tim], // Valor para reemplazar el '?' (el TIM a eliminar)
    );
  }
}
