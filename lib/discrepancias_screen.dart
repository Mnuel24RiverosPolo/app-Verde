import 'dart:io';

import 'package:app_conteo/database_helper.dart';
import 'package:app_conteo/model/reporteTim_model.dart';
import 'package:app_conteo/model/reporte_model.dart';
import 'package:app_conteo/reporte_detail_screen.dart';
import 'package:app_conteo/screens/qr/mobile_scanner.dart';
import 'package:app_conteo/utils/app_colors.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class DiscrepanciasScreen extends StatefulWidget {
  @override
  _DiscrepanciasScreen createState() => _DiscrepanciasScreen();
}

class _DiscrepanciasScreen extends State<DiscrepanciasScreen> {
  List<Reporte> _productos = [];
  List<Reporte> _productosFiltrados = [];
  List<Reporte> _productosFaltantes = [];
  List<Reporte> _productosSobrantes = [];
  // String? _descripcionFiltro;
  // String? _eanFiltro;
  // String? _subDeptFiltro;
  // bool _filtrosVisbles = true;
  bool _isFaltantesSelected =
      true; // Para saber si 'Faltantes' está seleccionado
  bool _isSobrantesSelected = false;

  List<ReporteTim> reportesInfo = [];

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _textControllerConductor =
      TextEditingController();
  final TextEditingController _textControllerContador = TextEditingController();

  // TextEditingController _dateDesdeController = TextEditingController();
  // TextEditingController _dateHastaController = TextEditingController();
  // TextEditingController _codigoController = TextEditingController();
  // TextEditingController _descController = TextEditingController();
  // DateTime? _selectedDesdeDate;
  // DateTime? _selectedHastaDate;

  ///List<String> _subDeptOptions = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await DatabaseHelper.instance.getReportes();
      final reporteInfo = await DatabaseHelper.instance.fetchReporteTim();

