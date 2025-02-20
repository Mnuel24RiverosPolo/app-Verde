import 'dart:io';

import 'package:app_conteo/database_helper.dart';
import 'package:app_conteo/model/producto_model.dart';
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

class ProductosReporteScreen extends StatefulWidget {
  final int selectedTim;

  const ProductosReporteScreen({Key? key, required this.selectedTim})
      : super(key: key);

  @override
  _ProductosReporteScreen createState() => _ProductosReporteScreen();
}

class _ProductosReporteScreen extends State<ProductosReporteScreen> {
  List<Reporte> _productos = [];
  List<Reporte> _productosFiltrados = [];
  String? _descripcionFiltro;
  String? _eanFiltro;
  String? _subDeptFiltro;
  bool _filtrosVisbles = true;

  bool activarTodo = false;

  Producto? _productoGenernal;
  // bool _seleccionarTodos = false;

  List<ReporteTim> reportesInfo = [];

  TextEditingController _dateDesdeController = TextEditingController();
  TextEditingController _dateHastaController = TextEditingController();
  TextEditingController _codigoController = TextEditingController();
  TextEditingController _descController = TextEditingController();
  DateTime? _selectedDesdeDate;
  DateTime? _selectedHastaDate;

  List<String> _subDeptOptions = [];

  final TextEditingController _controllerAddTim = TextEditingController();

  double? unidadesAddTim;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await DatabaseHelper.instance
          .getReportesByTim(widget.selectedTim); //655247005
      final reporteInfo = await DatabaseHelper.instance.fetchReporteTim();

