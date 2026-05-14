import 'package:equatable/equatable.dart';
import '../../../core/models/category_model.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
}

class CategoryLoad extends CategoryEvent {
  const CategoryLoad();
  @override
  List<Object?> get props => [];
}

class CategoryCreate extends CategoryEvent {
  final CategoryModel category;
  const CategoryCreate(this.category);
  @override
  List<Object?> get props => [category];
}

class CategoryUpdate extends CategoryEvent {
  final CategoryModel category;
  const CategoryUpdate(this.category);
  @override
  List<Object?> get props => [category];
}

class CategoryDelete extends CategoryEvent {
  final int id;
  const CategoryDelete(this.id);
  @override
  List<Object?> get props => [id];
}

class CategoryToggleActive extends CategoryEvent {
  final CategoryModel category;
  const CategoryToggleActive(this.category);
  @override
  List<Object?> get props => [category];
}
