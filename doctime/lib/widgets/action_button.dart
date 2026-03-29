// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS FILE EXISTS:
// patient_home_screen, doctor_home_screen, and guest_home_screen each had an
// IDENTICAL private method called _buildActionBtn(icon, title, color, onTap).
// Three copies = three places to update for any UI change.
//
// Extracted into a single shared StatelessWidget so all 3 screens import it.
// Add it to any new screen that needs a grid action button.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Reusable grid action button.
/// Used by: patient_home_screen, doctor_home_screen, guest_home_screen.
///
/// BEFORE: each of those screens had a private _buildActionBtn() method
/// with identical code. Now they all use this shared widget.
class ActionButton extends StatelessWidget {
  // The icon shown inside the coloured circle.
  final IconData icon;

  // The label shown below the icon.
  final String title;

  // The accent colour — used for the icon tint and the circle background.
  final Color color;

  // What happens when the user taps the button.
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Coloured circle background for the icon.
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 38),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