      setState(() {
        _productos = productos;
        _productosFaltantes = productos.where((item) {
          return item.unidades > item.recibidos;
        }).toList();
        _productosSobrantes = productos.where((item) {
          return item.unidades < item.recibidos;
        }).toList();

        _productosFiltrados = productos;
        reportesInfo = reporteInfo;
      });
    } catch (error) {
      print('Error al cargar productos: $error');
    }
  }

  // void _actualizarFiltro() {
  //   setState(() {
  //     _productosFiltrados = _productos.where((item) {
  //       bool descripcionMatch = _descripcionFiltro == null ||
  //           item.descripcion
  //               .toLowerCase()
  //               .contains(_descripcionFiltro!.toLowerCase());

  //       // Filtro de EAN
  //       bool eanMatch = _eanFiltro == null || item.ean.contains(_eanFiltro!);

  //       // Filtro de SubDepartamento
  //       bool subDeptMatch = _subDeptFiltro == null ||
  //           item.subdpto.toLowerCase().contains(_subDeptFiltro!.toLowerCase());

  //       // Filtro de fecha desde
  //       bool desdeMatch = true;
  //       if (_selectedDesdeDate != null) {
  //         if (item.fechavencimiento != "dd/mm/yy" &&
  //             item.fechavencimiento != null &&
  //             item.fechavencimiento.isNotEmpty) {
  //           DateTime fechaVencimiento = _convertirFecha(item.fechavencimiento);
  //           desdeMatch = fechaVencimiento.isAfter(_selectedDesdeDate!);
  //         } else {
  //           desdeMatch == false;
  //         }
  //       }

  //       // Filtro de fecha hasta
  //       bool hastaMatch = true;
  //       if (_selectedHastaDate != null) {
  //         if (item.fechavencimiento != "dd/mm/yy" &&
  //             item.fechavencimiento != null &&
  //             item.fechavencimiento.isNotEmpty) {
  //           DateTime fechaVencimiento = _convertirFecha(item.fechavencimiento);
  //           hastaMatch = fechaVencimiento.isBefore(_selectedHastaDate!);
  //         } else {
  //           hastaMatch = false;
  //         }
  //       }

  //       // Combinamos todos los filtros
  //       return descripcionMatch &&
  //           eanMatch &&
  //           subDeptMatch &&
  //           desdeMatch &&
  //           hastaMatch;
  //     }).toList();
  //   });
  // }

  // Future<void> _selectDesdeDate(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2101),
  //   );
  //   if (picked != null && picked != _selectedDesdeDate) {
  //     setState(() {
  //       _selectedDesdeDate = picked;
  //       _dateDesdeController.text =
  //           DateFormat('yyyy-MM-dd').format(picked); // Formato de fecha
  //     });
  //     _actualizarFiltro();
  //   }
  // }

  // Future<void> _selectHastaDate(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2101),
  //   );
  //   if (picked != null && picked != _selectedHastaDate) {
  //     setState(() {
  //       _selectedHastaDate = picked;
  //       _dateHastaController.text =
  //           DateFormat('yyyy-MM-dd').format(picked); // Formato de fecha
  //     });

  //     _actualizarFiltro();
  //   }
  // }

  // DateTime _convertirFecha(String fecha) {
  //   // Suponemos que el formato es "dd/MM/yyyy"
  //   List<String> partesFecha = fecha.split('/');
  //   return DateTime(
  //     int.parse(partesFecha[2]), // Año
  //     int.parse(partesFecha[1]), // Mes
  //     int.parse(partesFecha[0]), // Día
  //   );
  // }

  void _showReportDetails(BuildContext context, Reporte report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportDetailsDialog(
          report: report,
          onSave: () async {
            _cargarProductos();
            // reportes = await _loadReports();
            // _filterReports("");
          },
        );
      },
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Completar Datos'),
          content: SizedBox(
            height: 200,
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Empresa Transporte',
                    hintText: '',
                  ),
                ),
                TextField(
                  controller: _textControllerConductor,
                  decoration: const InputDecoration(
                    labelText: 'Conductor',
                  ),
                ),
                TextField(
                  controller: _textControllerContador,
                  decoration: const InputDecoration(
                    labelText: 'Contador',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                )),
            ElevatedButton(
                onPressed: () async {
                  final String nombreUsuario = _textController.text;
                  final String conductor = _textControllerConductor.text;
                  final String contador = _textControllerContador.text;
                  final String fechaEnvio = reportesInfo.first.fechaEnvio;
                  final String origen = reportesInfo.first.localOrigen;
                  final String destino = reportesInfo.first.localDestino;
                  final String placa = reportesInfo.first.placa;
                  final String tim = reportesInfo.first.tim.toString();
                  final String discrepancias =
                      (_productosFaltantes.length + _productosSobrantes.length)
                          .toString();

                  if (nombreUsuario.isNotEmpty &&
                      conductor.isNotEmpty &&
                      contador.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirmar'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Empresa Transporte: $nombreUsuario'),
                              Text('Conductor: $conductor'),
                              Text('Contador: $contador'),
                              Text('Fecha Envío: $fechaEnvio'),
                              Text('Origen: $origen'),
                              Text('Destino: $destino'),
                              Text('Placa: $placa'),
                              Text('TIM: $tim'),
                              Text('Discrepancias: $discrepancias'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                String filePath = await exportToExcel();
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.success,
                                  animType: AnimType.scale,
                                  title: 'Archivo exportado',
                                  desc:
                                      'El archivo ha sido guardado en: $filePath',
                                  btnOkOnPress: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                ).show();
                              },
                              child: Text(
                                'Todo Ok ',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    //quieor que me muestre denuevo otro dialog conla informacion auqe acabo de ingresar
                  } else {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.warning,
                      animType: AnimType.scale,
                      title: 'Ingrese su Nombre ',
                      desc: 'Es necesario Nombre',
                      btnOkOnPress: () {
                        // Puedes agregar alguna acción extra si lo deseas al presionar "Aceptar"
                        // En este caso, solo cerramos el diálogo.
                      },
                    ).show();
                  }
                },
                child: const Text(
                  'Continuar',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                )),
          ],
        );
      },
    );
  }

  Future<String> exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Información de los campos del formulario
    String empresaTransporte = _textController.text;
    String conductor = _textControllerConductor.text;
    String contador = _textControllerContador.text;

    // Información adicional
    String fechaEnvio = reportesInfo.first.fechaEnvio;
    String origen = reportesInfo.first.localOrigen;
    String destino = reportesInfo.first.localDestino;
    String placa = reportesInfo.first.placa;
    String tim = reportesInfo.first.tim.toString();
    String discrepancias =
        (_productosFaltantes.length + _productosSobrantes.length).toString();

    // Agregar la información del formulario al Excel
    sheet.appendRow(['Empresa de Transporte: ', empresaTransporte]);
    sheet.appendRow(['Conductor: ', conductor]);
    sheet.appendRow(['Contador: ', contador]);
    sheet.appendRow(['Fecha Envío: ', fechaEnvio]);
    sheet.appendRow(['Origen: ', origen]);
    sheet.appendRow(['Destino: ', destino]);
    sheet.appendRow(['Placa: ', placa]);
    sheet.appendRow(['TIM: ', tim]);
    sheet.appendRow(['Discrepancias: ', discrepancias]);

    // Agregar un espacio antes de los encabezados
    sheet.appendRow(['']);
    sheet.appendRow(['Productos Faltantes']);

    // Encabezado para los productos faltantes
    sheet.appendRow([
      'SKU',
      'Descripción',
      'Cajas',
      'Olpn',
      'Sub Departamento',
      'Unidades',
      'Ean',
      'U Recibidas',
      'Fecha Vencimiento',
    ]);

    // Agregar los productos faltantes
    for (var report in _productosFaltantes) {
      sheet.appendRow([
        report.sku ?? 'Sin SKU',
        report.descripcion ?? 'Sin Descripción',
        report.cajas ?? 0,
        report.olpn ?? 'Sin Olpn',
        report.subdpto ?? 'Sin Sub Departamento',
        report.unidades ?? 0,
        report.ean ?? 0,
        report.recibidos,
        report.fechavencimiento,
      ]);
    }

    // Agregar un espacio antes de los productos sobrantes
    sheet.appendRow(['']);
    sheet.appendRow(['Productos Sobrantes']);

    // Encabezado para los productos sobrantes
    sheet.appendRow([
      'SKU',
      'Descripción',
      'Cajas',
      'Tipo Inventario',
      'Sub Departamento',
      'Unidades',
      'Ean',
      'U Recibidas',
      'Fecha Vencimiento',
    ]);

    // Agregar los productos sobrantes
    for (var report in _productosSobrantes) {
      sheet.appendRow([
        report.sku ?? 'Sin SKU',
        report.descripcion ?? 'Sin Descripción',
        report.cajas ?? 0,
        report.tipoInventario ?? 'Sin Tipo',
        report.subdpto ?? 'Sin Sub Departamento',
        report.unidades ?? 0,
        report.ean ?? 0,
        report.recibidos,
        report.fechavencimiento,
      ]);
    }

    String formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    String fileName =
        'TIM_Discrepancias_${reportesInfo.first.tim}_$formattedDate.xlsx';

    try {
      final directory = await getExternalStorageDirectory();
      final downloadDirectory = Directory('/storage/emulated/0/Download');
      final filePath = '${downloadDirectory.path}/$fileName';

      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(recursive: true);
      }
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.save()!);

      // Mostrar una notificación al usuario
      print('Archivo guardado en: $filePath');
      return filePath; // Retorna la ubicación del archivo
    } catch (e) {
      return "Error $e";
    }
  }

  void _showOptionsMenu(BuildContext context) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(300, 92, 0, 0), // Posición del menú
      items: [
        PopupMenuItem(
          value: 1,
          child: Text('Mostrar Exportar'),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('Otra opción'),
        ),
      ],
    );

    switch (result) {
      case 1:
        _showExportDialog(context);
        //_showExportButton = true; // Mostrar el botón de exportar

        break;
      case 2:
        // Realiza alguna acción para otra opción si es necesario
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Discrepancias', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.verdeClaro,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.white), // Icono de retroceso
          onPressed: () {
            Navigator.of(context).pop(); // Regresa a la pantalla anterior
          },
        ),
        actions: [
          // IconButton(
          //   icon: _filtrosVisbles
          //       ? Icon(Icons.filter_list_off)
          //       : Icon(Icons.filter_list),
          //   onPressed: () => {
          //     setState(() {
          //       _filtrosVisbles = !_filtrosVisbles;
          //     })
          //   },
          //   //tooltip: '',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.more_vert),
          //   onPressed: () => _showOptionsMenu(context),
          //   // tooltip: 'Exportar',
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isFaltantesSelected =
                              true; // El botón 'Faltantes' se selecciona
                          _isSobrantesSelected =
                              false; // El botón 'Sobrantes' se deselecciona
                          // Filtra los productos donde 'unidades' es mayor que 'recibidos'
                          _productosFiltrados = _productos.where((item) {
                            return item.unidades > item.recibidos;
                          }).toList();
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _isFaltantesSelected
                            ? Colors.grey
                            : Colors.transparent, // Cambia el color de fondo
                        // primary: _isFaltantesSelected
                        //     ? Colors.white
                        //     : Colors.blue, // Cambia el color del texto
                      ),
                      child: Text('Faltantes'),
                    ),
                    SizedBox(width: 8), // Espacio entre los botones
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSobrantesSelected =
                              true; // El botón 'Sobrantes' se selecciona
                          _isFaltantesSelected =
                              false; // El botón 'Faltantes' se deselecciona
                          // Filtra los productos donde 'unidades' es menor que 'recibidos'
                          _productosFiltrados = _productos.where((item) {
                            return item.unidades < item.recibidos;
                          }).toList();
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _isSobrantesSelected
                            ? Colors.grey
                            : Colors.transparent, // Cambia el color de fondo
                        // : _isSobrantesSelected
                        //     ? Colors.white
                        //     : Colors.green, // Cambia el color del texto
                      ),
                      child: Text('Sobrantes'),
                    ),
                  ],
                ),

                Material(
                  color: AppColors.primary, // El color de fondo que deseas
                  borderRadius:
                      BorderRadius.circular(8), // Opcional: bordes redondeados
                  child: IconButton(
                    onPressed: () {
                      _showExportDialog(context);
                    },
                    icon: Row(
                      mainAxisSize: MainAxisSize
                          .min, // Evita que el Row ocupe todo el espacio
                      children: [
                        Text(
                          'Reportar',
                          style:
                              TextStyle(color: Colors.white), // Color del texto
                        ),
                        Icon(Icons.chevron_right,
                            color: Colors
                                .white), // Icono de la flecha hacia la derecha con color blanco
                      ],
                    ),
                  ),
                )

                // TextButton(
                //     onPressed: () {}, child: Text('Fecha de Fencimientos')),
              ],
            ),

            // ? const Center(child: CircularProgressIndicator())
            Column(
              children: [
                Container(
                  height: 600,
                  // constraints: const BoxConstraints(
                  //   maxHeight: 100, // Establece la altura máxima aquí
                  // ),
                  child: ListView.builder(
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (context, index) {
                      var producto = _productosFiltrados[index];
                      return Card(
                        elevation: 4, // Agrega una sombra para el estilo
                        // margin: const EdgeInsets.symmetric(
                        //     vertical: 8.0,
                        //     horizontal: 16.0), // Ajusta los márgenes
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  producto.descripcion.trim() ??
                                      'Sin descripción',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),

                              // Container(
                              //   padding: const EdgeInsets.symmetric(
                              //       horizontal: 8, vertical: 1),
                              //   decoration: BoxDecoration(
                              //     color: Colors.green,
                              //     borderRadius: BorderRadius.circular(8),
                              //   ),
                              //   child: const Text(
                              //     'Registrado',
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //     ),
                              //   ),
                              // )
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    Text(
                                      'Ean:  ${producto.ean ?? 'Sin SKU'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text:
                                                    'Sub Depto: ', // Texto fijo
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .bold, // Negrita
                                                  color: Colors
                                                      .black, // Color del texto
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${producto.subdpto}', // Texto variable
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .normal, // Normal
                                                  color: Colors
                                                      .black, // Color del texto
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Cajas: ', // Texto fijo
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .bold, // Negrita
                                                  color: Colors
                                                      .black, // Color del texto
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${producto.cajas}', // Texto variable
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .normal, // Normal
                                                  color: Colors
                                                      .black, // Color del texto
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text:
                                                    'Unidades: ', // Texto fijo
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .bold, // Negrita
                                                  color: Colors
                                                      .black, // Color del texto
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${producto.unidades}', // Texto variable
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .normal, // Normal
                                                  color: Colors
                                                      .black, // Color del texto
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (producto.recibidos != 0)
                                          Row(
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text:
                                                          'Registrados: ', // Texto fijo
                                                      style: TextStyle(
                                                        fontWeight: FontWeight
                                                            .bold, // Negrita
                                                        color: Colors
                                                            .black, // Color del texto
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${producto.recibidos.toString()}', // Texto variable
                                                      style: TextStyle(
                                                        fontWeight: FontWeight
                                                            .normal, // Normal
                                                        color: Colors
                                                            .black, // Color del texto
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                producto.recibidos ==
                                                        producto.unidades
                                                    ? Icons.check
                                                    : Icons
                                                        .warning, // Usamos un ícono diferente dependiendo del color
                                                color: producto.recibidos ==
                                                        producto.unidades
                                                    ? Colors
                                                        .green // Verde cuando las unidades coinciden
                                                    : producto.recibidos > 0 &&
                                                            producto.recibidos <
                                                                producto
                                                                    .unidades
                                                        ? Colors
                                                            .amber // Amarillo cuando hay más de 0 pero menos que el total
                                                        : Colors.red,
                                              ),
                                            ],
                                          ),

                                        // Container(
                                        //   padding:
                                        //       const EdgeInsets.symmetric(
                                        //           horizontal: 8,
                                        //           vertical: 1),
                                        //   decoration: BoxDecoration(
                                        //     color: producto.recibidos ==
                                        //             producto.unidades
                                        //         ? Colors
                                        //             .green // Verde cuando las unidades coinciden
                                        //         : producto.recibidos > 0 &&
                                        //                 producto.recibidos <
                                        //                     producto
                                        //                         .unidades
                                        //             ? Colors
                                        //                 .amber // Amarillo cuando hay más de 0 pero menos que el total
                                        //             : Colors
                                        //                 .red, // Rojo cuando no se han recibido unidades
                                        //     borderRadius:
                                        //         BorderRadius.circular(8),
                                        //   ),
                                        //   child: Row(
                                        //     children: [
                                        //       Icon(
                                        //         producto.recibidos ==
                                        //                 producto.unidades
                                        //             ? Icons.check
                                        //             : Icons
                                        //                 .warning, // Usamos un ícono diferente dependiendo del color
                                        //         color: Colors.white,
                                        //       ),
                                        //       Text(
                                        //         producto.recibidos
                                        //             .toString(),
                                        //         style: TextStyle(
                                        //             color: Colors.white),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Text(
                              //   'Registrado ',
                              //   style: const TextStyle(
                              //       color: Colors.white,
                              //       backgroundColor: Colors.green),
                              // ),
                            ],
                          ),

                          onTap: () {
                            _showReportDetails(context, producto);
                          },
                          // Agrega otras propiedades al ListTile si es necesario, como leading o trailing
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 50, // Altura del contenedor
                      padding: EdgeInsets.symmetric(
                          horizontal: 20), // Agregar padding horizontal
                      margin:
                          EdgeInsets.all(10), // Margen alrededor del contenedor
                      decoration: BoxDecoration(
                        color: Colors.blue, // Color de fondo del contenedor
                        borderRadius:
                            BorderRadius.circular(15), // Bordes redondeados
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26, // Sombra sutil
                            blurRadius: 8, // Difusión de la sombra
                            offset: Offset(0, 4), // Dirección de la sombra
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Centrado horizontal
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // Centrado vertical
                        children: [
                          // Icon(Icons.info_outline,
                          //     color: Colors.white), // Icono al inicio
                          // SizedBox(
                          //     width: 8), // Espacio entre el icono y el texto
                          Text(
                            'Total: ${_productosFiltrados.length}', // El texto que muestra el total
                            style: TextStyle(
                              color: Colors.white, // Color blanco para el texto
                              fontSize: 18, // Tamaño de la fuente
                              fontWeight:
                                  FontWeight.bold, // Hacer el texto en negrita
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
