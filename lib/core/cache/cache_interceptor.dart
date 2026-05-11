import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/network/app_dio.dart';

/// Dio interceptor for automatic response caching
class CacheInterceptor extends Interceptor {
  final CacheManager _cacheManager = CacheManager();
  final bool _enableMemoryCache;
  final bool _enableDiskCache;

  CacheInterceptor({
    bool enableMemoryCache = true,
    bool enableDiskCache = true,
  }) : _enableMemoryCache = enableMemoryCache,
       _enableDiskCache = enableDiskCache;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip caching for certain requests
    if (_shouldSkipCaching(options)) {
      handler.next(options);
      return;
    }

    final cacheKey = _generateCacheKey(options);
    final config = CacheConfigs.getConfigForEndpoint(options.path);

    // Try to get cached data with stale-while-revalidate
    final cacheResult = await _cacheManager.getWithStaleRevalidate<Map<String, dynamic>>(
      cacheKey,
      (data) => data is Map<String, dynamic> ? data : {},
      config,
      () => _performRequest(options),
      toJson: (data) => data,
    );

    if (cacheResult.hasData && !cacheResult.isStale) {
      debugPrint('🎯 [CacheInterceptor] Cache hit: ${options.path}');
      
      // Return cached response
      final cachedResponse = Response(
        data: cacheResult.data,
        statusCode: 200,
        requestOptions: options,
        extra: {'fromCache': true},
      );
      handler.resolve(cachedResponse);
      return;
    }

    if (cacheResult.hasData && cacheResult.isStale) {
      debugPrint('🔄 [CacheInterceptor] Stale data returned: ${options.path}');
      
      // Return stale data while refreshing in background
      final staleResponse = Response(
        data: cacheResult.data,
        statusCode: 200,
        requestOptions: options,
        extra: {'fromCache': true, 'isStale': true},
      );
      handler.resolve(staleResponse);
      return;
    }

    // No cached data, proceed with request
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Skip caching for certain responses
    if (_shouldSkipCaching(response.requestOptions)) {
      handler.next(response);
      return;
    }

    // Only cache successful GET requests
    if (response.requestOptions.method.toUpperCase() == 'GET' && 
        (response.statusCode ?? 0) >= 200 && 
        (response.statusCode ?? 0) < 300) {
      
      final cacheKey = _generateCacheKey(response.requestOptions);
      final config = CacheConfigs.getConfigForEndpoint(response.requestOptions.path);

      await _cacheManager.put(
        cacheKey,
        response.data,
        config,
        toJson: (data) => data,
      );

      debugPrint('💾 [CacheInterceptor] Cached response: ${response.requestOptions.path}');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Try to return stale data on network errors
    if (_shouldReturnStaleOnError(err)) {
      final cacheKey = _generateCacheKey(err.requestOptions);
      final config = CacheConfigs.getConfigForEndpoint(err.requestOptions.path);

      final cached = await _cacheManager.get<Map<String, dynamic>>(
        cacheKey,
        (data) => data is Map<String, dynamic> ? data : {},
        config,
      );

      if (cached != null) {
        debugPrint('🔄 [CacheInterceptor] Returned stale data on error: ${err.requestOptions.path}');
        
        final staleResponse = Response(
          data: cached,
          statusCode: 200,
          requestOptions: err.requestOptions,
          extra: {'fromCache': true, 'isStale': true, 'fromError': true},
        );
        handler.resolve(staleResponse);
        return;
      }
    }

    handler.next(err);
  }

  /// Performs the actual request using a fresh Dio instance
  Future<Map<String, dynamic>> _performRequest(RequestOptions options) async {
    final dio = AppDio.create();
    try {
      final response = await dio.fetch(options);
      return response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic>
          : {};
    } catch (e) {
      rethrow;
    }
  }

  /// Generates a unique cache key for the request
  String _generateCacheKey(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write('${options.method}:${options.path}');
    
    // Add query parameters
    if (options.queryParameters.isNotEmpty) {
      final sortedParams = Map<String, dynamic>.fromEntries(
        options.queryParameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write('?${sortedParams.toString()}');
    }
    
    // Add user-specific prefix if available
    if (options.headers.containsKey('Authorization')) {
      // Extract user identifier from token or use generic prefix
      buffer.write('_user');
    }
    
    return buffer.toString();
  }

  /// Determines if a request should skip caching
  bool _shouldSkipCaching(RequestOptions options) {
    final skipPaths = {
      '/auth/',
      '/logout',
      '/refresh',
      '/upload',
      '/delete',
      '/update',
      '/create',
    };

    final method = options.method.toUpperCase();
    final isWriteOperation = method == 'POST' || method == 'PUT' || method == 'DELETE' || method == 'PATCH';

    return isWriteOperation ||
           skipPaths.any((path) => options.path.contains(path)) ||
           options.extra['skipCache'] == true;
  }

  /// Determines if stale data should be returned on error
  bool _shouldReturnStaleOnError(DioException err) {
    // Return stale data on network errors but not on auth errors
    return err.type == DioExceptionType.connectionError ||
           err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           (err.response?.statusCode ?? 0) >= 500;
  }
}

/// Cache invalidation helper
class CacheInvalidationHelper {
  final CacheManager _cacheManager = CacheManager();

