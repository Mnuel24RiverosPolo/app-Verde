import 'dart:convert';
import 'dart:io';

import 'package:app_conteo/discrepancias_screen.dart';
import 'package:app_conteo/model/producto_model.dart';
import 'package:app_conteo/model/reporteTim_model.dart';
import 'package:app_conteo/model/reporte_model.dart';
import 'package:app_conteo/model/ubicacion_model.dart';
import 'package:app_conteo/productos_list_screen.dart';
import 'package:app_conteo/productos_reporte_screen.dart';
import 'package:app_conteo/resport_list_screen.dart';
import 'package:app_conteo/ubicaciones_screen.dart';
import 'package:app_conteo/utils/app_colors.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({Key? key}) : super(key: key);

  Future<void> processExcelFile(String filePath) async {
    // Leer el archivo Excel
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final dbHelper = DatabaseHelper.instance;

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table]!;

      for (var i = 11; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        final reporte = Reporte(
          olpn: row[0]?.value?.toString() ?? '',
          pallet: row[1]?.value?.toString() ?? '',
          tipoInventario: row[2]?.value?.toString() ?? '',
          tipoSku: row[3]?.value?.toString() ?? '',
          subdpto: row[4]?.value?.toString() ?? '',
          // ean: row[5]?.value?.toString() ?? '',
          sku: row[5]?.value?.toString() ?? '',
          descripcion: row[6]?.value?.toString() ?? '',
          casePack: row[7]?.value ?? 0,
          unidades: row[8]?.value ?? 0,
          cajas: (row[9]?.value is num)
              ? (row[9]?.value as num).toDouble()
              : double.tryParse(row[9]?.value?.toString() ?? '0') ?? 0.0,

          recibidos: row[10]?.value ?? 0,
          ean: row[11]?.value?.toString() ?? '',
          fechavencimiento: '',
          faltantes: '',
        );

        // Insertar el objeto Reporte en la base de datos
        await dbHelper.insertReport(reporte);
      }
    }
  }

  Future<void> processExcelFile2(String filePath) async {
    // Leer el archivo Excel
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final dbHelper = DatabaseHelper.instance;
    final extractValue = (String? input) {
      if (input == null || !input.contains(':')) return input ?? '';
      // Divide por ":", y toma todo después del primer ":".
      return input.split(':').skip(1).join(':').trim();
    };

    if (excel.tables.containsKey('Página1_1')) {
      final sheet2 = excel.tables['Página1_1']!;
      if (sheet2.rows.length >= 10) {
        final reporteTim = ReporteTim(
          fechaGeneracion:
              extractValue(sheet2.rows[1][0]?.value?.toString()), // A2
          tim: int.tryParse(
                  extractValue(sheet2.rows[3][0]?.value?.toString())) ??
              0, // A4
          shipment: int.tryParse(
                  extractValue(sheet2.rows[4][0]?.value?.toString())) ??
              0, // A5
          placa: extractValue(sheet2.rows[5][0]?.value?.toString()), // A6
          localOrigen: extractValue(sheet2.rows[6][0]?.value?.toString()), // A7
          localDestino:
              extractValue(sheet2.rows[7][0]?.value?.toString()), // A8
          fechaEnvio: extractValue(sheet2.rows[8][0]?.value?.toString()), // A9
        );

        await dbHelper.insertReporteTim(reporteTim);
      } else {
        print('Hoja2 no tiene suficientes filas para procesar');
      }

      for (var i = 11; i < sheet2.rows.length; i++) {
        final row = sheet2.rows[i];

        final reporte = Reporte(
          olpn: row[0]?.value?.toString() ?? '',
          pallet: row[1]?.value?.toString() ?? '',
          tipoInventario: row[2]?.value?.toString() ?? '',
          tipoSku: row[3]?.value?.toString() ?? '',
          subdpto: row[4]?.value?.toString() ?? '',
          // ean: row[5]?.value?.toString() ?? '',
          sku: row[5]?.value?.toString() ?? '',
          descripcion: row[6]?.value?.toString() ?? '',
          casePack: row[7]?.value ?? 0,
          unidades: (row[8]?.value is num)
              ? (row[8]?.value as num).toDouble()
              : double.tryParse(row[8]?.value?.toString() ?? '0') ?? 0.0,

          ///row[8]?.value ?? 0,
          cajas: (row[9]?.value is num)
              ? (row[9]?.value as num).toDouble()
              : double.tryParse(row[9]?.value?.toString() ?? '0') ?? 0.0,
          ean: row[10]?.value?.toString() ?? '',
          recibidos: 0.0, //row[10]?.value ??
          tim: int.tryParse(
                  extractValue(sheet2.rows[3][0]?.value?.toString())) ??
              0,
          fechavencimiento: '',
          faltantes: '',
        );

        await dbHelper.insertReport(reporte);
      }
    }
  }

  Future<void> processCsvFile(String filePath) async {
    try {
      // Leemos el archivo CSV con una codificación específica (ISO-8859-1 o similar)
      final file = File(filePath);
      final data = await file.readAsString(
          encoding: latin1); // Usando latin1 en lugar de utf-8

      // Convertimos el contenido del archivo CSV a una lista de filas, especificando el delimitador ';'
      List<List<dynamic>> rows =
          const CsvToListConverter(fieldDelimiter: ';').convert(data);

      // Obtiene la instancia de la base de datos
      final dbHelper = DatabaseHelper.instance;

      // Itera sobre las filas y las inserta en la base de datos
      for (var i = 1; i < rows.length; i++) {
        // Empezamos en 1 para saltarnos el encabezado
        var row = rows[i];

        final casePack =
            (double.tryParse(row[3]?.toString().replaceAll(',', '.') ?? '') ??
                    0.0)
                .toInt();

        final producto = Producto(
          sku: row[0]?.toString() ?? '',
          ean: row[1]?.toString() ?? '',
          descripcion: row[2]?.toString() ?? '',
          casePack: casePack, // Usamos la conversión de casePack aquí
          subclase: row[5]?.toString() ?? '',
          proveedor: row[8]?.toString() ?? '',
        );

        // Insertar el producto en la base de datos
        await dbHelper.insertProducto(producto);
      }
    } catch (e) {
      print("Error al procesar el archivo CSV: $e");
    }
  }

  Future<void> insertProducto(Producto producto) async {
    final db = await DatabaseHelper.instance.database;
    final productoMap = producto.toMap();
    await db.insert(
      'producto',
      productoMap,
      conflictAlgorithm: ConflictAlgorithm.replace, // Evita duplicados
    );
  }

  Future<void> processExcelFile3(String filePath) async {
    // Leer el archivo Excel
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final dbHelper = DatabaseHelper.instance;

    // Procesar la hoja 1
    if (excel.tables.containsKey('Hoja1')) {
      final sheet1 = excel.tables['Hoja1']!;

      // Iniciar una transacción
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        for (var i = 1; i < sheet1.rows.length; i++) {
          final row = sheet1.rows[i];

          final producto = Producto(
            sku: row[0]?.value?.toString() ?? '',
            ean: row[1]?.value?.toString() ?? '',
            descripcion: row[2]?.value?.toString() ?? '',
            casePack: (row[3]?.value is int)
                ? row[3]?.value
                : int.tryParse(row[3]?.value?.toString() ?? '') ?? 0,
            subclase: row[5]?.value?.toString() ?? '',
            proveedor: row[8]?.value?.toString() ?? '',
          );

          // Insertar el producto en la transacción
          await txn.insert(
            'producto',
            producto.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace, // Evita duplicados
          );
        }
      });
    }
  }

  Future<void> pickFile(BuildContext context) async {
    // Seleccionar archivo
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      final filePath = result.files.single.path!;

      // Mostrar indicador de carga mientras se procesa el archivo
      showDialog(
        context: context,
        barrierDismissible: false, // Evita cerrar el diálogo al tocar afuera
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(), // Indicador de carga
          );
        },
      );

      try {
        await processExcelFile2(filePath); // Procesar el archivo

        // Cierra el diálogo de carga
        Navigator.of(context).pop();

        // Mostrar diálogo de éxito con AwesomeDialog
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          title: 'Éxito',
          desc: 'Archivo procesado y datos guardados en la base de datos.',
          btnOkOnPress: () {},
        ).show();
      } catch (e) {
        // Cierra el diálogo de carga si ocurre un error
        Navigator.of(context).pop();

        // Mostrar diálogo de error con AwesomeDialog
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Ocurrió un problema al procesar el archivo: $e',
          btnOkOnPress: () {},
        ).show();
      }
    } else {
      // Mostrar diálogo de cancelación con AwesomeDialog
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'Advertencia',
        desc: 'No se seleccionó ningún archivo.',
        btnOkOnPress: () {},
      ).show();
    }
  }

  Future<void> pickFile2(BuildContext context) async {
    // Seleccionar archivo
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'], // Aceptamos solo archivos CSV
    );

    if (result != null) {
      final filePath = result.files.single.path!;

      // Mostrar indicador de carga mientras se procesa el archivo
      showDialog(
        context: context,
        barrierDismissible: false, // Evita cerrar el diálogo al tocar afuera
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(), // Indicador de carga
          );
        },
      );

      try {
        await processCsvFile(filePath);

        // Cierra el diálogo de carga
        Navigator.of(context).pop();

        // Mostrar diálogo de éxito con AwesomeDialog
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          title: 'Éxito',
          desc: 'Archivo procesado y datos guardados en la base de datos.',
          btnOkOnPress: () {},
        ).show();
      } catch (e) {
        // Cierra el diálogo de carga si ocurre un error
        Navigator.of(context).pop();

        // Mostrar diálogo de error con AwesomeDialog
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'Ocurrió un problema al procesar el archivo: $e',
          btnOkOnPress: () {},
        ).show();
      }
    } else {
      // Mostrar diálogo de cancelación con AwesomeDialog
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'Advertencia',
        desc: 'No se seleccionó ningún archivo.',
        btnOkOnPress: () {},
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Control Verde',
            style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.verdeClaro,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete), // Ícono de eliminación
            onPressed: () {
              // Mostrar diálogo de confirmación con AwesomeDialog
              AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                title: 'Confirmación',
                desc: '¿Estás seguro de que deseas eliminar todos los datos?',
                btnCancelOnPress: () {
                  // Acciones si el usuario cancela (opcional)
                },
                btnOkOnPress: () async {
                  // Eliminar todos los datos de la base de datos
                  await DatabaseHelper.instance.deleteAllReports();

                  // Mostrar diálogo de éxito con AwesomeDialog
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.success,
                    title: 'Éxito',
                    desc: 'Todos los datos han sido eliminados correctamente.',
                    btnOkOnPress: () {},
                  ).show();
                },
              ).show();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Número de columnas
          crossAxisSpacing: 16, // Espacio horizontal entre las Cards
          mainAxisSpacing: 16, // Espacio vertical entre las Cards
          children: <Widget>[
            // Opción para subir archivo
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () => pickFile(context), // Acción para subir archivo
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file,
                        size: 40, color: AppColors.verdeClaro),
                    const SizedBox(height: 10),
                    const Text(
                      'Subir Archivo',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () {
                  int? selectedTim;

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: Text("Selecciona una TIM"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Elige una TIM en la que vas a trabajar:"),
                                const SizedBox(height: 20),
                                RadioListTile<int>(
                                  title: Text("TIM 1: 655247005"),
                                  value: 655247005,
                                  groupValue: selectedTim,
                                  onChanged: (value) {
                                    setState(() => selectedTim = value);
                                  },
                                ),
                                RadioListTile<int>(
                                  title: Text("TIM 2: 8t7347878453"),
                                  value: 5435564357,
                                  groupValue: selectedTim,
                                  onChanged: (value) {
                                    setState(() => selectedTim = value);
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Cancelar"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (selectedTim != null) {
                                    Navigator.pop(context); // Cerrar diálogo
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductosReporteScreen(
                                          selectedTim: selectedTim!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text("Aceptar"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.list, size: 40, color: AppColors.verdeClaro),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        const Text(
                          'Registro de ',
                          style: TextStyle(
                              height: 0.8,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          ' Recepción',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Agregar más Cards para otras opciones
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DiscrepanciasScreen()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '≠',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.verdeClaro,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Discrepancias',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () => pickFile2(context), // Acción para subir archivo
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file,
                        size: 40, color: AppColors.verdeClaro),
                    const SizedBox(height: 10),
                    const Text(
                      'Subir Archivo 2',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProductListScreen()),
                  );
                }, // Acción para subir archivo
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.list, size: 40, color: Colors.blue),
                    const SizedBox(height: 10),
                    const Text(
                      'Productos',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
