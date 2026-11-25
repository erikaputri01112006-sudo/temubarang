import 'package:flutter/material.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
  });

  final int id;
  final String name;
  final String iconName;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      iconName: (json['icon_name'] as String?) ?? 'category',
    );
  }

  IconData get icon {
    switch (iconName) {
      case 'devices':
        return Icons.devices_rounded;
      case 'badge':
        return Icons.badge_rounded;
      case 'wallet':
        return Icons.wallet_rounded;
      case 'key':
        return Icons.key_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'watch':
        return Icons.watch_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
