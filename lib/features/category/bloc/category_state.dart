import 'package:equatable/equatable.dart';
import '../../../core/models/category_model.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
  @override
  List<Object?> get props => [];
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
  @override
  List<Object?> get props => [];
}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> incomeCategories;
  final List<CategoryModel> expenseCategories;

  const CategoryLoaded({
    required this.incomeCategories,
    required this.expenseCategories,
  });

  @override
  List<Object?> get props => [incomeCategories, expenseCategories];
}

class CategorySuccess extends CategoryState {
  final String message;
  const CategorySuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object?> get props => [message];
}
