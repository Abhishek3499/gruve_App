import 'package:flutter/material.dart';
import '../models/idea_item.dart';
import 'idea_card.dart';

class IdeasColumn extends StatelessWidget {
  final Widget? header;
  final List<IdeaItem> items;

  const IdeasColumn({
    super.key,
    this.header,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        if (header != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: header!,
          ),
        // List of Cards
        ...items.map((item) => IdeaCard(item: item)),
      ],
    );
  }
}
