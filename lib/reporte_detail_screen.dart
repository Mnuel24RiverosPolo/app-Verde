import 'package:app_conteo/database_helper.dart';
import 'package:app_conteo/model/reporte_model.dart';
import 'package:app_conteo/utils/app_colors.dart';
import 'package:flutter/material.dart';

class ReportDetailsDialog extends StatefulWidget {
  final Reporte report;
  final VoidCallback onSave;

  const ReportDetailsDialog(
      {Key? key, required this.report, required this.onSave})
      : super(key: key);

  @override
  _DetalleReporteDialogState createState() => _DetalleReporteDialogState();
}

class _DetalleReporteDialogState extends State<ReportDetailsDialog> {
  late double _count;
  DateTime? selectedDate;

  final TextEditingController _controller = TextEditingController();
  TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    dateController.text = widget.report.fechavencimiento?.isEmpty ?? true
        ? "dd/mm/yy"
        : widget.report.fechavencimiento!;
    _count = widget.report.recibidos ?? 0.0; //
    _controller.text = _count.toString();
  }

  void _increment() {
    setState(() {
      _count++;
      _controller.text = _count.toString(); // Actualiza el controlador
    });
  }

  void _decrement() {
    if (_count > 0) {
      setState(() {
        _count--;
        _controller.text = _count.toString(); // Actualiza el controlador
      });
    }
  }

  void _updateCount(String value) {
    double? newValue = double.tryParse(value); // int.tryParse(value);
    if (newValue != null) {
      setState(() {
        _count = newValue; // Actualiza la variable de estado
      });
    } else if (value.isEmpty) {
      setState(() {
        _count = 0; // Reinicia a 0 si el campo está vacío
        _controller.text = _count.toString(); // Actualiza el controlador
      });
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${widget.report.descripcion ?? 'Sin descripción'}',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.start,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ajusta el tamaño al contenido
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue:
                      '${widget.report.sku}', // Muestra el valor del SKU
                  decoration: InputDecoration(
                    labelText: 'SKU', // Texto del hint que se posiciona arriba
                    labelStyle: TextStyle(
                      color: Colors.blue, // Color del label
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors
                            .grey, // Color del borde cuando el campo no está enfocado
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors
                            .blue, // Color del borde cuando el campo está enfocado
                        width: 2.0,
                      ),
                    ),
                    filled: true, // Para dar un color de fondo al campo
                    fillColor: Colors.grey[200],

                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  readOnly: true, // Hace que el campo no sea editable
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Color del texto
                  ),
                ),
              ),
              SizedBox(width: 30),
              Expanded(
                child: TextFormField(
                  initialValue: '${widget.report.tipoSku}',
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    labelStyle: TextStyle(
                      color: Colors.blue,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  readOnly: true,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue:
                      '${widget.report.tipoInventario}', // Muestra el valor del SKU
                  decoration: InputDecoration(
                    labelText:
                        'Inventario', // Texto del hint que se posiciona arriba
                    labelStyle: TextStyle(
                      color: Colors.blue, // Color del label
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors
                            .grey, // Color del borde cuando el campo no está enfocado
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors
                            .blue, // Color del borde cuando el campo está enfocado
                        width: 2.0,
                      ),
                    ),
                    filled: true, // Para dar un color de fondo al campo
                    fillColor: Colors.grey[200],

                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  readOnly: true, // Hace que el campo no sea editable
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Color del texto
                  ),
                ),
              ),
              SizedBox(width: 30),
              Expanded(
                child: TextFormField(
                  initialValue: '${widget.report.subdpto}',
                  decoration: InputDecoration(
                    labelText: 'Departamento',
                    labelStyle: TextStyle(
                      color: Colors.blue,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  readOnly: true,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '${widget.report.casePack}',
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'CasePack',
                    labelStyle: TextStyle(
                      color: Colors.blue, // Color del label
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  readOnly: true,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Color del texto
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: '${widget.report.cajas}',
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Cajas',
                    labelStyle: TextStyle(
                      color: Colors.blue,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  readOnly: true,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue:
                      '${widget.report.unidades}', // Muestra el valor del SKU
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText:
                        'Unidades', // Texto del hint que se posiciona arriba
                    labelStyle: TextStyle(
                      color: Colors.blue, // Color del label
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors
                            .grey, // Color del borde cuando el campo no está enfocado
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors
                            .blue, // Color del borde cuando el campo está enfocado
                        width: 2.0,
                      ),
                    ),
                    filled: true, // Para dar un color de fondo al campo
                    fillColor: Colors.grey[200],

                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  //readOnly: true, // Hace que el campo no sea editable
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Color del texto
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  //initialValue: '',
                  controller: dateController,
                  readOnly: true, // Evita que el usuario escriba directamente
                  decoration: InputDecoration(
                    labelText: 'F. Vencimiento',
                    //  hintText: 'Selecciona una fecha',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors
                            .black, // Color del borde cuando el campo está enfocado
                        width: 2.0,
                      ),
                    ),
                    suffixIcon:
                        Icon(Icons.calendar_today), // Ícono de calendario
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  onTap: () async {
                    // Abre el selector de fecha
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      // Formatea la fecha seleccionada y la muestra en el campo
                      String formattedDate =
                          '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                      setState(() {
                        dateController.text = formattedDate;
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: 10),
              Column(
                // Aquí reemplazamos el Expanded
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text(
                  //   'U. Recibidas:',
                  //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TextField
                      SizedBox(
                        width: 80, // Ancho deseado
                        child: Expanded(
                          child: TextFormField(
                            controller: _controller,
                            textAlign: TextAlign.center,
                            onChanged: _updateCount,
                            // initialValue:
                            //     '${widget.report.unidades}', // Muestra el valor del SKU
                            decoration: InputDecoration(
                              labelText: 'U. Cont',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors
                                      .grey, // Color del borde cuando el campo no está enfocado
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors
                                      .black, // Color del borde cuando el campo está enfocado
                                  width: 2.0,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                            ),
                            //readOnly: true, // Hace que el campo no sea editable
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black, // Color del texto
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap:
                                _increment, // Acción cuando se hace tap en el ícono de arriba
                            child: Icon(
                              Icons.keyboard_arrow_up,
                              size: 24, // Tamaño del ícono, puedes ajustarlo
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                _decrement, // Acción cuando se hace tap en el ícono de abajo
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 24, // Tamaño del ícono, puedes ajustarlo
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${widget.report.unidades - _count} Faltantes',
            style: TextStyle(color: AppColors.error, fontSize: 12),
          )
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            // Botón Guardar
            TextButton(
              onPressed: () async {
                Reporte reporteActualizado = Reporte(
                  id: widget.report.id,
                  olpn: widget.report.olpn,
                  pallet: widget.report.pallet,
                  tipoInventario: widget.report.tipoInventario,
                  tipoSku: widget.report.tipoSku,
                  subdpto: widget.report.subdpto,
                  ean: widget.report.ean,
                  sku: widget.report.sku,
                  descripcion: widget.report.descripcion,
                  casePack: widget.report.casePack,
                  unidades: widget.report.unidades,
                  cajas: widget.report.cajas,
                  recibidos: double.tryParse(_controller
                          .text) ?? //  int.tryParse(_controller.text)
                      widget.report.recibidos,
                  fechavencimiento:
                      dateController.text ?? widget.report.fechavencimiento,
                  faltantes: widget.report.faltantes,
                );

                int result = await DatabaseHelper.instance
                    .updateReporte(reporteActualizado);

                if (result > 0) {
                  widget.onSave();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar el reporte')),
                  );
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green, // Color de fondo verde
                // primary: Colors.white, // Color del texto blanco
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        )
      ],
    );
  }
}
