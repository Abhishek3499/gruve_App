import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/connections/data/datasource/connections_service.dart';
import 'package:gruve_app/features/connections/presentation/controller/connections_controller.dart';
import 'package:gruve_app/features/connections/presentation/widgets/connection_user_tile.dart';

class ConnectionsScreen extends StatefulWidget {
  final String userId;
  final int initialTabIndex;

  const ConnectionsScreen({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ConnectionsController _subscribersController;
  late final ConnectionsController _subscribedController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _subscribersController = ConnectionsController(
      userId: widget.userId,
      type: ConnectionType.subscribers,
    )..loadInitial();
    _subscribedController = ConnectionsController(
      userId: widget.userId,
      type: ConnectionType.subscribed,
    )..loadInitial();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 0) {
        _subscribersController.loadInitial();
      } else {
        _subscribedController.loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subscribersController.dispose();
    _subscribedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepPlum,
      appBar: AppBar(
        backgroundColor: AppColors.deepPlum,
        elevation: 0,
        title: const Text(
          'Connections',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFE24E0),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Subscribers'),
            Tab(text: 'Subscribed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ConnectionsList(controller: _subscribersController),
          _ConnectionsList(controller: _subscribedController),
        ],
      ),
    );
  }
}

class _ConnectionsList extends StatefulWidget {
  final ConnectionsController controller;

  const _ConnectionsList({required this.controller});

  @override
  State<_ConnectionsList> createState() => _ConnectionsListState();
}

class _ConnectionsListState extends State<_ConnectionsList> {
  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: widget.controller.isFetchingMore,
      hasMore: widget.controller.hasNext,
    )) {
      widget.controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        if (controller.isLoading && controller.users.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          );
        }

        if (controller.error != null && controller.users.isEmpty) {
          return Center(
            child: Text(
              controller.error!,
              style: const TextStyle(color: Colors.white60),
            ),
          );
        }

        if (controller.hasLoadedOnce && controller.users.isEmpty) {
          return const Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: Colors.white,
          backgroundColor: AppColors.deepPlum,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.users.length + (controller.hasNext ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.users.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                );
              }
              return ConnectionUserTile(
                user: controller.users[index],
                listType: controller.type,
              );
            },
          ),
        );
      },
    );
  }
}
