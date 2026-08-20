import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muserpol_pvt/components/containers.dart';
import 'package:muserpol_pvt/components/headers.dart';
import 'package:muserpol_pvt/components/table_row.dart';
import 'package:muserpol_pvt/model/contribution_model.dart';

class CardExpanded extends StatefulWidget {
  final String index;
  final Contribution contribution;
  final Color colorRefund;
  const CardExpanded({super.key, required this.colorRefund, required this.index, required this.contribution});

  @override
  State<CardExpanded> createState() => _CardExpandedState();
}

class _CardExpandedState extends State<CardExpanded> {
  @override
  Widget build(BuildContext context) {
    final sizeHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent.withValues(alpha: 0.5),
        body: GestureDetector(
          child: Center(
            child: Hero(
                tag: widget.index,
                child: Material(
                  type: MaterialType.transparency,
                  child: GestureDetector(
                    onTap: () {},
                    child: ContainerComponent(
                        height: (widget.contribution.state == 'ACTIVO') ? sizeHeight / 1.5 : sizeHeight / 3,
                        width: MediaQuery.of(context).size.width / 1.1,
                        color: AdaptiveTheme.of(context).theme.scaffoldBackgroundColor,
                        child: Column(
                          children: [
                            HedersComponent(
                                titleHeader: widget.contribution.state,
                                title: DateFormat(' dd, MMMM yyyy ', "es_ES").format(widget.contribution.monthYear!)),
                            Expanded(
                                child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Table(
                                        columnWidths: const {
                                          0: FlexColumnWidth(5),
                                          1: FlexColumnWidth(0.3),
                                          2: FlexColumnWidth(5),
                                        },
                                        border: const TableBorder(
                                          horizontalInside: BorderSide(
                                            width: 0.5,
                                            color: Colors.grey,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                        children: [
                                          // Fila 1: Siempre
                                          tableInfo('Cotizable', Text(widget.contribution.quotable!)),
                                          // Fila 2: Solo si tiene valor
                                          if (widget.contribution.state == 'ACTIVO' &&
                                              widget.contribution.retirementFund != null &&
                                              widget.contribution.retirementFund != '0,00')
                                            tableInfo('Fondo de retiro', Text(widget.contribution.retirementFund!)),
                                          // Fila 3: Solo si tiene valor
                                          if (widget.contribution.state == 'ACTIVO' &&
                                              widget.contribution.mortuaryQuota != null &&
                                              widget.contribution.mortuaryQuota != '0,00')
                                            tableInfo('Cuota mortuoria', Text(widget.contribution.mortuaryQuota!)),
                                          // Fila 4: Solo si contributionTotal no es null
                                          if (widget.contribution.state == 'ACTIVO' &&
                                              widget.contribution.contributionTotal != null)
                                            tableInfo('Aporte', Text(widget.contribution.contributionTotal!)),
                                          // Fila 5: Siempre para ACTIVO (Reintegro o Regularización)
                                          if (widget.contribution.state == 'ACTIVO')
                                            tableInfo(
                                                widget.contribution.typePayroll == 'regularizacion'
                                                    ? 'Regularización'
                                                    : 'Reintegro',
                                                Text('${widget.contribution.reimbursementTotal ?? '0,00'} Bs')
                                            ),
                                          // Fila 6: Siempre para ACTIVO (Total)
                                          if (widget.contribution.state == 'ACTIVO')
                                            tableInfo(
                                                widget.contribution.typePayroll == 'regularizacion'
                                                    ? 'Total Regularización'
                                                    : 'Total Reintegro',
                                                Text('${widget.contribution.total!} Bs')
                                            ),
                                        ])
                                  ],
                                ),
                              ),
                            ))
                          ],
                        )),
                  ),
                )),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
