import 'package:flutter/material.dart';

class SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final List<Widget>? actions;
  const SheetHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),

        if (actions != null && actions!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children:
                actions!
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: w,
                      ),
                    )
                    .toList(),
          )
        else if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
