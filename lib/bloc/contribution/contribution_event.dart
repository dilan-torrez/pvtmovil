part of 'contribution_bloc.dart';


abstract class ContributionEvent {}

class UpdateContributions extends ContributionEvent {
  final ContributionModel contribution;

  UpdateContributions(this.contribution);
}


class ClearContributions extends ContributionEvent {
  ClearContributions();
}

class ContributionLoadState extends ContributionEvent {
  final bool isLoading;
  final bool hasError;

  ContributionLoadState({required this.isLoading, this.hasError = false});
}