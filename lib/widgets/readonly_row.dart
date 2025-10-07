import 'package:flutter/material.dart';

class ReadonlyRow extends StatelessWidget {
  final String label;
  final String value;
  const ReadonlyRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
