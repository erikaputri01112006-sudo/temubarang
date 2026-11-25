import 'package:flutter/material.dart';
import 'package:temubarang/core/theme/app_theme.dart';

class ItemBadge extends StatelessWidget {
  const ItemBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  });

  factory ItemBadge.type(String type) {
    final isLost = type == 'lost';
    return ItemBadge(
      label: isLost ? 'Barang Hilang' : 'Barang Temuan',
      textColor: isLost ? AppTheme.lostColor : AppTheme.foundColor,
      backgroundColor: isLost ? AppTheme.lostBgColor : AppTheme.foundBgColor,
      icon: isLost ? Icons.search_off_rounded : Icons.volunteer_activism_rounded,
    );
  }

  factory ItemBadge.status(String status) {
    final isResolved = status == 'resolved';
    return ItemBadge(
      label: isResolved ? 'Selesai' : 'Aktif',
      textColor: isResolved ? AppTheme.resolvedColor : AppTheme.primarySeed,
      backgroundColor: isResolved
          ? AppTheme.resolvedBgColor
          : const Color(0xFFCCFBF1),
      icon: isResolved ? Icons.check_circle_rounded : Icons.bolt_rounded,
    );
  }

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
