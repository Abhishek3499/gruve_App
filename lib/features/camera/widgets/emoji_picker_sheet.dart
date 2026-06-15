import 'dart:ui';
import 'package:flutter/material.dart';

class EmojiPickerSheet extends StatefulWidget {
  const EmojiPickerSheet({super.key});

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Map<String, String> _categoryIcons = {
    'Smileys & People': '😃',
    'Animals & Nature': '🐻',
    'Food & Drink': '🍔',
    'Activities & Sports': '⚽',
    'Travel & Places': '✈️',
    'Objects & Symbols': '💡',
  };

  static const Map<String, List<String>> _emojiCategories = {
    'Smileys & People': [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
      '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
      '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
      '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
      '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
      '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗',
      '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯',
      '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐',
      '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈',
      '👿', '👹', '👺', '🤡', '💩', '👻', '💀', '☠️', '👽', '👾',
      '🤖', '🎃', '😺', '😸', '😹', '😻', '😼', '😽', '🙀', '😿',
      '😾', '👋', '🤚', '🖐️', '✋', '🖖', '👌', '👍', '👎', '✊',
      '👊', '👏', '🙌', '👐', '🤲', '🙏', '✍️', '💅', '🤳', '💪',
      '🧠', '👀', '👅', '👄', '💋', '❤️', '💖', '✨'
    ],
    'Animals & Nature': [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
      '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒',
      '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇',
      '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜',
      '🦟', '🦗', '🕷️', '🕸️', '🦂', '🐢', '🐍', '🦎', '🐙', '🦑',
      '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊',
      '🐅', '🐆', '🦓', '🦍', '🦧', '🐘', '🦛', '🦏', '🐪', '🐫',
      '🦒', '🦘', '🐕', '🐈', '🐇', '🐿️', '🦔', '🐾', '🐉', '🌵',
      '🎄', '🌲', '🌳', '🌴', '🌱', '🌿', '🍀', '🍁', '🍄', '🌹',
      '🥀', '🌺', '🌸', '🌼', '🌻', '🌞', '🌝', '🌙', '⭐', '🌟',
      '✨', '⚡', '💥', '🔥', '🌈', '☀️', '🌤️', '⛅', '🌥️', '☁️',
      '🌧️', '⛈️', '❄️', '☃️', '🌊'
    ],
    'Food & Drink': [
      '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈',
      '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦',
      '🥬', '🥒', '🌶️', '🌽', '🥕', '🥔', '🍠', '🥐', '🥯', '🍞',
      '🥖', '🥨', '🧀', '🥚', '🍳', '🥞', '🥓', '🥩', '🍗', '🍖',
      '🌭', '🍔', '🍟', '🍕', '🥪', '🥙', '🌮', '🌯', '🥗', '🥘',
      '🍲', '🥣', '🥫', '🥟', '🍤', '🍣', '🍱', '🦪', '🍙', '🍚',
      '🍜', '🍝', '🍠', '🧁', '🍩', '🍪', '🎂', '🍰', '🍫', '🍬',
      '🍭', '🍮', '🍯', '☕', '🍵', '🍶', '🍷', '🍸', '🍹', '🍺',
      '🍻', '🥤', '🧃', '🧊'
    ],
    'Activities & Sports': [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🎱', '🪀',
      '🏓', '🏸', '🏒', '🏑', '🏏', '⛳', '🏹', '🎣', '🤿', '🥊',
      '🥋', '🥅', '🎯', '🛹', '🛷', '🎿', '⛷️', '🏂', '🏋️‍♀️', '🏋️‍♂️',
      '🤺', '🤸‍♀️', '🤸‍♂️', '⛹️‍♀️', '⛹️‍♂️', '🚴‍♀️', '🚴‍♂️', '🏆', '🥇', '🥈',
      '🥉', '🏅', '🎖️', '🎫', '🎟️', '🎪', '🎭', '🎨', '🎬', '🎤',
      '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸', '🎻', '🎲', '🧩',
      '🎳', '🎮', '🕹️', '🎰'
    ],
    'Travel & Places': [
      '🚗', '🚕', '🚙', '🚌', '🚐', '🏎️', '🚓', '🚑', '🚒', '🚚',
      '🚜', '🏍️', '🛵', '🚲', '🛴', '🛹', '🚨', '🚔', '🚍', '🚘',
      '🚖', '🚂', '🚆', '🚇', '✈️', '🛫', '🛬', '🛩️', '🚁', '🚀',
      '🛸', '🛎️', '🧳', '⌛', '⏳', '⌚', '⏰', '⏱️', '🧭', '🏔️',
      '⛰️', '🌋', '🗻', '🏕️', '🏖️', '🏜️', '🏝️', '🏞️', '🏟️', '🏛️',
      '🏠', '🏡', '🏢', '🏤', '🏥', '🏦', '🏨', '🏪', '🏫', '🏬',
      '🏭', '🏯', '🏰', '🗼', '🗽', '⛪', '🕌', '⛩️', '⛲', '⛺',
      '🌁', '🌃', '🏙️', '🌄', '🌅', '🌆', '🌇', '🌉', '🎠', '🎡',
      '🎢', '🚢', '⛵', '🛥️', '🚤', '⛴️', '⚓'
    ],
    'Objects & Symbols': [
      '💡', '🔦', '🕯️', '🔌', '🔋', '💻', '🖥️', '🖨️', '⌨️', '🖱️',
      '💿', '💾', '📷', '📹', '🎥', '🎞️', '📞', '☎️', '📟', '📠',
      '📺', '📻', '🎙️', '🎚️', '🎛️', '🧭', '⏰', '⌛', '📡', '🗑️',
      '🛢️', '💸', '💵', '💴', '💶', '💷', '🪙', '💰', '💳', '💎',
      '⚖️', '🔧', '🔨', '⚒️', '⛏️', '🛠️', '🛡️', '⚙️', '🔩', '🔑',
      '🔐', '✉️', '📩', '📨', '📦', '📫', '📬', '📭', '📮', '📝',
      '📁', '📂', '📅', '📆', '🗒️', '📈', '📉', '📊', '📋', '📌',
      '📍', '📎', '🖇️', '📏', '📐', '✂️', '🔒', '🔓', '🔏', '🗝️',
      '🪓', '⚔️', '🪃', '🏹', '🗜️', '🔗', '⛓️', '🔬', '🔭', '💉',
      '💊', '🩹', '🩺', '🚪', '🛏️', '🛋️', '🪑', '🚽', '🚿', '🛁',
      '🪒', '🧴', '🧻', '🧼', '🧽', '🪣', '🎁', '🎈', '🎏', '🎆',
      '🎇', '🧨', '🧧', '💌', '📥', '📤', '🔮', '🧿', '📿', '💈',
      '⚗️', '🕳️'
    ]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _emojiCategories.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredEmojis() {
    if (_searchQuery.isEmpty) return [];
    
    final allEmojis = _emojiCategories.values.expand((list) => list).toList();
    // In a production app, we would search by description keywords.
    // For a lightweight solution, we return matching characters if they are part of a lookup,
    // or just display a subset since exact semantic search requires a large database.
    // For search, we will simply return emojis matching category names or a subset of popular emojis
    // that are matching basic symbols.
    return allEmojis.where((emoji) {
      // Basic text queries to filter emojis (just matching characters or categories)
      return emoji.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchQuery.isNotEmpty;
    final filteredEmojis = _getFilteredEmojis();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.45,
          color: const Color(0xEB161616),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Bottom sheet handle bar
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: const Color(0xFFC358D7),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () => _searchController.clear(),
                            child: const Icon(Icons.close, color: Colors.white70, size: 18),
                          )
                        : null,
                    hintText: 'Search emojis...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Categories TabBar (only when not searching)
              if (!isSearching)
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: const Color(0xFFC358D7),
                  labelPadding: EdgeInsets.zero,
                  tabs: _emojiCategories.keys.map((category) {
                    return Tab(
                      child: Text(
                        _categoryIcons[category] ?? '',
                        style: const TextStyle(fontSize: 22),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),

              // Emoji Grid
              Expanded(
                child: isSearching
                    ? (filteredEmojis.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching emojis',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: filteredEmojis.length,
                            itemBuilder: (context, index) {
                              return EmojiTile(
                                emoji: filteredEmojis[index],
                                onTap: () => Navigator.pop(context, filteredEmojis[index]),
                              );
                            },
                          ))
                    : TabBarView(
                        controller: _tabController,
                        children: _emojiCategories.keys.map((category) {
                          final emojis = _emojiCategories[category]!;
                          return GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: emojis.length,
                            itemBuilder: (context, index) {
                              return EmojiTile(
                                emoji: emojis[index],
                                onTap: () => Navigator.pop(context, emojis[index]),
                              );
                            },
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmojiTile extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const EmojiTile({super.key, required this.emoji, required this.onTap});

  @override
  State<EmojiTile> createState() => _EmojiTileState();
}

class _EmojiTileState extends State<EmojiTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.82),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: Transform.scale(
        scale: _scale,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }
}
