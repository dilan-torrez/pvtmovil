import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muserpol_pvt/bloc/user/user_bloc.dart';
import 'package:muserpol_pvt/services/service_method.dart';
import 'package:muserpol_pvt/services/services.dart';

class ScreenBenefitsNew extends StatefulWidget {
  const ScreenBenefitsNew({super.key});

  @override
  State<ScreenBenefitsNew> createState() => _ScreenBenefitsNewState();
}

class _ScreenBenefitsNewState extends State<ScreenBenefitsNew> {
  List<Map<String, dynamic>> _retFunds = [];
  List<Map<String, dynamic>> _quotaAids = [];
  bool _loading = true;
  bool _hasError = false;
  int? _printingId;

  @override
  void initState() {
    super.initState();
    _loadBenefits();
  }

  int? get _affiliateId =>
      BlocProvider.of<UserBloc>(context, listen: false).state.user?.affiliateId;

  Future<void> _loadBenefits() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _fetchList(serviceGetRetirementFunds(_affiliateId!)),
        _fetchList(serviceGetQuotaAid(_affiliateId!)),
      ]);

      if (!mounted) return;
      setState(() {
        _retFunds = results[0];
        _quotaAids = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchList(String url) async {
    final response =
        await serviceMethod(mounted, context, 'get', null, url, true, false);
    if (response == null) return [];

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['error'] == true) return [];

    final data = decoded['data'];
    if (data is! List) return [];

    return data
        .map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadBenefits,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Fondo de Retiro:'),
            SizedBox(
              height: 20.h,
            ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xff419388)),
                  ),
                ),
              )
            else if (_hasError)
              _buildLoadError('No se pudieron cargar tus beneficios.',
                  _loadBenefits)
            else if (_retFunds.isEmpty)
              const _EmptyMessage('No tienes trámites de Fondo de Retiro.')
            else
              _tramitesSection(_retFunds, 'Benefits', 'ret_fun'),
            SizedBox(
              height: 20.h,
            ),
            _sectionTitle('Cuota Auxilio Mortuorio:'),
            SizedBox(
              height: 20.h,
            ),
            if (!_loading && !_hasError)
              _quotaAids.isEmpty
                  ? const _EmptyMessage(
                      'No tienes trámites de Cuota Auxilio Mortuorio.')
                  : _tramitesSection(
                      _quotaAids, 'Benefits', 'quota_aid'),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 18.sp,
        ),
      ),
    );
  }

  Widget _buildLoadError(String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff419388),
              foregroundColor: Colors.white,
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // TODO: implementar descarga y validacion del PDF
  Future<void> _printDocument(
      int id, String url, String folder, String fileName) async {}

  Widget _tramitesSection(
      List<Map<String, dynamic>> items, String folder, String prefix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          _TramiteCard(
            code: item['code']?.toString() ?? '-',
            receptionDate: item['reception_date']?.toString() ?? '-',
            modality: item['procedure_modality']?.toString() ?? '-',
            procedureType: item['procedure_type']?.toString() ?? '-',
            printable: item['printable'] == true,
            printing: _printingId != null && _printingId == item['id'],
            onPrint: () {
              if (item['printable'] != true) return;
              final url =
                  prefix == 'ret_fun'
                      ? servicePrintRetFunLiquidation(item['id'] as int)
                      : servicePrintQuotaAidLiquidation(item['id'] as int);
              final name = '${prefix}_${item['id']}.pdf';
              _printDocument(item['id'] as int, url, folder, name);
            },
          ),
      ],
    );
  }
}

class _TramiteCard extends StatelessWidget {
  final String code;
  final String receptionDate;
  final String modality;
  final String procedureType;
  final bool printable;
  final bool printing;
  final VoidCallback onPrint;

  const _TramiteCard({
    required this.code,
    required this.receptionDate,
    required this.modality,
    required this.procedureType,
    required this.printable,
    required this.printing,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isDarkMode ? const Color(0xff184741) : const Color(0xffE8F3F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dataRow('Código:', code),
          _dataRow('Fecha de recepción:', receptionDate),
          _dataRow('Modalidad:', modality),
          _dataRow('Tipo de Trámite:', procedureType),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff419388),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              onPressed: printable ? onPrint : null,
              icon: printing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print, size: 20),
              label: Text(printing
                  ? 'Generando...'
                  : printable
                      ? 'Imprimir Liquidación'
                      : 'Sin liquidación disponible'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}