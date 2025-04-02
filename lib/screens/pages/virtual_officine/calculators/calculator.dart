import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:muserpol_pvt/components/headers.dart';
import 'package:muserpol_pvt/model/biometric_user_model.dart';
import 'package:muserpol_pvt/components/button.dart';
import 'package:muserpol_pvt/services/service_method.dart';
import 'package:muserpol_pvt/services/services.dart';
import 'package:muserpol_pvt/services/auth_service.dart';
import 'package:provider/provider.dart';

class ScreenCalculator extends StatefulWidget {
  final GlobalKey? keyNotification;
  const ScreenCalculator({super.key, required this.keyNotification});
  @override
  State<ScreenCalculator> createState() => _ScreenCalculatorState();
}

class _ScreenCalculatorState extends State<ScreenCalculator> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _plazoController = TextEditingController();

  List<dynamic> modalitiesList = [];
  List<dynamic> selectedModalities = [];
  String? selectedLoan;
  String? selectedProcedure;

  @override
  void dispose() {
    _montoController.dispose();
    _plazoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getListModalities();
  }

  Future<void> getListModalities() async {
    var response = await serviceMethod(
        mounted, context, 'get', {}, listModalities(), false, true);

    if (response != null) {
      final decodedResponse = json.decode(response.body);
      setState(() {
        modalitiesList = decodedResponse;
      });
    } else {
      debugPrint('Error fetching modalities');
    }
  }

  void sendDataToServer() async {
    if (selectedLoan == null || selectedProcedure == null) {
      debugPrint('Préstamo o modalidad no seleccionados.');
      return;
    }
    final authService = Provider.of<AuthService>(context, listen: false);
    final biometric =
        biometricUserModelFromJson(await authService.readBiometric());
    Map<String, dynamic> requestBody = {
      'loan_id': selectedLoan,
      'procedure_id': selectedProcedure,
      'amount': _montoController.text,
      'term': _plazoController.text,
      'id_affiliate': biometric.affiliateId,
    };

    var response = await serviceMethod(
      mounted,
      context,
      'post',
      requestBody,
      calculatorLoan(),
      true,
      true,
    );

    if (!mounted) return;

    if (response != null && response.statusCode == 200) {
      debugPrint('Datos enviados correctamente: ${response.body}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Éxito'),
            content: const Text('La información se envió correctamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } else {
      debugPrint('Error al enviar datos: ${response?.body}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Ocurrió un error al enviar los datos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          HedersComponent(
            keyNotification: widget.keyNotification,
            title: 'Calculadora',
            stateBell: true,
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Seleccione un préstamo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  value: selectedLoan,
                  isExpanded: true, // Evitar overflow horizontal
                  items: modalitiesList
                      .map<DropdownMenuItem<String>>((loan) => DropdownMenuItem(
                            value: loan['id'].toString(),
                            child: Text(loan['second_name']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLoan = value;
                      selectedModalities = modalitiesList.firstWhere((loan) =>
                          loan['id'].toString() ==
                          value)['procedure_modalities'] as List<dynamic>;
                      selectedProcedure = null; 
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Por favor seleccione un préstamo' : null,
                ),
                const SizedBox(height: 16),
                // DropdownButtonFormField<String>(
                //   decoration: InputDecoration(
                //     labelText: 'Seleccione una modalidad',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(8.0),
                //     ),
                //   ),
                //   value: selectedProcedure,
                //   isExpanded: true, // Evitar overflow horizontal
                //   items: selectedModalities
                //       .map<DropdownMenuItem<String>>(
                //           (modality) => DropdownMenuItem(
                //                 value: modality['id'].toString(),
                //                 child: Text(modality['name']),
                //               ))
                //       .toList(),
                //   onChanged: (value) {
                //     setState(() {
                //       selectedProcedure = value;
                //     });
                //   },
                //   validator: (value) => value == null
                //       ? 'Por favor seleccione una modalidad'
                //       : null,
                // ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _montoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese el monto';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plazoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Plazo (en meses)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.timer),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese el plazo';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ButtonIconComponent(
                  text: 'CALCULAR',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      sendDataToServer();
                    }
                  },
                  icon: Container(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
