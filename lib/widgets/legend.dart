import 'package:flutter/material.dart';
import 'dot.dart';

class Legend extends StatelessWidget {
  final Color color;
  final String text;
  const Legend({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Dot(color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
