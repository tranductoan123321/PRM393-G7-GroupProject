import 'package:flutter/material.dart';

const _ink = Color(0xFF001D34);

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    required this.title,
    required this.action,
    super.key,
  });

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: _ink),
            ),
          ),
          TextButton(onPressed: null, child: Text(action)),
        ],
      ),
    ),
  );
}
