class AccountModel {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final int active;

  const AccountModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.active = 1,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['account_id'] as int?,
      name: map['account_name'] as String,
      icon: map['account_icon'] as String,
      color: map['account_color'] as String,
      active: map['account_active'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'account_id': id,
      'account_name': name,
      'account_icon': icon,
      'account_color': color,
      'account_active': active,
    };
  }

  AccountModel copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? active,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      active: active ?? this.active,
    );
  }

  @override
  String toString() => 'AccountModel(id: $id, name: $name)';
}
