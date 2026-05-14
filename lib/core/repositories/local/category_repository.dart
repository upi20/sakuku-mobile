import '../../database/daos/category_dao.dart';
import '../../models/category_model.dart';
import '../interfaces/i_category_repository.dart';

class CategoryRepository implements ICategoryRepository {
  final CategoryDao _dao;

  CategoryRepository({CategoryDao? dao}) : _dao = dao ?? CategoryDao();

  @override
  Future<List<CategoryModel>> getAll({bool activeOnly = true}) =>
      _dao.getAll(activeOnly: activeOnly);

  @override
  Future<List<CategoryModel>> getBySign(String sign,
          {bool activeOnly = true}) =>
      _dao.getBySign(sign, activeOnly: activeOnly);

  @override
  Future<CategoryModel?> getById(int id) => _dao.getById(id);

  @override
  Future<int> create(CategoryModel category) => _dao.insert(category);

  @override
  Future<int> update(CategoryModel category) => _dao.update(category);

  @override
  Future<int> delete(int id) => _dao.softDelete(id);
}
