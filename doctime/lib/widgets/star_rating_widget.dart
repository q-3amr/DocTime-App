// ─────────────────────────────────────────────────────────────────────────────
// StarRatingWidget
//
// A reusable 1–5 star widget with two modes:
//   • Interactive (isReadOnly: false): tapping a star sets the rating.
//     Used in feedback popups in patient_home_screen.dart.
//   • Display-only (isReadOnly: true): renders filled/half/empty stars from
//     a double value. Used in doctor_reviews_screen.dart and
//     doctor_details_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class StarRatingWidget extends StatefulWidget {
  /// Current rating value (1.0 – 5.0).
  final double initialRating;

  /// Called whenever the user taps a star (only fires when isReadOnly: false).
  final ValueChanged<double>? onRatingChanged;

  /// Size of each star icon. Defaults to 32 in interactive, 20 in read-only.
  final double starSize;

  /// When true, the widget is non-interactive and just displays the rating.
  final bool isReadOnly;

  const StarRatingWidget({
    super.key,
    this.initialRating = 5.0,
    this.onRatingChanged,
    this.starSize = 32.0,
    this.isReadOnly = false,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating.clamp(1.0, 5.0);
  }

  void _onStarTapped(int starIndex) {
    if (widget.isReadOnly) return;
    final newRating = starIndex.toDouble();
    setState(() => _currentRating = newRating);
    widget.onRatingChanged?.call(newRating);
  }

  /// Returns the correct icon for a star position given a fractional rating.
  /// e.g. rating 3.7 → stars 1,2,3 are full; star 4 is half; star 5 is empty.
  IconData _iconForStar(int starIndex) {
    if (_currentRating >= starIndex) {
      return Icons.star_rounded; // full
    } else if (_currentRating >= starIndex - 0.5) {
      return Icons.star_half_rounded; // half
    } else {
      return Icons.star_outline_rounded; // empty
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final icon = _iconForStar(starIndex);
        final isFilled = icon != Icons.star_outline_rounded;

        if (widget.isReadOnly) {
          return Icon(
            icon,
            color: isFilled ? Colors.amber : Colors.grey.shade300,
            size: widget.starSize,
          );
        }

        // Interactive: wrap each star in a GestureDetector
        return GestureDetector(
          onTap: () => _onStarTapped(starIndex),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              key: ValueKey('$starIndex-$_currentRating'),
              icon,
              color: isFilled ? Colors.amber : Colors.grey.shade300,
              size: widget.starSize,
            ),
          ),
        );
      }),
    );
  }
}
