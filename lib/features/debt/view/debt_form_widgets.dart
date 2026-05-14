import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/account_model.dart';
import '../../../shared/widgets/colored_icon.dart';

class DebtTypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const DebtTypeButton(
      {super.key,
      required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : color)),
        ),
      ),
    );
  }
}

class DebtAccountSection extends StatelessWidget {
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final void Function(AccountModel) onPick;
  const DebtAccountSection(
      {super.key,
      required this.accounts,
      required this.selected,
      required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REKENING',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final acc = await showModalBottomSheet<AccountModel>(
                context: context,
                builder: (_) => DebtAccountPicker(accounts: accounts),
              );
              if (acc != null) onPick(acc);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (selected != null) ...[
                    ColoredIcon(
                      iconName: selected!.icon,
                      backgroundColor:
                          ColoredIcon.parseColor(selected!.color),
                      size: 28,
                      iconSize: 16,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      selected?.name ?? 'Pilih rekening',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected != null
                              ? AppColors.darkBlue
                              : AppColors.disabled),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      color: AppColors.darkGray),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DebtAccountPicker extends StatelessWidget {
  final List<AccountModel> accounts;
  const DebtAccountPicker({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: accounts.length,
      itemBuilder: (_, i) {
        final acc = accounts[i];
        return ListTile(
          leading: ColoredIcon(
            iconName: acc.icon,
            backgroundColor: ColoredIcon.parseColor(acc.color),
          ),
          title: Text(acc.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
          onTap: () => Navigator.of(context).pop(acc),
        );
      },
    );
  }
}

class DebtFormCard extends StatelessWidget {
  final String label;
  final Widget child;
  const DebtFormCard({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class DebtDateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const DebtDateButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.darkBlue),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class DebtDateSection extends StatelessWidget {
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final VoidCallback onPickStart;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEnd;
  final VoidCallback onPickEndTime;
  final VoidCallback onClearEnd;
  final String Function(DateTime) formatDateDisplay;
  final String Function(TimeOfDay) formatTime;

  const DebtDateSection({
    super.key,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.onPickStart,
    required this.onPickStartTime,
    required this.onPickEnd,
    required this.onPickEndTime,
    required this.onClearEnd,
    required this.formatDateDisplay,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TANGGAL MULAI',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DebtDateButton(
                  label: formatDateDisplay(startDate),
                  icon: Icons.calendar_today,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 8),
              DebtDateButton(
                label: formatTime(startTime),
                icon: Icons.access_time,
                onTap: onPickStartTime,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('JATUH TEMPO (OPSIONAL)',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray)),
              if (endDate != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearEnd,
                  child: const Icon(Icons.clear,
                      size: 16, color: AppColors.darkGray),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DebtDateButton(
                  label: endDate != null
                      ? formatDateDisplay(endDate!)
                      : 'Pilih tanggal',
                  icon: Icons.calendar_today,
                  onTap: onPickEnd,
                ),
              ),
              const SizedBox(width: 8),
              DebtDateButton(
                label: endTime != null ? formatTime(endTime!) : '--:--',
                icon: Icons.access_time,
                onTap: onPickEndTime,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
