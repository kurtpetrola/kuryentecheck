import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/report_service.dart';

class ReportFormState {
  final String? selectedBarangay;
  final String? selectedIssue;
  final String notes;
  final bool isLoading;
  final String? error;

  ReportFormState({
    this.selectedBarangay,
    this.selectedIssue,
    this.notes = '',
    this.isLoading = false,
    this.error,
  });

  ReportFormState copyWith({
    String? selectedBarangay,
    String? selectedIssue,
    String? notes,
    bool? isLoading,
    String? error,
  }) {
    return ReportFormState(
      selectedBarangay: selectedBarangay ?? this.selectedBarangay,
      selectedIssue: selectedIssue ?? this.selectedIssue,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullable, so we can clear it by passing null
    );
  }
}

class ReportFormController extends Notifier<ReportFormState> {
  @override
  ReportFormState build() {
    return ReportFormState();
  }

  void setBarangay(String? barangay) {
    state = state.copyWith(selectedBarangay: barangay, error: null);
  }

  void setIssue(String? issue) {
    state = state.copyWith(selectedIssue: issue, error: null);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<bool> submitReport() async {
    if (state.selectedBarangay == null || state.selectedIssue == null) {
      state = state.copyWith(error: 'missing_fields');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref
          .read(reportServiceProvider)
          .addReport(
            barangay: state.selectedBarangay!,
            issueType: state.selectedIssue!,
            notes: state.notes,
          );

      // Reset form on success
      state = ReportFormState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final reportFormControllerProvider =
    NotifierProvider<ReportFormController, ReportFormState>(() {
      return ReportFormController();
    });
