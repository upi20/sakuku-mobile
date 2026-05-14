import '../../models/category_model.dart';

abstract class ICategoryRepository {
  Future<List<CategoryModel>> getAll({bool activeOnly = true});
  Future<List<CategoryModel>> getBySign(String sign, {bool activeOnly = true});
  Future<CategoryModel?> getById(int id);
  Future<int> create(CategoryModel category);
  Future<int> update(CategoryModel category);
  Future<int> delete(int id);
}
