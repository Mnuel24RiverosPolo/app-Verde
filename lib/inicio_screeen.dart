import 'dart:convert';
import 'dart:io';

import 'package:app_conteo/database_helper.dart';
import 'package:app_conteo/discrepancias_screen.dart';
import 'package:app_conteo/model/producto_model.dart';
import 'package:app_conteo/model/reporteTim_model.dart';
import 'package:app_conteo/model/reporte_model.dart';
import 'package:app_conteo/productos_list_screen.dart';

import 'package:app_conteo/productos_reporte_screen.dart';
import 'package:app_conteo/screens/donaciones/donaciones_screen.dart';

import 'package:app_conteo/utils/app_colors.dart';
import 'package:app_conteo/widgets/cardInicio.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

import 'package:sqflite/sqflite.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({Key? key}) : super(key: key);

  Future<void> _processExcelReport(String filePath) async {
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

  Future<void> _processCsvDepthFile(String filePath) async {
    try {
      final file = File(filePath);
      final data = await file.readAsString(encoding: latin1);
      List<List<dynamic>> rows =
          const CsvToListConverter(fieldDelimiter: ';').convert(data);

      final dbHelper = DatabaseHelper.instance;
      for (var i = 1; i < rows.length; i++) {
        var row = rows[i];

        final casePack =
            (double.tryParse(row[3]?.toString().replaceAll(',', '.') ?? '') ??
                    0.0)
                .toInt();

        final producto = Producto(
          sku: row[0]?.toString() ?? '',
          ean: row[1]?.toString() ?? '',
          descripcion: row[2]?.toString() ?? '',
          casePack: casePack,
          subclase: row[5]?.toString() ?? '',
          proveedor: row[8]?.toString() ?? '',
        );
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

  Future<void> _handleTimReportSelection(BuildContext context) async {
    await _pickAndProcessFile(
      context,
      allowedExtensions: ['xlsx'],
      processFunction: _processExcelReport,
    );
  }

  Future<void> _handleDepthReportSelection(BuildContext context) async {
    await _pickAndProcessFile(
      context,
      allowedExtensions: ['csv'],
      processFunction: _processCsvDepthFile,
    );
  }

  Future<void> _pickAndProcessFile(
    BuildContext context, {
    required List<String> allowedExtensions,
    required Future<void> Function(String) processFunction,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result == null) {
      _showWarningDialog(context, 'No se seleccionó ningún archivo.');
      return;
    }

    final filePath = result.files.single.path!;
    final fileName =
        result.files.single.name; // Nombre del archivo seleccionado
    final dialogContext =
        _showLoadingDialog(context, fileName); // Pasamos el nombre del archivo

    try {
      await processFunction(filePath);
      Navigator.pop(dialogContext);
      _showSuccessDialog(
          context, 'Archivo procesado y datos guardados en la base de datos.');
    } catch (e) {
      Navigator.pop(dialogContext);
      _showErrorDialog(
          context, 'Ocurrió un problema al procesar el archivo: $e');
    }
  }

  // Future<void> _pickAndProcessFileExel(
  //   BuildContext context,
  // ) async {
  //   final result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['xlsx'],
  //   );

  //   if (result == null) {
  //     _showWarningDialog(context, 'No se seleccionó ningún archivo.');
  //     return;
  //   }

  //   final filePath = result.files.single.path!;
  //   final dialogContext = _showLoadingDialog(context);

  //   try {
  //     await _processExcelReport(filePath);
  //     Navigator.pop(dialogContext);
  //     _showSuccessDialog(
  //         context, 'Archivo procesado y datos guardados en la base de datos.');
  //   } catch (e) {
  //     Navigator.pop(dialogContext);
  //     _showErrorDialog(
  //         context, 'Ocurrió un problema al procesar el archivo: $e');
  //   }
  // }

  BuildContext _showLoadingDialog(BuildContext context, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 15),
              Text(
                'Procesando: $fileName',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Por favor, espera mientras procesamos el archivo.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return context;
  }

  Future<void> _showDialogSelectedTimAction(BuildContext context,
      {required String action}) async {
    List<int> tims = await DatabaseHelper.instance.getTims();
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
                  Text(action == 'eliminar'
                      ? "Elige una TIM para eliminar:"
                      : "Elige una TIM en la que vas a trabajar:"),
                  const SizedBox(height: 20),

                  // Generar un RadioListTile para cada TIM
                  ...tims.map((tim) {
                    return RadioListTile<int>(
                      title: Text("TIM: $tim"),
                      value: tim,
                      groupValue: selectedTim,
                      onChanged: (value) {
                        setState(() => selectedTim = value);
                      },
                    );
                  }).toList(),
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
                      if (action == 'eliminar') {
                        // Si es la acción de eliminar
                        DatabaseHelper.instance.deleteReportes(selectedTim!);
                      } else {
                        // Si es la acción de trabajar
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductosReporteScreen(
                              selectedTim: selectedTim!,
                            ),
                          ),
                        );
                      }
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
  }

  // void _showFileTypeSelectionDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Seleccionar tipo de archivo'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           _buildFileTypeTile(
  //             context: context,
  //             icon: Icons.receipt_long,
  //             title: 'Reporte TIM',
  //             subtitle: 'Archivo Excel (.xlsx)',
  //             onTap: () => _handleTimReportSelection(context),
  //           ),
  //           const Divider(),
  //           _buildFileTypeTile(
  //             context: context,
  //             icon: Icons.stacked_line_chart,
  //             title: 'Profundidad',
  //             subtitle: 'Archivo CSV (.csv)',
  //             onTap: () => _handleDepthReportSelection(context),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFileTypeTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.verdeClaro),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context); // Cerrar diálogo
        onTap();
      },
    );
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
              AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                title: 'Confirmación',
                desc: '¿Estás seguro de que deseas eliminar todos los datos?',
                btnCancelOnPress: () {},
                btnOkOnPress: () async {
                  await DatabaseHelper.instance.deleteAllReports();
                  _showSuccessDialog(context,
                      'Todos los datos han sido eliminados correctamente.');
                },
              ).show();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: <Widget>[
            CustomGridCard(
              icon: Icon(Icons.receipt_long,
                  size: 40, color: AppColors.verdeClaro),
              title: 'Subir Reporte Tim',
              onTap: (context) => _handleTimReportSelection(context),
            ),

            // CustomGridCard(
            //   icon: Icon(Icons.upload_file,
            //       size: 40, color: AppColors.verdeClaro),
            //   title: 'Subir Archivos',
            //   onTap: (context) => _showFileTypeSelectionDialog(context),
            // ),
            CustomGridCard(
                icon: Icon(Icons.list, size: 40, color: AppColors.verdeClaro),
                title: 'Registro de\nRecepción',
                onTap: (context) =>
                    _showDialogSelectedTimAction(context, action: 'trabajar')),
            CustomGridCard(
              customIcon: const Text(
                '≠',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.verdeClaro,
                ),
              ),
              title: 'Discrepancias',
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DiscrepanciasScreen()),
              ),
            ),

            CustomGridCard(
              icon: Icon(Icons.task_alt, size: 40, color: AppColors.verdeClaro),
              title: 'Terminar Recepción',
              onTap: (context) =>
                  _showDialogSelectedTimAction(context, action: 'eliminar'),
            ),

            CustomGridCard(
              icon:
                  Icon(Icons.handshake, size: 40, color: AppColors.verdeClaro),
              title: 'Donaciones',
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductListScreen()),
              ),
            ),

            CustomGridCard(
              icon:
                  Icon(Icons.data_usage, size: 40, color: AppColors.verdeClaro),
              title: 'Data Maestro',
              onTap: (context) => _handleTimReportSelection(context),
            ),

            CustomGridCard(
              icon: Icon(Icons.stacked_line_chart,
                  size: 40, color: AppColors.verdeClaro),
              title: 'Subir Profundidad',
              onTap: (context) => _handleDepthReportSelection(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    _showAwesomeDialog(
      context,
      type: DialogType.success,
      title: 'Éxito',
      desc: message,
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    _showAwesomeDialog(
      context,
      type: DialogType.error,
      title: 'Error',
      desc: message,
    );
  }

  void _showWarningDialog(BuildContext context, String message) {
    _showAwesomeDialog(
      context,
      type: DialogType.warning,
      title: 'Advertencia',
      desc: message,
    );
  }

  void _showAwesomeDialog(
    BuildContext context, {
    required DialogType type,
    required String title,
    required String desc,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
    ).show();
  }
}