      setState(() {
        _productos = productos;
        _subDeptOptions = productos
            .map((item) => item.subdpto) // Extrae los subdepartamentos/thiss
            .toSet() // Elimina duplicados
            .toList(); // Convierte de nuevo a lista
        _productosFiltrados = productos;
        reportesInfo = reporteInfo;
      });
    } catch (error) {
      print('Error al cargar productos: $error');
    }
  }

  Future<void> _reCargaProductos() async {
    try {
      final productos = await DatabaseHelper.instance.getReportes();

      setState(() {
        _productos = productos;
        _subDeptOptions = productos
            .map((item) => item.subdpto) // Extrae los subdepartamentos/thiss
            .toSet() // Elimina duplicados
            .toList(); // Convierte de nuevo a lista
        _productosFiltrados = productos;
      });
    } catch (error) {
      print('Error al cargar productos: $error');
    }
  }

  void _actualizarFiltro() async {
    setState(() {
      _productosFiltrados = _productos.where((item) {
        bool descripcionMatch = _descripcionFiltro == null ||
            item.descripcion
                .toLowerCase()
                .contains(_descripcionFiltro!.toLowerCase());

        // Filtro de EAN
        bool eanMatch = _eanFiltro == null || _eanFiltro!.length <= 8
            ? item.sku.contains(_eanFiltro ?? '')
            : item.ean.contains(_eanFiltro ?? '');

        // Filtro de SubDepartamento
        bool subDeptMatch = _subDeptFiltro == null ||
            item.subdpto.toLowerCase().contains(_subDeptFiltro!.toLowerCase());

        // Filtro de fecha desde
        // bool desdeMatch = true;
        // if (_selectedDesdeDate != null) {
        //   if (item.fechavencimiento != "dd/mm/yy" &&
        //       item.fechavencimiento != null &&
        //       item.fechavencimiento.isNotEmpty) {
        //     DateTime fechaVencimiento = _convertirFecha(item.fechavencimiento);
        //     desdeMatch = fechaVencimiento.isAfter(_selectedDesdeDate!);
        //   } else {
        //     desdeMatch == false;
        //   }
        // }

        // Filtro de fecha hasta
        // bool hastaMatch = true;
        // if (_selectedHastaDate != null) {
        //   if (item.fechavencimiento != "dd/mm/yy" &&
        //       item.fechavencimiento != null &&
        //       item.fechavencimiento.isNotEmpty) {
        //     DateTime fechaVencimiento = _convertirFecha(item.fechavencimiento);
        //     hastaMatch = fechaVencimiento.isBefore(_selectedHastaDate!);
        //   } else {
        //     hastaMatch = false;
        //   }
        // }

        // Combinamos todos los filtros
        return descripcionMatch && eanMatch && subDeptMatch;
      }).toList();

      // List<Reporte> productosConRecibidosCero =
      //     _productosFiltrados.where((item) => item.recibidos == 0).toList();
      // List<Reporte> productosConRecibidosNoCero =
      //     _productosFiltrados.where((item) => item.recibidos != 0).toList();

      // // Luego, ordena ambas listas alfabéticamente por descripción
      // productosConRecibidosCero
      //     .sort((a, b) => a.descripcion.compareTo(b.descripcion));
      // productosConRecibidosNoCero
      //     .sort((a, b) => a.descripcion.compareTo(b.descripcion));

      // // Combina ambas listas: primero los productos con recibidos == 0, luego los demás
      // _productosFiltrados =
      //     productosConRecibidosCero + productosConRecibidosNoCero;
    });

    if (_productosFiltrados.isEmpty) {
      final productoGenal = await DatabaseHelper.instance
          .getProductobyEan(_eanFiltro ?? ''); // 7750474000404
      setState(() {
        _productoGenernal = productoGenal;
      });
    }
  }

  Future<void> _cambiarEstadoMasa() async {
    // Mostrar el cuadro de confirmación
    bool confirmar = await _mostrarConfirmacion();

    if (confirmar) {
      // Realizar las acciones de actualización para todos los productos
      for (var producto in _productosFiltrados) {
        bool result;
        //if (activarTodo) {
        // Si activarTodo es true, activamos el switch
        result = await DatabaseHelper.instance
            .updateRecibidos(producto.id ?? 0, producto.unidades);
        //}

        // else {
        //   // Si activarTodo es false, desactivamos el switch
        //   result = await DatabaseHelper.instance
        //       .updateRecibidos(producto.id ?? 0, 0);
        // }

        // Si la actualización fue exitosa, actualizamos el estado del producto
        if (result) {
          setState(() {
            producto.fastRegister = true;
            //  producto.fastRegister = activarTodo;
            producto.recibidos = producto.unidades;
          });
        } else {
          _showAlert('Error al actualizar los datos.');
          break; // Si ocurre un error, detenemos el proceso
        }
      }
    }
  }

  Future<bool> _mostrarConfirmacion() async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Confirmación'),
              content: Text(
                  '¿Estás seguro de que quieres  registras todos los productos?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Regresar false al cerrar el diálogo
                  },
                ),
                TextButton(
                  child: Text('Confirmar'),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(true); // Regresar true al confirmar
                  },
                ),
              ],
            );
          },
        )) ??
        false; // Si showDialog retorna null, retornamos false por defecto
  }

  // void _showAlert(String mensaje) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Alerta'),
  //         content: Text(mensaje),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text('OK'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> _selectDesdeDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDesdeDate) {
      setState(() {
        _selectedDesdeDate = picked;
        _dateDesdeController.text =
            DateFormat('yyyy-MM-dd').format(picked); // Formato de fecha
      });
      _actualizarFiltro();
    }
  }

  Future<void> _selectHastaDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedHastaDate) {
      setState(() {
        _selectedHastaDate = picked;
        _dateHastaController.text =
            DateFormat('yyyy-MM-dd').format(picked); // Formato de fecha
      });

      _actualizarFiltro();
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      barrierDismissible:
          false, // Evita que el usuario cierre el dialog tocando fuera de él
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(
                  'Cargando...'), // Mensaje que se puede modificar según sea necesario
            ],
          ),
        );
      },
    );
  }

  Future<void> _insertarProductoSobrante(Producto productoSobrante) async {
    // Mostrar el dialog con el indicador de carga
    //_showLoadingDialog(context);

    try {
      // Crear el reporte a insertar
      final reporte = Reporte(
        olpn: '',
        pallet: '',
        tipoInventario: '',
        tipoSku: '',
        subdpto: '',
        sku: productoSobrante.sku,
        descripcion: productoSobrante.descripcion,
        casePack: productoSobrante.casePack,
        unidades: 0,
        cajas: 0.0,
        ean: productoSobrante.ean,
        recibidos: unidadesAddTim ?? 0.0,
        fechavencimiento: '',
        faltantes: '',
      );

      // Insertar el reporte
      await DatabaseHelper.instance.insertReportSinR(reporte);

      // Recargar los productos y actualizar los filtros
      await _reCargaProductos();
      _actualizarFiltro();

      // Si todo fue bien, mostrar el AwesomeDialog de éxito
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        headerAnimationLoop: false,
        title: 'Éxito',
        desc: 'El producto fue agregado como sobrante exitosamente.',
        btnOkOnPress: () {},
      ).show();
    } catch (e) {
      // Si hubo un error, mostrar el AwesomeDialog de error
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        headerAnimationLoop: false,
        title: 'Error',
        desc: 'Hubo un problema al agregar el producto como sobrante. $e',
        btnOkOnPress: () {},
      ).show();
    }

    //  finally {
    //   Navigator.of(context).pop();
    // }
  }

  DateTime _convertirFecha(String fecha) {
    // Suponemos que el formato es "dd/MM/yyyy"
    List<String> partesFecha = fecha.split('/');
    return DateTime(
      int.parse(partesFecha[2]), // Año
      int.parse(partesFecha[1]), // Mes
      int.parse(partesFecha[0]), // Día
    );
  }

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

  void _showExportDialog(BuildContext context) async {
    final TextEditingController _textController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportar Reporte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tim: ${widget.selectedTim}'),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Ingrese nombre de OT',
                  hintText: 'Ingrese nombre de OT',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                )),
            ElevatedButton(
                onPressed: () async {
                  final String nombreUsuario = _textController.text;

                  if (nombreUsuario.isNotEmpty) {
                    _cargarProductos();
                    String filePath =
                        await exportToExcel(_productos, nombreUsuario);

                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.success,
                      animType: AnimType.scale,
                      title: 'Archivo exportado',
                      desc: 'El archivo ha sido guardado en: $filePath',
                      btnOkOnPress: () {
                        Navigator.of(context).pop();
                      },
                    ).show();
                  } else {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.warning,
                      animType: AnimType.scale,
                      title: 'Ingrese su Nombre OT',
                      desc: 'Es necesario Nombre OT',
                      btnOkOnPress: () {
                        // Puedes agregar alguna acción extra si lo deseas al presionar "Aceptar"
                        // En este caso, solo cerramos el diálogo.
                      },
                    ).show();
                  }
                },
                child: const Text(
                  'Aceptar',
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

  Future<String> exportToExcel(List<Reporte> reports, String nombre) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    //Sheet sheet = excel['Reportes'];
    sheet.appendRow(['Nombre: ', nombre]);
    sheet.appendRow(['Tim: ', reportesInfo.first.tim]);
    sheet.appendRow(['Placa: ', reportesInfo.first.placa]);
    sheet.appendRow(['Origen: ', reportesInfo.first.localOrigen]);
    sheet.appendRow(['Destino: ', reportesInfo.first.localDestino]);
    sheet.appendRow(['Fecha envío: ', reportesInfo.first.fechaEnvio]);

    // Agregar un espacio antes de los encabezados
    sheet.appendRow(['']);

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

    for (var report in reports) {
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

    String fileName = 'TIM_${reportesInfo.first.tim}_$formattedDate.xlsx';

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
      //print('Archivo guardado en: $filePath');
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
        title: Text('Productos', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.verdeClaro,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.white), // Icono de retroceso
          onPressed: () {
            Navigator.of(context).pop(); // Regresa a la pantalla anterior
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                // setState(() {
                //   activarTodo = !activarTodo;
                // });

                // Llamar la función para cambiar el estado de todos
                _cambiarEstadoMasa();
              },
              icon: Icon(Icons.check)),
          IconButton(
            icon: _filtrosVisbles
                ? Icon(Icons.filter_list_off)
                : Icon(Icons.filter_list),
            onPressed: () => {
              setState(() {
                _filtrosVisbles = !_filtrosVisbles;
              })
            },
            //tooltip: '',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
            // tooltip: 'Exportar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TIM:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(widget.selectedTim.toString(),
                    style: TextStyle(fontSize: 18))
              ],
            ),
            SizedBox(height: 15),
            Visibility(
                visible: _filtrosVisbles,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // SizedBox(height: 25),
                        Expanded(
                          child: TextFormField(
                            controller: _descController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              labelText: 'Descripción',
                              filled: false,
                              fillColor: Colors.grey[200],
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 8.0),
                              suffixIcon: IconButton(
                                icon: _descripcionFiltro == null ||
                                        _descripcionFiltro!.isEmpty
                                    ? Icon(
                                        Icons.description,
                                        color: Colors.amber,
                                      )
                                    : Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                onPressed: () async {
                                  if (_descripcionFiltro != null ||
                                      _descripcionFiltro!.isEmpty) {
                                    setState(() {
                                      _descController.clear();
                                      _descripcionFiltro = null;
                                      _actualizarFiltro();
                                    });
                                  }
                                },
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _descripcionFiltro = value;
                              });
                              _actualizarFiltro();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codigoController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.amber),
                              ),
                              suffixIcon: IconButton(
                                icon: _eanFiltro == null || _eanFiltro!.isEmpty
                                    ? Icon(
                                        Icons.qr_code,
                                        color: Colors.amber,
                                      )
                                    : Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                onPressed: () async {
                                  if (_eanFiltro == null ||
                                      _eanFiltro!.isEmpty) {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BarcodeScannerSimple(),
                                      ),
                                    );

                                    if (result != null) {
                                      setState(() {
                                        _codigoController.text = result;
                                        _eanFiltro = result.toString().trim();
                                      });
                                      _actualizarFiltro();
                                    }
                                  } else {
                                    setState(() {
                                      _codigoController.clear();
                                      _eanFiltro = null;
                                    });
                                    _actualizarFiltro();
                                  }
                                },
                              ),
                              labelText: 'Sku/Ean',
                              filled: false,
                              fillColor: Colors.grey[200],
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 8.0),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _eanFiltro = value;
                              });
                              _actualizarFiltro();
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Autocomplete<String>(
                            initialValue: TextEditingValue(
                                text: _subDeptFiltro ?? ''), // Valor inicial
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              return _subDeptOptions.where((option) {
                                return option.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase());
                              }).toList(); // Filtra las opciones a medida que el usuario escribe
                            },
                            onSelected: (selectedOption) {
                              setState(() {
                                _subDeptFiltro =
                                    selectedOption; // Al seleccionar una opción, se actualiza el filtro
                              });
                              _actualizarFiltro();
                            },
                            fieldViewBuilder: (context, controller, focusNode,
                                onFieldSubmitted) {
                              // Asegúrate de devolver el TextField correctamente
                              return TextField(
                                controller:
                                    controller, // Usa el controlador del Autocomplete
                                focusNode: focusNode, // Asigna el focusNode
                                decoration: InputDecoration(
                                  labelText: 'SubDept',
                                  suffixIcon: IconButton(
                                    icon: _subDeptFiltro == null
                                        ? Icon(
                                            Icons.place,
                                            color: Colors.amber,
                                          )
                                        : Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                    onPressed: () {
                                      if (_subDeptFiltro != null) {
                                        setState(() {
                                          controller.text = "Todos";
                                          _subDeptFiltro = null;
                                        });

                                        _actualizarFiltro();
                                      }
                                    },
                                  ),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 8.0),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _subDeptFiltro = value;
                                  });
                                  _actualizarFiltro();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    // SizedBox(height: 12),
                    // Row(
                    //   children: [
                    //     Text('Seleccionar Todos'),
                    //     Switch(
                    //       value: _seleccionarTodos,
                    //       onChanged: (value) async {
                    //         try {
                    //           // Usamos Future.wait para hacer todas las actualizaciones en paralelo
                    //           List<Future> updateTasks = [];

                    //           // Recorremos todos los productos y creamos las tareas para actualizar
                    //           for (var producto in _productosFiltrados) {
                    //             bool result = value
                    //                 ? await DatabaseHelper.instance
                    //                     .updateRecibidos(
                    //                         producto.id ?? 0, producto.unidades)
                    //                 : await DatabaseHelper.instance
                    //                     .updateRecibidos(producto.id ?? 0, 0);

                    //             // Agregamos la tarea al list de tareas
                    //             updateTasks.add(
                    //               Future.delayed(Duration.zero, () {
                    //                 if (result) {
                    //                   setState(() {
                    //                     producto.fastRegister = value;
                    //                     producto.recibidos =
                    //                         value ? producto.unidades : 0;
                    //                   });
                    //                 } else {
                    //                   _showAlert(
                    //                       'Error al actualizar los datos.');
                    //                 }
                    //               }),
                    //             );
                    //           }

                    //           // Esperamos a que todas las tareas se completen
                    //           await Future.wait(updateTasks);
                    //           if (value) {
                    //             setState(() {
                    //               _seleccionarTodos = true;
                    //             });
                    //           } else {
                    //             setState(() {
                    //               _seleccionarTodos = false;
                    //             });
                    //           }

                    //           // Aquí podrías agregar alguna lógica adicional si es necesario
                    //         } catch (e) {
                    //           // Si ocurre un error inesperado, mostramos una alerta.
                    //           _showAlert('Ocurrió un error: $e');
                    //         }
                    //       },
                    //     ),
                    //   ],
                    // ),

                    SizedBox(height: 12),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.start,
                    //   children: [
                    //     Text('Fecha Vecimiento: '),
                    //   ],
                    // ),
                    // SizedBox(height: 4),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: TextFormField(
                    //         controller: _dateDesdeController,
                    //         readOnly: true,
                    //         decoration: InputDecoration(
                    //           labelText: " Desde",
                    //           suffixIcon: IconButton(
                    //               icon: _dateDesdeController.text.isEmpty
                    //                   ? Icon(
                    //                       Icons.calendar_today,
                    //                       color: Colors.amber,
                    //                     )
                    //                   : Icon(
                    //                       Icons.close,
                    //                       color: Colors.red,
                    //                     ),
                    //               onPressed: () async {
                    //                 if (_dateDesdeController.text.isNotEmpty) {
                    //                   _dateDesdeController.clear();
                    //                   _selectedDesdeDate = null;
                    //                   _actualizarFiltro();
                    //                 } else {
                    //                   _selectDesdeDate(context);
                    //                 }
                    //               }),
                    //           border: OutlineInputBorder(),
                    //           contentPadding: EdgeInsets.symmetric(
                    //               vertical: 8.0, horizontal: 8.0),
                    //         ),
                    //         onTap: () => _selectDesdeDate(context),
                    //       ),
                    //     ),
                    //     SizedBox(width: 10),
                    //     Expanded(
                    //       child: TextFormField(
                    //         controller: _dateHastaController,
                    //         readOnly: true,
                    //         decoration: InputDecoration(
                    //           labelText: "Hasta ",
                    //           suffixIcon: IconButton(
                    //             icon: _dateHastaController.text.isEmpty
                    //                 ? Icon(
                    //                     Icons.calendar_today,
                    //                     color: Colors.amber,
                    //                   )
                    //                 : Icon(Icons.close, color: Colors.red),
                    //             onPressed: () async {
                    //               if (_dateHastaController.text.isNotEmpty) {
                    //                 _dateHastaController.clear();
                    //                 _selectedHastaDate = null;
                    //                 _actualizarFiltro();
                    //               } else {
                    //                 _selectHastaDate(context);
                    //               }
                    //             },
                    //           ),
                    //           border: OutlineInputBorder(),
                    //           contentPadding: EdgeInsets.symmetric(
                    //               vertical: 8.0, horizontal: 8.0),
                    //         ),
                    //         onTap: () => _selectHastaDate(context),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                )),
            Expanded(
              child: _productosFiltrados.isEmpty
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No se encontraron productos en la TIM',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 28),
                          if (_productoGenernal != null)
                            Card(
                              elevation: 6, // Sombra más pronunciada
                              color: Colors.blue[50], // Color de fondo suave
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    15), // Esquinas más redondeadas
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    16.0), // Espaciado interno
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Producto Encontrado en generales:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors
                                            .blue[800], // Color del título
                                      ),
                                    ),
                                    SizedBox(height: 10), // Espaciado
                                    Text(
                                      ' ${_productoGenernal!.descripcion}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Proveedor: ${_productoGenernal!.proveedor}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(widget.selectedTim.toString()),
                                    Row(
                                      children: [
                                        Text(
                                          'SKU: ${_productoGenernal!.sku}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'EAN: ${_productoGenernal!.ean}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Case Pack: ${_productoGenernal!.casePack}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _controllerAddTim,
                                            keyboardType: TextInputType
                                                .number, // Solo permite números
                                            decoration: InputDecoration(
                                              labelText: 'Unidades Contadas',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              // Convierte el valor a un número decimal (double) si es posible
                                              setState(() {
                                                // Intenta convertir el valor a un número decimal
                                                unidadesAddTim =
                                                    double.tryParse(value);
                                              });
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 15,
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            // Validar que el valor ingresado sea diferente de null y mayor que 0
                                            if (unidadesAddTim != null &&
                                                unidadesAddTim! > 0 &&
                                                _productoGenernal != null) {
                                              _insertarProductoSobrante(
                                                  _productoGenernal!);
                                            } else {
                                              // Mostrar un mensaje de error si el valor no es válido o es 0
                                              AwesomeDialog(
                                                context: context,
                                                dialogType: DialogType.error,
                                                headerAnimationLoop: false,
                                                title: 'Error',
                                                desc:
                                                    'Por favor, ingresa un valor mayor a 0 para las unidades contadas.',
                                                btnOkOnPress: () {},
                                              ).show();
                                            }
                                          },
                                          label: const Text(
                                            'Agregar a la TIM',
                                            style: TextStyle(
                                                color: AppColors.white),
                                          ),
                                          //icon: Icon(Icons.add),
                                          style: TextButton.styleFrom(
                                            backgroundColor: AppColors
                                                .verdeOs, // Color de fondo
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Se agregará automáticamente a la TIM como sobrante.',
                                      style: TextStyle(fontSize: 10),
                                    )
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            height: _filtrosVisbles ? 500 : 615,
                            child: ListView.builder(
                              itemCount: _productosFiltrados.length,
                              itemBuilder: (context, index) {
                                var producto = _productosFiltrados[index];
                                return Card(
                                  elevation:
                                      4, // Agrega una sombra para el estilo
                                  // margin: const EdgeInsets.symmetric(
                                  //     vertical: 8.0,
                                  //     horizontal: 16.0), // Ajusta los márgenes
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // Redondea las esquinas del card
                                  ),
                                  child: ListTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        Switch(
                                            value: producto.fastRegister, //
                                            activeColor: AppColors.verdeClaro,
                                            onChanged: (value) async {
                                              try {
                                                // Primero esperamos la actualización en la base de datos.
                                                if (value) {
                                                  // Si el Switch está activado, actualizamos en la base de datos.
                                                  bool result =
                                                      await DatabaseHelper
                                                          .instance
                                                          .updateRecibidos(
                                                              producto.id ?? 0,
                                                              producto
                                                                  .unidades);

                                                  // Verificamos si la actualización fue exitosa.
                                                  if (result) {
                                                    // Si fue exitosa, actualizamos el estado.
                                                    setState(() {
                                                      producto.fastRegister =
                                                          true;
                                                      producto.recibidos =
                                                          producto.unidades;
                                                    });
                                                  } else {
                                                    // Si no fue exitosa, mostramos una alerta.
                                                    _showAlert(
                                                        'Error al actualizar los datos.');
                                                  }
                                                } else {
                                                  // Si el Switch está desactivado, actualizamos en la base de datos.
                                                  bool result =
                                                      await DatabaseHelper
                                                          .instance
                                                          .updateRecibidos(
                                                              producto.id ?? 0,
                                                              0);

                                                  // Verificamos si la actualización fue exitosa.
                                                  if (result) {
                                                    // Si fue exitosa, actualizamos el estado.
                                                    setState(() {
                                                      producto.recibidos = 0;
                                                      producto.fastRegister =
                                                          false;
                                                    });
                                                  } else {
                                                    // Si no fue exitosa, mostramos una alerta.
                                                    _showAlert(
                                                        'Error al actualizar los datos.');
                                                  }
                                                }
                                              } catch (e) {
                                                // Si ocurre un error inesperado, mostramos una alerta.
                                                _showAlert(
                                                    'Ocurrió un error: $e');
                                              }
                                            })

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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Sku:  ${producto.sku ?? 'Sin SKU'}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    'Ean:  ${producto.ean ?? 'Sin Ean'}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                          text:
                                                              'Cajas: ', // Texto fijo
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold, // Negrita
                                                                  color: Colors
                                                                      .black, // Color del texto
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    '${producto.recibidos.toString()}', // Texto variable
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
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
                                                                  producto
                                                                      .unidades
                                                              ? Icons.check
                                                              : Icons
                                                                  .warning, // Usamos un ícono diferente dependiendo del color
                                                          color: producto
                                                                      .recibidos ==
                                                                  producto
                                                                      .unidades
                                                              ? Colors
                                                                  .green // Verde cuando las unidades coinciden
                                                              : producto.recibidos >
                                                                          0 &&
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
                                height: 40, // Altura del contenedor
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        20), // Agregar padding horizontal
                                margin: EdgeInsets.all(
                                    10), // Margen alrededor del contenedor
                                decoration: BoxDecoration(
                                  color: Colors
                                      .purple, // Color de fondo del contenedor
                                  borderRadius: BorderRadius.circular(
                                      15), // Bordes redondeados
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26, // Sombra sutil
                                      blurRadius: 8, // Difusión de la sombra
                                      offset: Offset(
                                          0, 4), // Dirección de la sombra
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Centrado horizontal
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center, // Centrado vertical
                                  children: [
                                    Text(
                                      'Cajas: ${(_productosFiltrados.fold(0.0, (previousValue, producto) => previousValue + (producto.cajas ?? 0.0))).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors
                                            .white, // Color blanco para el texto
                                        fontSize: 14, // Tamaño de la fuente
                                        fontWeight: FontWeight
                                            .bold, // Hacer el texto en negrita
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                height: 40, // Altura del contenedor
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        20), // Agregar padding horizontal
                                margin: EdgeInsets.all(
                                    10), // Margen alrededor del contenedor
                                decoration: BoxDecoration(
                                  color: Colors
                                      .blue, // Color de fondo del contenedor
                                  borderRadius: BorderRadius.circular(
                                      15), // Bordes redondeados
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26, // Sombra sutil
                                      blurRadius: 8, // Difusión de la sombra
                                      offset: Offset(
                                          0, 4), // Dirección de la sombra
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Centrado horizontal
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center, // Centrado vertical
                                  children: [
                                    // Icon(Icons.info_outline,
                                    //     color: Colors.white), // Icono al inicio
                                    // SizedBox(
                                    //     width: 8), // Espacio entre el icono y el texto
                                    Text(
                                      'Productos: ${_productosFiltrados.length}', // El texto que muestra el total
                                      style: TextStyle(
                                        color: Colors
                                            .white, // Color blanco para el texto
                                        fontSize: 14, // Tamaño de la fuente
                                        fontWeight: FontWeight
                                            .bold, // Hacer el texto en negrita
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlert(String message) {
    AwesomeDialog(
      context: context,
      dialogType:
          DialogType.error, // Tipo de diálogo (error, info, success, etc.)
      animType: AnimType.scale, // Tipo de animación (puedes elegir diferentes)
      title: 'Error', // Título del diálogo
      desc: message, // Descripción (el mensaje de error)
      btnOkOnPress: () {
        // Acción cuando se presiona el botón 'OK'
      },
      btnOkText: 'OK', // Texto del botón
    )..show();
  }
}
