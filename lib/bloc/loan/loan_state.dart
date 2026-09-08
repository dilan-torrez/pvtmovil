part of 'loan_bloc.dart';

class LoanState {
  final LoanModel? loan;

  final bool existLoan;

  final bool isLoading;

  final bool hasError;

  const LoanState({
    this.loan,
    this.existLoan = false,
    this.isLoading = false,
    this.hasError = false,
  });

  LoanState copyWith({
    bool? existLoan,
    LoanModel? loan,
    bool? isLoading,
    bool? hasError,
  }) =>
      LoanState(
        existLoan: existLoan ?? this.existLoan,
        loan: loan ?? this.loan,
        isLoading: isLoading ?? this.isLoading,
        hasError: hasError ?? this.hasError,
      );
}
