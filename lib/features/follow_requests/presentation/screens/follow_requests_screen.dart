import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/follow_requests/data/follow_request_service.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  final _service = FollowRequestService();
  List<FollowRequestModel> _requests = [];
  bool _loading = true;
  String? _error;

  // Track which userIds are currently being acted on
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchRequests();
      if (mounted) setState(() => _requests = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(String userId, String action) async {
    setState(() => _processing.add(userId));
    try {
      await _service.respondToRequest(userId, action);
      if (mounted) {
        setState(() => _requests.removeWhere((r) => r.userId == userId));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.deepPlum, Color(0xFF212235)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    BackButton(
                      color: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Follow Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_requests.isEmpty) {
      return const Center(
        child: Text(
          'No pending follow requests',
          style: TextStyle(color: Colors.white60, fontSize: 15),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: Colors.white,
      backgroundColor: AppColors.deepPlum,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _requests.length,
        itemBuilder: (context, index) => _RequestTile(
          request: _requests[index],
          isProcessing: _processing.contains(_requests[index].userId),
          onAccept: () => _respond(_requests[index].userId, 'accept'),
          onReject: () => _respond(_requests[index].userId, 'reject'),
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

  final FollowRequestModel request;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white12,
            backgroundImage:
                (request.profilePicture != null &&
                    request.profilePicture!.isNotEmpty)
                ? NetworkImage(request.profilePicture!)
                : null,
            child:
                (request.profilePicture == null ||
                    request.profilePicture!.isEmpty)
                ? Text(
                    request.username.isNotEmpty
                        ? request.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name + username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fullName.isNotEmpty
                      ? request.fullName
                      : request.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '@${request.username}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          // Buttons
          if (isProcessing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else ...[
            _ActionButton(
              label: 'Accept',
              color: const Color(0xFFFE24E0),
              onTap: onAccept,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Reject',
              color: Colors.white12,
              onTap: onReject,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
