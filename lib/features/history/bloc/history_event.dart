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

class HistoryDeleteRequested extends HistoryEvent {
  final int id;
  HistoryDeleteRequested(this.id);
}

class HistoryRefresh extends HistoryEvent {}
