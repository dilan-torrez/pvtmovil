import 'package:flutter_test/flutter_test.dart';
import 'package:muserpol_pvt/model/loan_pre_evaluation_model.dart';
import 'package:muserpol_pvt/model/saved_loan_evaluation.dart';
import 'package:muserpol_pvt/services/evaluation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Escenarios de la validación ligera de evaluaciones guardadas.
///
/// La regla de oro: **nunca se borra nada**. Solo se marca `isObsolete` con un
/// motivo legible, y se compara por `procedureModalityId` (estable) y no por el
/// índice `id` de la lista (posicional).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 2684;
  final service = EvaluationService();

  LoanParametersNew params({double annual = 13.2, int guarantors = 0}) {
    return LoanParametersNew(
      debtIndex: 0,
      guarantors: guarantors,
      maxLenders: 4,
      minLenderCategory: 1,
      maxLenderCategory: 5,
      maximumAmountModality: 70000,
      minimumAmountModality: 1000,
      maximumTermModality: 60,
      minimumTermModality: 6,
      loanMonthTerm: 1,
      coveragePercentage: 0.8,
      annualInterest: annual,
      periodInterest: annual / 12,
    );
  }

  LoanModalityNew modality({
    int id = 1,
    int procedureModalityId = 43,
    String catalogHash = 'hash-A',
    double annual = 13.2,
    int guarantors = 0,
  }) {
    return LoanModalityNew(
      id: id,
      affiliateId: userId,
      procedureModalityId: procedureModalityId,
      name: 'Largo Plazo',
      category: 'Activo',
      pensionEntityName: '',
      affiliateStateType: 'Activo',
      subsector: '',
      parameters: params(annual: annual, guarantors: guarantors),
      catalogHash: catalogHash,
    );
  }

  SavedLoanEvaluation evaluation({
    required String id,
    int procedureModalityId = 43,
    String catalogHash = 'hash-A',
    double annual = 13.2,
    int guarantors = 0,
  }) {
    return SavedLoanEvaluation(
      id: id,
      createdAt: DateTime.now(),
      modalityName: 'Largo Plazo',
      amount: 30000,
      term: 24,
      termType: 'Meses',
      monthlyPayment: 1500,
      paymentFrequency: 'Mensual',
      sueldoBase: 5000,
      affiliateStateType: 'Activo',
      documents: const [],
      annualInterest: annual,
      periodInterest: annual / 12,
      guarantors: guarantors,
      modalityId: 1,
      procedureModalityId: procedureModalityId,
      catalogHash: catalogHash,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('hash igual → vigente', () async {
    await service.saveEvaluation(evaluation(id: 'e1'), userId: userId);

    final reports =
        await service.validateEvaluations([modality()], userId: userId);

    final saved = await service.getSavedEvaluations(userId: userId);
    expect(reports, isEmpty);
    expect(saved.single.isObsolete, isFalse);
    // `checkedAt` solo se persiste cuando hay un cambio real: si nada cambió,
    // no se reescribe el almacenamiento en cada visita (ligereza).
    expect(saved.single.obsoleteReason, isNull);
  });

  test('cambio de interés → obsoleta con motivo, sin borrar', () async {
    await service.saveEvaluation(evaluation(id: 'e1'), userId: userId);

    final reports = await service.validateEvaluations(
      [modality(catalogHash: 'hash-B', annual: 15.0)],
      userId: userId,
    );

    final saved = await service.getSavedEvaluations(userId: userId);
    expect(saved, hasLength(1), reason: 'no debe borrarse');
    expect(saved.single.isObsolete, isTrue);
    expect(saved.single.obsoleteReason, contains('interés anual'));
    expect(reports, hasLength(1));
  });

  test('modalidad que ya no aplica → obsoleta, sin borrar', () async {
    await service.saveEvaluation(evaluation(id: 'e1'), userId: userId);

    final reports = await service.validateEvaluations([], userId: userId);

    final saved = await service.getSavedEvaluations(userId: userId);
    expect(saved, hasLength(1));
    expect(saved.single.obsoleteReason, contains('ya no está disponible'));
    expect(reports, hasLength(1));
  });

  test('reordenamiento de la lista NO invalida (usa procedureModalityId)',
      () async {
    await service.saveEvaluation(evaluation(id: 'e1'), userId: userId);

    // La modalidad 43 ahora está en la posición 7 de la lista.
    final reports = await service.validateEvaluations(
      [modality(id: 7)],
      userId: userId,
    );

    final saved = await service.getSavedEvaluations(userId: userId);
    expect(reports, isEmpty);
    expect(saved.single.isObsolete, isFalse);
  });

  test('evaluación antigua sin hash: se adopta si los parámetros coinciden',
      () async {
    await service.saveEvaluation(
      evaluation(id: 'legacy', catalogHash: ''),
      userId: userId,
    );

    final reports =
        await service.validateEvaluations([modality()], userId: userId);

    final saved = await service.getSavedEvaluations(userId: userId);
    expect(reports, isEmpty);
    expect(saved.single.catalogHash, 'hash-A');
    expect(saved.single.isObsolete, isFalse);
  });

  test('evaluación antigua sin hash y parámetros distintos → obsoleta',
      () async {
    await service.saveEvaluation(
      evaluation(id: 'legacy', catalogHash: '', annual: 10.0),
      userId: userId,
    );

    final reports =
        await service.validateEvaluations([modality()], userId: userId);

    final saved = await service.getSavedEvaluations(userId: userId);
    expect(saved.single.isObsolete, isTrue);
    expect(reports, hasLength(1));
  });

  test('un cambio posterior vuelve a marcar y luego se limpia la marca',
      () async {
    await service.saveEvaluation(evaluation(id: 'e1'), userId: userId);

    await service.validateEvaluations(
      [modality(catalogHash: 'hash-B', annual: 15.0)],
      userId: userId,
    );
    var saved = await service.getSavedEvaluations(userId: userId);
    expect(saved.single.isObsolete, isTrue);

    // Vuelve el catálogo original.
    await service.validateEvaluations([modality()], userId: userId);
    saved = await service.getSavedEvaluations(userId: userId);
    expect(saved.single.isObsolete, isFalse);
    expect(saved.single.obsoleteReason, isNull);
  });
}
