import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/events_filter_provider.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<EventsFilterProvider>();
    const options = ['all', ...EventCategory.all];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: options.map((c) {
          final selected = filter.category == c;
          final label = c == 'all' ? 'All' : EventCategory.label(c);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => context
                  .read<EventsFilterProvider>()
                  .setCategory(c),
            ),
          );
        }).toList(),
      ),
    );
  }
}
