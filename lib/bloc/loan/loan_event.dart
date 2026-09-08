part of 'loan_bloc.dart';

abstract class LoanEvent {}

class UpdateLoan extends LoanEvent {
  final LoanModel loan;

  UpdateLoan(this.loan);
}

class ClearLoans extends LoanEvent {
  ClearLoans();
}

class LoanLoadState extends LoanEvent {
  final bool isLoading;
  final bool hasError;

  LoanLoadState({required this.isLoading, this.hasError = false});
}
