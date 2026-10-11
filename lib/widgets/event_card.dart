import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../utils/date_format.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final Widget? trailing;

  const EventCard({super.key, required this.event, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: event.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator())),
                errorWidget: (_, __, ___) => const SizedBox(
                    height: 150,
                    child: Center(child: Icon(Icons.image_not_supported))),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(event.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Chip(
                          label: Text(event.category,
                              style: const TextStyle(fontSize: 11))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormatUtil.dateTime(event.startDateTime),
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(event.locationName,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(event.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (trailing != null) ...[
                    const SizedBox(height: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
