import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/history_model.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/utils/date_formatter.dart';

/// Transaction list item matching item_history.xml and item_history_with_note.xml.
/// Tappable with ripple effect.
class HistoryListItem extends StatelessWidget {
  final HistoryModel item;
  final VoidCallback? onTap;

  const HistoryListItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconName = item.categoryIcon ?? 'ic_other';
    final bgColor = ColoredIcon.parseColor(item.categoryColor);
    final hasNote = item.note.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredIcon(iconName: iconName, backgroundColor: bgColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: category name | amount
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.categoryName ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AmountText(
                        amount: item.amount,
                        sign: item.sign,
                        type: item.type,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  // Row 2: account name | time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.accountName ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatTime(item.time),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                  // Note row (only when note exists)
                  if (hasNote) ...[
                    const SizedBox(height: 4),
                    const Divider(
                      color: AppColors.lightBlue,
                      height: 1,
                      thickness: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppColors.darkGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.note,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.darkGray,
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
    );
  }
}
