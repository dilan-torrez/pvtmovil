import 'package:bloc/bloc.dart';
import 'package:muserpol_pvt/model/loan_model.dart';

part 'loan_event.dart';
part 'loan_state.dart';

class LoanBloc extends Bloc<LoanEvent, LoanState> {
  LoanBloc() : super(const LoanState()) {
    on<UpdateLoan>((event, emit) => emit(state.copyWith(
        existLoan: true,
        loan: event.loan,
        isLoading: false,
        hasError: false)));
    on<ClearLoans>((event, emit) => emit(const LoanState()));
    on<LoanLoadState>((event, emit) =>
        emit(state.copyWith(isLoading: event.isLoading, hasError: event.hasError)));
  }
}
