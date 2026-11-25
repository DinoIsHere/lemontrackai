import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key, required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = AppConstants.suggestionChips.take(3).toList();
    return Column(
      children: [
        for (int i = 0; i < suggestions.length; i++) ...[
          InkWell(
            onTap: () => onTap(suggestions[i]),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                suggestions[i],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (i < suggestions.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
        ],
      ],
    );
  }
}