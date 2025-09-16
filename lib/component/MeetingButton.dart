import 'package:flutter/material.dart';

class Buttons extends StatelessWidget {
  final String text;
  final IconData? icon;
  final void Function()? onTap;
  const Buttons({super.key, this.onTap, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 35, color: Colors.white),
            Text(text, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
