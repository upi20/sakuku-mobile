part of 'history_bloc.dart';

abstract class HistoryEvent {}

class HistoryLoadByMonth extends HistoryEvent {
  final String yearMonth; // format: yyyy-MM
  HistoryLoadByMonth(this.yearMonth);
}

class HistoryChangeMonth extends HistoryEvent {
  final int delta; // -1 or +1
  HistoryChangeMonth(this.delta);
}

class HistoryChangeYear extends HistoryEvent {
  final int delta; // -1 or +1
  HistoryChangeYear(this.delta);
}

class HistoryChangeDay extends HistoryEvent {
  final int delta; // -1 or +1
  HistoryChangeDay(this.delta);
}

class HistoryDeleteRequested extends HistoryEvent {
  final int id;
  HistoryDeleteRequested(this.id);
}

class HistoryRefresh extends HistoryEvent {}

class HistorySetMode extends HistoryEvent {
  final HistoryViewMode viewMode;
  final Set<int> selectedAccountIds;  // empty = all accounts
  final Set<int> selectedCategoryIds; // empty = all categories
  final String? customStartDate; // "yyyy-MM-dd", only for custom mode
  final String? customEndDate;   // "yyyy-MM-dd", only for custom mode

  HistorySetMode({
    required this.viewMode,
    this.selectedAccountIds = const {},
    this.selectedCategoryIds = const {},
    this.customStartDate,
    this.customEndDate,
  });
}
