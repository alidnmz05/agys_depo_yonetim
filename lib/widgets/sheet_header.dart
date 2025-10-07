import 'package:flutter/material.dart';

class SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const SheetHeader({super.key, required this.title, required this.subtitle, required this.icon});

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
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
      ],
    );
  }
}
