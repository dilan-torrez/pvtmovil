import 'package:flutter/material.dart';

class TokenState with ChangeNotifier {
  bool stateAuxToken = false;
  void updateStateAuxToken(bool state) {
    stateAuxToken = state;
    notifyListeners();
  }
}

class ObservationState with ChangeNotifier {
  String messageObservation = '';
  void updateObservation(String message) {
    messageObservation = message;
    notifyListeners();
  }
}

class TabProcedureState with ChangeNotifier {
  int indexTabProcedure = 0;
  Future<void> updateTabProcedure(int index) async {
    await Future.delayed(const Duration(milliseconds: 50), () {});
    indexTabProcedure = index;
    notifyListeners();
  }
}

class ProcessingState with ChangeNotifier {
  bool stateProcessing = false;
  void updateStateProcessing(bool state) {
    stateProcessing = state;
    notifyListeners();
  }
}

class LoadingState with ChangeNotifier {
  bool stateLoadingProcedure = false;
  Future<void> updateStateLoadingProcedure(bool state) async {
    await Future.delayed(const Duration(milliseconds: 50), () {});
    stateLoadingProcedure = state;
    notifyListeners();
  }
}