  /// Invalidate cache entries based on action
  Future<void> invalidateOnAction(CacheAction action, {String? resourceId}) async {
    switch (action.type) {
      case CacheActionType.post:
        await _invalidateOnPost(resourceId);
        break;
      case CacheActionType.like:
        await _invalidateOnLike(resourceId);
        break;
      case CacheActionType.follow:
        await _invalidateOnFollow(resourceId);
        break;
      case CacheActionType.comment:
        await _invalidateOnComment(resourceId);
        break;
      case CacheActionType.message:
        await _invalidateOnMessage(resourceId);
        break;
      case CacheActionType.profileUpdate:
        await _invalidateOnProfileUpdate(resourceId);
        break;
      case CacheActionType.storyCreate:
        await _invalidateOnStoryCreate(resourceId);
        break;
      case CacheActionType.highlightUpdate:
        await _invalidateOnHighlightUpdate(resourceId);
        break;
    }
  }

  Future<void> _invalidateOnPost(String? postId) async {
    // Invalidate feed cache
    await _cacheManager.invalidatePattern('/feed');
    await _cacheManager.invalidatePattern('/posts');
    
    // Invalidate user profile if post belongs to current user
    if (postId != null) {
      await _cacheManager.invalidatePattern('/profile');
    }
    
    debugPrint('🗑️ [CacheInvalidation] Invalidated caches for new post: $postId');
  }

  Future<void> _invalidateOnLike(String? postId) async {
    // Invalidate feed and post details
    await _cacheManager.invalidatePattern('/feed');
    await _cacheManager.invalidatePattern('/posts/$postId');
    
    debugPrint('🗑️ [CacheInvalidation] Invalidated caches for like: $postId');
  }

  Future<void> _invalidateOnFollow(String? userId) async {
    // Invalidate profile caches
    await _cacheManager.invalidatePattern('/profile');
    await _cacheManager.invalidatePattern('/user/$userId');
    await _cacheManager.invalidatePattern('/feed');
    
    debugPrint('🗑️ [CacheInvalidation] Invalidated caches for follow: $userId');
  }

  Future<void> _invalidateOnComment(String? postId) async {
    // Invalidate post details and feed
    await _cacheManager.invalidatePattern('/posts/$postId');
    await _cacheManager.invalidatePattern('/feed');
    
    debugPrint('🗑️ [CacheInvalidation] Invalidated caches for comment: $postId');
  }

  Future<void> _invalidateOnMessage(String? conversationId) async {
    // Invalidate conversation caches
    await _cacheManager.invalidatePattern('/conversations');
    if (conversationId != null) {
      await _cacheManager.invalidatePattern('/conversations/$conversationId');
    }
    
    debugPrint('🗑️ [CacheInvalidation] Invalidated caches for message: $conversationId');
  }

  Future<void> _invalidateOnProfileUpdate(String? userId) async {
    // Invalidate all profile-related caches
    await _cacheManager.invalidatePattern('/profile');
    await _cacheManager.invalidatePattern('/user/$userId');
    
    debugPrint('🗑️ [CacheInvalidation] Invalidated caches for profile update: $userId');
  }

  Future<void> _invalidateOnStoryCreate(String? userId) async {
    // Invalidate story caches
    await _cacheManager.invalidatePattern('/stories');
    await _cacheManager.invalidatePattern('/profile');
    
    debugPrint('🗑️ [CacheInvalidation] Invalidated caches for story create: $userId');
  }

  Future<void> _invalidateOnHighlightUpdate(String? highlightId) async {
    // Invalidate highlight caches
    await _cacheManager.invalidatePattern('/highlights');
    if (highlightId != null) {
      await _cacheManager.invalidatePattern('/highlights/$highlightId');
    }
    
    debugPrint('🗑️ [CacheInvalidation] Invalidated caches for highlight update: $highlightId');
  }
}

/// Cache action types for invalidation
enum CacheActionType {
  post,
  like,
  follow,
  comment,
  message,
  profileUpdate,
  storyCreate,
  highlightUpdate,
}

/// Cache action for invalidation
class CacheAction {
  final CacheActionType type;
  final String? resourceId;

  CacheAction({
    required this.type,
    this.resourceId,
  });
}
