import 'package:flutter/material.dart';

/// Maps icon names from the original Android app to Flutter MaterialIcons
class AppIcons {
  AppIcons._();

  static IconData fromName(String name) {
    return _iconMap[name] ?? Icons.category_outlined;
  }

  static const Map<String, IconData> _iconMap = {
    // Account icons
    'ic_bank': Icons.account_balance,
    'ic_cash': Icons.account_balance_wallet,
    'ic_gopay': Icons.phone_android,
    'ic_e_wallet': Icons.wallet,
    'ic_graph': Icons.show_chart,
    'ic_other': Icons.more_horiz,

    // Category - system/transfer
    'ic_transfer': Icons.swap_horiz,
    'ic_transfer_expense': Icons.arrow_upward,
    'ic_transfer_income': Icons.arrow_downward,
    'ic_debt': Icons.credit_card,
    'ic_debt_collection': Icons.request_quote,
    'ic_loan': Icons.monetization_on,
    'ic_repayment': Icons.payment,
    'ic_initial': Icons.account_balance_wallet,

    // Category - income
    'ic_money': Icons.attach_money,
    'ic_work': Icons.work,
    'ic_youtube': Icons.play_circle_outline,
    'ic_love': Icons.favorite_border,

    // Category - expense
    'ic_shopping_2': Icons.shopping_bag_outlined,
    'ic_food': Icons.restaurant,
    'ic_drink': Icons.local_cafe,
    'ic_drink_2': Icons.local_bar,
    'ic_kitchen': Icons.kitchen,
    'ic_bus': Icons.directions_bus,
    'ic_car': Icons.directions_car,
    'ic_motorcycle': Icons.two_wheeler,
    'ic_flight': Icons.flight,
    'ic_train': Icons.train,
    'ic_fuel': Icons.local_gas_station,
    'ic_gadget': Icons.devices,
    'ic_game': Icons.sports_esports,
    'ic_movie': Icons.movie,
    'ic_ticket': Icons.confirmation_number,
    'ic_education': Icons.school,
    'ic_water': Icons.water_drop,
    'ic_electric': Icons.bolt,
    'ic_electronic': Icons.electrical_services,
    'ic_furniture': Icons.chair,
    'ic_fitness': Icons.fitness_center,
    'ic_hospital': Icons.local_hospital,
    'ic_pet': Icons.pets,
    'ic_cake': Icons.cake,
    'ic_building': Icons.business,
    'ic_baby': Icons.child_care,
  };

  /// All icons available for category/account selection
  static List<MapEntry<String, IconData>> get allIcons =>
      _iconMap.entries.toList();

  /// Icons suitable for accounts
  static List<MapEntry<String, IconData>> get accountIcons => [
        const MapEntry('ic_bank', Icons.account_balance),
        const MapEntry('ic_cash', Icons.account_balance_wallet),
        const MapEntry('ic_gopay', Icons.phone_android),
        const MapEntry('ic_e_wallet', Icons.wallet),
        const MapEntry('ic_graph', Icons.show_chart),
        const MapEntry('ic_other', Icons.more_horiz),
      ];

  /// Icons suitable for categories
  static List<MapEntry<String, IconData>> get categoryIcons => _iconMap.entries
      .where((e) => !e.key.startsWith('ic_bank') && e.key != 'ic_cash')
      .toList();
}
