import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom sheet untuk memilih ikon dan warna rekening/kategori.
class IconColorPickerSheet extends StatefulWidget {
  final String selectedIcon;
  final String selectedColor;
  final void Function(String icon, String color) onSelected;

  const IconColorPickerSheet({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  State<IconColorPickerSheet> createState() => _IconColorPickerSheetState();
}

class _IconColorPickerSheetState extends State<IconColorPickerSheet> {
  late String _icon;
  late String _color;

  static const List<String> _colors = [
    '#f44336', '#e91e63', '#9c27b0', '#673ab7',
    '#3f51b5', '#2196f3', '#03a9f4', '#0288d1',
    '#009688', '#4caf50', '#8bc34a', '#cddc39',
    '#ffeb3b', '#ffc107', '#ff9800', '#ff5722',
    '#795548', '#9e9e9e', '#607d8b', '#323643',
  ];

  @override
  void initState() {
    super.initState();
    _icon = widget.selectedIcon;
    _color = widget.selectedColor;
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final pickerColor = _parseColor(_color);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Pilih Ikon & Warna',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('Ikon',
                        style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant)),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: AppIcons.allIcons.map((entry) {
                      final selected = entry.key == _icon;
                      return GestureDetector(
                        onTap: () => setState(() => _icon = entry.key),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: selected
                                ? pickerColor.withAlpha(40)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? pickerColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            color: selected
                                ? pickerColor
                                : cs.onSurfaceVariant,
                            size: 28,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('Warna',
                        style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colors.map((hex) {
                        final c = _parseColor(hex);
                        final selected = _color == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _color = hex),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? cs.outline
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onSelected(_icon, _color);
                  Navigator.pop(context);
                },
                child: const Text('PILIH'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
