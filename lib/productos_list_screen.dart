import 'dart:async';

import 'package:app_conteo/model/producto_model.dart';
import 'package:app_conteo/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart'; // Asegúrate de importar tu DatabaseHelper

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];

  List<String> _subDeptOptions = [];
  String? subclaseSeleccionada;
  String busquedaTexto = '';
  Timer? _debounce;
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() async {
    _cargarSubclases();
    productos = await DatabaseHelper.instance.getProductosFiltrados();
    setState(() {
      productosFiltrados = productos;
    });
  }

  Future<void> _cargarSubclases() async {
    try {
      final result = await DatabaseHelper.instance.getSubclasesUnicas();
      if (mounted) {
        setState(() => _subDeptOptions = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _subDeptOptions = []);
      }
    }
  }

  void _actualizarProductos() async {
    setState(() {
      productosFiltrados = productos.where((item) {
        bool subDeptnMatch = subclaseSeleccionada == null ||
            item.subclase.contains(subclaseSeleccionada!);

        bool descripcionMatch = busquedaTexto == '' ||
            item.descripcion.toLowerCase().contains(busquedaTexto);
        return subDeptnMatch && descripcionMatch;
      }).toList();
    });
  }

  Future<List<Producto>> _cargarProductos() async {
    try {
      final datos = await DatabaseHelper.instance
          .getProductosFiltrados(); // Función async
      setState(() => productos = datos);
      return datos;
    } catch (e) {
      // Maneja errores (ej: muestra un snackbar)
      throw Exception('Error al cargar: $e');
    }
  }

  void _handleSubDeptSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          subclaseSeleccionada = value.isEmpty ? null : value;
          _actualizarProductos();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.verdeClaro,
        title: const Text(
          'Donaciones',
          style: TextStyle(color: AppColors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.white), // Icono de retroceso
          onPressed: () {
            Navigator.of(context).pop(); // Regresa a la pantalla anterior
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSubDeptFilter(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildDescripcionSearch(),
          ),
          const SizedBox(height: 16),
          Expanded(
            // child: _buildProductList(),
            child: productosFiltrados.isEmpty
                ? const Text(
                    'No se encontraron productos en la TIM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  )
                : Scrollbar(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: productosFiltrados.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final producto = productosFiltrados[index];
                        return ListTile(
                          title: Text('${index + 1}. ${producto.descripcion}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ean: ${producto.ean}'),
                              Text('subdept: ${producto.subclase}'),
                            ],
                          ),
                          trailing: Text('Case Pack: ${producto.casePack}'),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          visualDensity: const VisualDensity(vertical: 2),
                          onTap: () =>{}
                             // _mostrarDialogoConfirmacion(context, producto),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // void _mostrarDialogoConfirmacion(BuildContext context, Producto producto) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Confirmar agregado'),
  //       content: Text('¿Estás seguro de agregar a la TIM ${producto.tim}?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancelar'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //            // _insertarEnReporteTIM(producto);
  //             Navigator.pop(context);
  //           },
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Future<void> _insertarEnReporteTIM(Producto producto) async {
  //   final Database db = await openDatabase('tu_base_de_datos.db');

  //   await db.insert('reporte_tim', {
  //     'fecha_generacion': DateTime.now().toIso8601String(),
  //     'tim': producto.tim, // Asegúrate que tu modelo Producto tenga este campo
  //     'shipment': producto.shipment,
  //     'placa': producto.placa,
  //     'local_origen': producto.localOrigen,
  //     'local_destino': producto.localDestino,
  //     'fecha_envio': producto.fechaEnvio,
  //   });

  //   await db.close();
  // }

  Widget _buildSubDeptFilter() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        return _subDeptOptions.where((option) =>
            option.toLowerCase().contains(value.text.toLowerCase()));
      },
      onSelected: (value) {
        controller.text = value;
        subclaseSeleccionada = value;
        _actualizarProductos();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Filtrar por Subclase',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                subclaseSeleccionada = null;

                _actualizarProductos();
              },
            ),
            hintText: 'Escribe para buscar...',
          ),
          onChanged: _handleSubDeptSearch,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildOptionsList(context, onSelected, options);
      },
    );
  }

  Widget _buildOptionsList(
    BuildContext context,
    void Function(String) onSelected,
    Iterable<String> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                title: Text(option),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDescripcionSearch() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Buscar por descripción...',
        suffixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => busquedaTexto = value.trim());
            _actualizarProductos();
          }
        });
      },
    );
  }
}
