import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/history_model.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../../../shared/widgets/amount_text.dart';

/// Transaction list item — rounded card design matching HTML mockup.
class HistoryListItem extends StatelessWidget {
  final HistoryModel item;
  final VoidCallback? onTap;

  const HistoryListItem({
    super.key,
    required this.item,
    this.onTap,
  });

  bool get _isTransfer => item.type == 2 || item.type == 4;

  @override
  Widget build(BuildContext context) {
    final iconName = item.categoryIcon ?? 'ic_other';
    final bgColor = ColoredIcon.parseColor(item.categoryColor);
    final hasNote = item.note.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ColoredIcon(iconName: iconName, backgroundColor: bgColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: category name | amount
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              item.categoryName ?? '-',
                              style: context.tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Transfer shows amount + swap icon; others normal
                          if (_isTransfer)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AmountText(
                                  amount: item.amount,
                                  sign: item.sign,
                                  type: item.type,
                                  style: context.tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  compact: true,
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.swap_horiz,
                                    size: 14, color: AppTheme.transfer),
                              ],
                            )
                          else
                            AmountText(
                              amount: item.amount,
                              sign: item.sign,
                              type: item.type,
                              style: context.tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              compact: true,
                            ),
                        ],
                      ),
                      // Row 2: account name
                      Text(
                        item.accountName ?? '-',
                        style: context.tt.bodySmall?.copyWith(
                          color: context.cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Row 3: note text (if exists)
                      if (hasNote) ...[
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              size: 12,
                              color: context.cs.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.note,
                                style: context.tt.bodySmall?.copyWith(
                                  color: context.cs.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
