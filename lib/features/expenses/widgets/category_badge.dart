import 'package:flutter/material.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/widgets/nb_badge.dart';

class CategoryBadge extends StatelessWidget {
  final String category;
  
  const CategoryBadge({super.key, required this.category});

  Color _getCategoryColor() {
    switch (category) {
      case 'Food': return NBColors.orange;
      case 'Travel': return NBColors.blue;
      case 'Rent': return NBColors.pink;
      case 'Shopping': return NBColors.purple;
      case 'Utilities': return NBColors.blue;
      case 'Entertainment': return NBColors.green;
      default: return NBColors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NBBadge(
      label: category.toUpperCase(),
      fillColor: _getCategoryColor(),
    );
  }
}
