part of 'contribution_bloc.dart';

class ContributionState {
  final ContributionModel? contribution;
  final bool existContribution;
  final bool isLoading;
  final bool hasError;
  const ContributionState({
    this.contribution,
    this.existContribution = false,
    this.isLoading = false,
    this.hasError = false,
  });

  ContributionState copyWith({
    bool? existContribution,
    ContributionModel? contribution,
    bool? isLoading,
    bool? hasError,
  }) =>
      ContributionState(
        existContribution: existContribution ?? this.existContribution,
        contribution: contribution ?? this.contribution,
        isLoading: isLoading ?? this.isLoading,
        hasError: hasError ?? this.hasError);
}
