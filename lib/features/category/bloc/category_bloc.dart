import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/interfaces/i_category_repository.dart';
import '../../../core/repositories/local/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ICategoryRepository _repo;

  CategoryBloc()
      : _repo = CategoryRepository(),
        super(const CategoryInitial()) {
    on<CategoryLoad>(_onLoad);
    on<CategoryCreate>(_onCreate);
    on<CategoryUpdate>(_onUpdate);
    on<CategoryDelete>(_onDelete);
    on<CategoryToggleActive>(_onToggleActive);
  }

  Future<void> _onLoad(
    CategoryLoad event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    try {
      final income = await _repo.getBySign('+', activeOnly: false);
      final expense = await _repo.getBySign('-', activeOnly: false);
      emit(CategoryLoaded(
        incomeCategories: income,
        expenseCategories: expense,
      ));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CategoryCreate event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repo.create(event.category);
      emit(const CategorySuccess('Kategori berhasil ditambahkan'));
      add(const CategoryLoad());
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    CategoryUpdate event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repo.update(event.category);
      emit(const CategorySuccess('Kategori berhasil diperbarui'));
      add(const CategoryLoad());
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onDelete(
    CategoryDelete event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      // Cascade delete: hapus semua History terkait, lalu hapus Category
      final db = await AppDatabase.instance.database;
      await db.transaction((txn) async {
        await txn.delete(
          'History',
          where: 'history_category_id = ?',
          whereArgs: [event.id],
        );
        await txn.delete(
          'Category',
          where: 'category_id = ?',
          whereArgs: [event.id],
        );
      });
      emit(const CategorySuccess('Kategori berhasil dihapus'));
      add(const CategoryLoad());
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onToggleActive(
    CategoryToggleActive event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final updated = event.category.copyWith(
        active: event.category.active == 1 ? 0 : 1,
      );
      await _repo.update(updated);
      add(const CategoryLoad());
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
