import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/auth/current_user_notifier.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/core/media/video_playback_guard.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/search/domain/entities/explore_story_model.dart';
import 'package:gruve_app/features/search/presentation/controller/explore_reels_controller.dart';
import 'package:gruve_app/features/search/presentation/notifiers/explore_stories_notifier.dart';
import 'package:gruve_app/features/search/presentation/screens/search_page.dart';
import 'package:gruve_app/features/search/presentation/widgets/explore_discover_grid.dart';
import 'package:gruve_app/features/search/presentation/widgets/explore_story_rows.dart';
import 'package:gruve_app/features/search/presentation/widgets/explore_top_bar.dart';
import 'package:gruve_app/features/story_preview/utils/story_utils.dart';
import 'package:gruve_app/shared/widgets/shimmer/app_shimmer.dart';

/// Discovery tab: Friends stories, Following stories and Discover reels.
class SearchScreen extends ConsumerStatefulWidget {
  /// Opens the profile tab.
  final VoidCallback? onProfileTap;

  /// Opens the camera so the user can add a story.
  final VoidCallback? onAddStory;

  const SearchScreen({super.key, this.onProfileTap, this.onAddStory});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final ExploreReelsController _discover;
  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger(
    threshold: 320,
  );
  bool _isOpeningStory = false;

  @override
  void initState() {
    super.initState();
    _discover = ExploreReelsController()..addListener(_onDiscoverChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(exploreStoriesNotifierProvider.notifier).load();
      _discover.loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _discover
      ..removeListener(_onDiscoverChanged)
      ..dispose();
    super.dispose();
  }

  void _onDiscoverChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: _discover.isLoading || _discover.isLoadingMore,
      hasMore: _discover.hasMore,
    )) {
      _discover.loadMore(reason: 'scroll');
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(exploreStoriesNotifierProvider.notifier).load(silent: true),
      _discover.refresh(),
    ]);
  }

  Future<void> _openStory(ExploreStory story, {bool isOwn = false}) async {
    if (_isOpeningStory) return;
    _isOpeningStory = true;
    // Free the feed's hardware video decoders before the story player starts.
    VideoPlaybackGuard.pauseHomeFeed?.call();
    await VideoFrameCache.disposeUnreferenced();
    if (!mounted) {
      _isOpeningStory = false;
      return;
    }
    try {
      await StoryUtils.navigateToStoryView(
        context,
        userId: isOwn ? null : story.user.id,
        displayName: story.user.displayName,
        username: story.user.username,
        avatar: story.user.profilePicture,
        isOwnProfile: isOwn,
      );
      // Views are recorded while watching; pull the tray again so rings drop
      // and fully-watched users move to the end of their row.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await ref
            .read(exploreStoriesNotifierProvider.notifier)
            .load(silent: true);
      }
    } finally {
      _isOpeningStory = false;
    }
  }

  void _openSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(exploreStoriesNotifierProvider);
    final myAvatar = ref.watch(
      currentUserNotifierProvider.select((s) => s.profileImageUrl),
    );
    final data = stories.data;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.2, -1.0),
            end: Alignment(0.2, 1.0),
            colors: [AppColors.deepPlum, Color(0xFF210C26), Color(0xFF000000)],
            stops: [0.0, 0.4172, 0.9933],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ExploreTopBar(
                onProfileTap: widget.onProfileTap ?? () {},
                onSearchTap: _openSearch,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.loaderDark,
                  backgroundColor: Colors.white24,
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    cacheExtent: 900,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: !stories.hasLoaded
                            ? const _StoriesShimmer()
                            : FriendsStoriesRow(
                                myStory: data.myStory,
                                myAvatarUrl: myAvatar,
                                friends: data.friends,
                                onAddStory: widget.onAddStory ?? () {},
                                onMyStoryTap: () =>
                                    _openStory(data.myStory!, isOwn: true),
                                onStoryTap: _openStory,
                              ),
                      ),
                      if (data.following.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: context.rh(8)),
                            child: const ExploreSectionTitle('Following'),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: FollowingStoriesRow(
                            stories: data.following,
                            onStoryTap: _openStory,
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: context.rh(12)),
                          child: const ExploreSectionTitle('Discover'),
                        ),
                      ),
                      ..._buildDiscover(context),
                      SliverToBoxAdapter(
                        child: SizedBox(height: context.rh(80)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDiscover(BuildContext context) {
    if (_discover.isLoading && _discover.reels.isEmpty) {
      return [const _DiscoverShimmer()];
    }

    if (_discover.error != null && _discover.reels.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _Message(
            text: _discover.error!,
            actionLabel: 'Try again',
            onAction: _discover.refresh,
          ),
        ),
      ];
    }

    if (_discover.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: _Message(text: 'Nothing to discover yet'),
        ),
      ];
    }

    return [
      ExploreDiscoverSliver(controller: _discover),
      if (_discover.isLoadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(context.rw(16)),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.loaderDark,
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

class _Message extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(32),
        vertical: context.rh(48),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _StoriesShimmer extends StatelessWidget {
  const _StoriesShimmer();

  @override
  Widget build(BuildContext context) {
    final size = context.rw(68);
    return AppShimmer(
      child: SizedBox(
        height: size + context.rh(34),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
          itemCount: 5,
          separatorBuilder: (_, _) => SizedBox(width: context.rw(12)),
          itemBuilder: (_, _) => Column(
            children: [
              ShimmerBox(width: size, height: size, borderRadius: size / 2),
              SizedBox(height: context.rh(6)),
              ShimmerBox(width: size * 0.8, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverShimmer extends StatelessWidget {
  const _DiscoverShimmer();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: context.rw(10),
          mainAxisSpacing: context.rw(10),
          childAspectRatio: 0.6,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => AppShimmer(
            child: const ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 10,
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }
}
