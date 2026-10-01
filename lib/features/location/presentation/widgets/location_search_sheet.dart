import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/location/data/location_service.dart';
import 'package:gruve_app/features/location/domain/place_suggestion.dart';

/// Bottom sheet with type-ahead place search.
/// Pops with the chosen place string, `''` to clear, or `null` if dismissed.
Future<String?> showLocationSearchSheet(
  BuildContext context, {
  String? currentLocation,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LocationSearchSheet(currentLocation: currentLocation),
  );
}

class _LocationSearchSheet extends StatefulWidget {
  final String? currentLocation;
  const _LocationSearchSheet({this.currentLocation});

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  CancelToken? _cancelToken;
  List<PlaceSuggestion> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _cancelToken?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    final token = CancelToken();
    _cancelToken = token;
    try {
      final results = await LocationService.search(query, cancelToken: token);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || (e is DioException && CancelToken.isCancel(e))) return;
      setState(() {
        _loading = false;
        _error = 'Could not load locations. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrent =
        widget.currentLocation != null && widget.currentLocation!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: context.rw(20),
        right: context.rw(20),
        top: context.rh(20),
      ),
      child: SizedBox(
        height: context.rh(460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.rf(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasCurrent)
                  TextButton(
                    onPressed: () => Navigator.pop(context, ''),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
            SizedBox(height: context.rh(12)),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lavenderPurple),
                ),
              ),
            ),
            SizedBox(height: context.rh(8)),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lavenderPurple),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white54)),
      );
    }
    if (_results.isEmpty) {
      final searched = _controller.text.trim().length >= 2;
      return Center(
        child: Text(
          searched ? 'No locations found' : 'Type to search places',
          style: const TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(color: Colors.white10, height: 1),
      itemBuilder: (context, i) {
        final place = _results[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.location_on_outlined,
            color: Colors.white54,
          ),
          title: Text(
            place.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: place.subtitle == null
              ? null
              : Text(
                  place.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
          onTap: () => Navigator.pop(context, place.formatted),
        );
      },
    );
  }
}
