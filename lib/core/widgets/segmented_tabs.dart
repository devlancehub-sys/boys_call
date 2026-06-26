import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selectedIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < labels.length - 1 ? 8 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.accent : AppColors.border),
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
