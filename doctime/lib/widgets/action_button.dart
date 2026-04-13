import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final dynamic icon; // بضل dynamic عشان العداد يشتغل
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // رجعنا الخلفية بيضاء زي ما كانت
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.grey.shade100, width: 1.5), // رجعنا الحدود
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // لون خفيف خلف الأيقونة
                shape: BoxShape.circle,
              ),
              child: icon is Widget
                  ? icon
                  : Icon(icon as IconData,
                      color: color, size: 28), // الأيقونة بتاخد لونها الأصلي
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87, // رجعنا الخط غامق
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
