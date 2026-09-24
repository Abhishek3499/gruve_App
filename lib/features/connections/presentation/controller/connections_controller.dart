import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/connections/data/datasource/connections_service.dart';
import 'package:gruve_app/features/connections/domain/entities/connection_user_model.dart';

class ConnectionsController extends ChangeNotifier {
  ConnectionsController({
    required this.userId,
    required this.type,
    ConnectionsService? service,
  }) : _service = service ?? ConnectionsService();

  final String userId;
  final ConnectionType type;
  final ConnectionsService _service;

  final List<ConnectionUser> _users = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasNext = true;
  bool _hasLoadedOnce = false;
  int _page = 1;
  String? _error;
  CancelToken? _cancelToken;

  List<ConnectionUser> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasNext => _hasNext;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get error => _error;

  Future<void> loadInitial() async {
    if (_isLoading || _hasLoadedOnce) return;
    await _fetch(reset: true);
  }

  Future<void> refresh() async {
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    if (_isLoading || _isFetchingMore || !_hasNext) return;
    await _fetch(reset: false);
  }

  /// Removes/updates a row in place after a subscribe toggle so counts and
  /// list membership stay consistent without a full refetch.
  void updateSubscribedState(String userId, bool isSubscribed) {
    final index = _users.indexWhere((u) => u.userId == userId);
    if (index == -1) return;
    final current = _users[index];
    _users[index] = ConnectionUser(
      userId: current.userId,
      username: current.username,
      fullName: current.fullName,
      profilePicture: current.profilePicture,
      bio: current.bio,
      isSubscribed: isSubscribed,
    );
    notifyListeners();
  }

  Future<void> _fetch({required bool reset}) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    if (reset) {
      _isLoading = true;
      _page = 1;
      _error = null;
      notifyListeners();
    } else {
      _isFetchingMore = true;
      notifyListeners();
    }

    try {
      final result = await _service.getConnections(
        userId: userId,
        type: type,
        page: _page,
        cancelToken: _cancelToken,
      );

      if (reset) {
        _users
          ..clear()
          ..addAll(result.results);
      } else {
        final existingIds = _users.map((u) => u.userId).toSet();
        _users.addAll(
          result.results.where((u) => !existingIds.contains(u.userId)),
        );
      }

      _hasNext = result.hasNext;
      if (_hasNext) _page += 1;
      _hasLoadedOnce = true;
      _error = null;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      AppLogger.d('[ConnectionsController] fetch failed (${type.param}): $e');
      _error = 'Failed to load. Pull to refresh.';
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
