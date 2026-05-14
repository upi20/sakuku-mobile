import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';

/// A square widget with a colored background and an icon centered inside,
/// matching the `layout_icon` RelativeLayout in the old app's item layouts.
class ColoredIcon extends StatelessWidget {
  final String iconName;
  final Color backgroundColor;
  final double size;
  final double iconSize;

  const ColoredIcon({
    super.key,
    required this.iconName,
    required this.backgroundColor,
    this.size = 40,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        AppIcons.fromName(iconName),
        color: Colors.white,
        size: iconSize,
      ),
    );
  }

  /// Parses a hex color string like "#2196f3" to a Color.
  static Color parseColor(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }
}
