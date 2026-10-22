import 'dart:convert';

class SavedLoanEvaluation {
  final String id;
  final DateTime createdAt;
  final String modalityName;
  final double amount;
  final int term;
  final String termType;
  final double monthlyPayment;
  final String paymentFrequency;
  final double sueldoBase;
  final String affiliateStateType;
  final List<Map<String, dynamic>> documents;
  bool isFavorite;
  
  // Datos adicionales para PDF y recarga
  final double annualInterest;
  final double periodInterest;
  final int guarantors;
  final double? liquidoPagable; // Solo para Activo
  final double? totalBonos; // Solo para Activo
  final double? seniorityBonus; // Solo para Activo
  final double? studyBonus; // Solo para Activo
  final double? positionBonus; // Solo para Activo
  final double? borderBonus; // Solo para Activo
  final double? eastBonus; // Solo para Activo
  final double? rentaDignidad; // Solo para Pasivo
  final int modalityId; // Para recarga
  final int procedureModalityId; // Para documentos
  final String? affiliateName; // Nombre del afiliado
  final String? affiliateIdentityCard; // CI del afiliado
  final double? loanCharge; // Cargo del préstamo

  /// Firma del catálogo (parámetros + documentos) vigente cuando se guardó.
  /// Si difiere de la actual, la evaluación quedó desactualizada.
  ///
  /// No es `final` a propósito: las evaluaciones creadas antes de existir la
  /// firma se "adoptan" con el hash actual cuando sus parámetros coinciden.
  String catalogHash;

  /// Marca de evaluación desactualizada. No se borra: se conserva para que el
  /// usuario decida si recalcula o elimina.
  bool isObsolete;

  /// Motivo legible del porqué quedó desactualizada.
  String? obsoleteReason;

  /// Última vez que se comparó contra el catálogo vigente.
  DateTime? checkedAt;

  SavedLoanEvaluation({
    required this.id,
    required this.createdAt,
    required this.modalityName,
    required this.amount,
    required this.term,
    required this.termType,
    required this.monthlyPayment,
    required this.paymentFrequency,
    required this.sueldoBase,
    required this.affiliateStateType,
    required this.documents,
    this.isFavorite = false,
    required this.annualInterest,
    required this.periodInterest,
    required this.guarantors,
    this.liquidoPagable,
    this.totalBonos,
    this.seniorityBonus,
    this.studyBonus,
    this.positionBonus,
    this.borderBonus,
    this.eastBonus,
    this.rentaDignidad,
    required this.modalityId,
    required this.procedureModalityId,
    this.affiliateName,
    this.affiliateIdentityCard,
    this.loanCharge,
    this.catalogHash = '',
    this.isObsolete = false,
    this.obsoleteReason,
    this.checkedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'modalityName': modalityName,
      'amount': amount,
      'term': term,
      'termType': termType,
      'monthlyPayment': monthlyPayment,
      'paymentFrequency': paymentFrequency,
      'sueldoBase': sueldoBase,
      'affiliateStateType': affiliateStateType,
      'documents': documents,
      'isFavorite': isFavorite,
      'annualInterest': annualInterest,
      'periodInterest': periodInterest,
      'guarantors': guarantors,
      'liquidoPagable': liquidoPagable,
      'totalBonos': totalBonos,
      'seniorityBonus': seniorityBonus,
      'studyBonus': studyBonus,
      'positionBonus': positionBonus,
      'borderBonus': borderBonus,
      'eastBonus': eastBonus,
      'rentaDignidad': rentaDignidad,
      'modalityId': modalityId,
      'procedureModalityId': procedureModalityId,
      'affiliateName': affiliateName,
      'affiliateIdentityCard': affiliateIdentityCard,
      'loanCharge': loanCharge,
      'catalogHash': catalogHash,
      'isObsolete': isObsolete,
      'obsoleteReason': obsoleteReason,
      'checkedAt': checkedAt?.toIso8601String(),
    };
  }

  factory SavedLoanEvaluation.fromJson(Map<String, dynamic> json) {
    return SavedLoanEvaluation(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modalityName: json['modalityName'] as String,
      amount: (json['amount'] as num).toDouble(),
      term: json['term'] as int,
      termType: json['termType'] as String,
      monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
      paymentFrequency: json['paymentFrequency'] as String,
      sueldoBase: (json['sueldoBase'] as num).toDouble(),
      affiliateStateType: json['affiliateStateType'] as String,
      documents: List<Map<String, dynamic>>.from(json['documents'] as List),
      isFavorite: json['isFavorite'] as bool? ?? false,
      annualInterest: (json['annualInterest'] as num?)?.toDouble() ?? 0.0,
      periodInterest: (json['periodInterest'] as num?)?.toDouble() ?? 0.0,
      guarantors: json['guarantors'] as int? ?? 0,
      liquidoPagable: (json['liquidoPagable'] as num?)?.toDouble(),
      totalBonos: (json['totalBonos'] as num?)?.toDouble(),
      seniorityBonus: (json['seniorityBonus'] as num?)?.toDouble(),
      studyBonus: (json['studyBonus'] as num?)?.toDouble(),
      positionBonus: (json['positionBonus'] as num?)?.toDouble(),
      borderBonus: (json['borderBonus'] as num?)?.toDouble(),
      eastBonus: (json['eastBonus'] as num?)?.toDouble(),
      rentaDignidad: (json['rentaDignidad'] as num?)?.toDouble(),
      modalityId: json['modalityId'] as int? ?? 0,
      procedureModalityId: json['procedureModalityId'] as int? ?? 0,
      affiliateName: json['affiliateName'] as String?,
      affiliateIdentityCard: json['affiliateIdentityCard'] as String?,
      loanCharge: (json['loanCharge'] as num?)?.toDouble(),
      catalogHash: json['catalogHash'] as String? ?? '',
      isObsolete: json['isObsolete'] as bool? ?? false,
      obsoleteReason: json['obsoleteReason'] as String?,
      checkedAt: json['checkedAt'] != null
          ? DateTime.tryParse(json['checkedAt'] as String)
          : null,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory SavedLoanEvaluation.fromJsonString(String jsonString) {
    return SavedLoanEvaluation.fromJson(json.decode(jsonString));
  }
}
