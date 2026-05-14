class CategoryModel {
  final int? id;
  final String name;
  final String sign; // '+' or '-'
  final String icon;
  final String color;
  final int active;
  final int editable;

  const CategoryModel({
    this.id,
    required this.name,
    required this.sign,
    required this.icon,
    required this.color,
    this.active = 1,
    this.editable = 1,
  });

  bool get isIncome => sign == '+';
  bool get isExpense => sign == '-';

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['category_id'] as int?,
      name: map['category_name'] as String,
      sign: map['category_sign'] as String,
      icon: map['category_icon'] as String,
      color: map['category_color'] as String,
      active: map['category_active'] as int,
      editable: map['category_editable'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'category_id': id,
      'category_name': name,
      'category_sign': sign,
      'category_icon': icon,
      'category_color': color,
      'category_active': active,
      'category_editable': editable,
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? sign,
    String? icon,
    String? color,
    int? active,
    int? editable,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sign: sign ?? this.sign,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      active: active ?? this.active,
      editable: editable ?? this.editable,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name, sign: $sign)';
}
