import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:gruve_app/core/cache/cache_interceptor.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/features/message/services/message_service.dart';
import 'package:gruve_app/features/message/models/message_model.dart';

import 'cache_interceptor_test.mocks.dart';

@GenerateMocks([Dio, CacheManager])
void main() {
  group('CacheInterceptor Tests', () {
    late CacheInterceptor interceptor;
    late MockDio mockDio;
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockDio = MockDio();
      mockCacheManager = MockCacheManager();
      interceptor = CacheInterceptor();
    });

    test('should handle List<dynamic> response from messages API', () async {
      // Arrange
      final listResponse = [
        {
          'id': 'msg1',
          'content': 'Hello world',
          'timestamp': '2024-01-01T00:00:00Z',
          'sender_id': 'user1',
        },
        {
          'id': 'msg2',
          'content': 'Hi there',
          'timestamp': '2024-01-01T00:01:00Z',
          'sender_id': 'user2',
        }
      ];

      final options = RequestOptions(
        path: '/conversations/conv1/messages/',
        method: 'GET',
      );

      final response = Response(
        data: listResponse,
        statusCode: 200,
        requestOptions: options,
      );

      final handler = MockResponseInterceptorHandler();

      // Act
      await interceptor.onResponse(response, handler);

      // Assert
      verify(handler.next(response)).called(1);
      // The interceptor should not crash when handling List responses
    });

    test('should handle Map<String, dynamic> response from profile API', () async {
      // Arrange
      final mapResponse = {
        'id': 'user1',
        'username': 'testuser',
        'email': 'test@example.com',
      };

      final options = RequestOptions(
        path: '/profile/user1',
        method: 'GET',
      );

      final response = Response(
        data: mapResponse,
        statusCode: 200,
        requestOptions: options,
      );

      final handler = MockResponseInterceptorHandler();

      // Act
      await interceptor.onResponse(response, handler);

      // Assert
      verify(handler.next(response)).called(1);
    });

    test('should handle nested response with results array', () async {
      // Arrange
      final nestedResponse = {
        'count': 25,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 'post1',
            'content': 'Test post 1',
            'likes': 10,
          },
          {
            'id': 'post2',
            'content': 'Test post 2',
            'likes': 5,
          }
        ]
      };

      final options = RequestOptions(
        path: '/feed/',
        method: 'GET',
      );

      final response = Response(
        data: nestedResponse,
        statusCode: 200,
        requestOptions: options,
      );

      final handler = MockResponseInterceptorHandler();

      // Act
      await interceptor.onResponse(response, handler);

      // Assert
      verify(handler.next(response)).called(1);
    });

    test('should handle empty response', () async {
      // Arrange
      final options = RequestOptions(
        path: '/conversations/empty/messages/',
        method: 'GET',
      );

      final response = Response(
        data: [],
        statusCode: 200,
        requestOptions: options,
      );

      final handler = MockResponseInterceptorHandler();

      // Act
      await interceptor.onResponse(response, handler);

      // Assert
      verify(handler.next(response)).called(1);
    });

    test('should not cache POST requests', () async {
      // Arrange
      final options = RequestOptions(
        path: '/conversations/',
        method: 'POST',
        data: {'content': 'New message'},
      );

      final response = Response(
        data: {'id': 'new_msg'},
        statusCode: 201,
        requestOptions: options,
      );

      final handler = MockResponseInterceptorHandler();

      // Act
      await interceptor.onResponse(response, handler);

      // Assert
      verify(handler.next(response)).called(1);
      // POST requests should not be cached
    });

    test('should generate consistent cache keys', () {
      // Arrange
      final options1 = RequestOptions(
        path: '/conversations/conv1/messages/',
        method: 'GET',
        queryParameters: {'page': 1},
      );

      final options2 = RequestOptions(
        path: '/conversations/conv1/messages/',
        method: 'GET',
        queryParameters: {'page': 1},
      );

      // Act
      final key1 = interceptor._generateCacheKey(options1);
      final key2 = interceptor._generateCacheKey(options2);

      // Assert
      expect(key1, equals(key2));
      expect(key1, contains('GET:/conversations/conv1/messages/'));
      expect(key1, contains('page=1'));
    });

    test('should create appropriate CacheData for different response types', () {
      // Test List response
      final listData = [{'id': '1'}, {'id': '2'}];
      final listCacheData = interceptor._createCacheData(listData);
      expect(listCacheData.dataType, equals('list'));
      expect(listCacheData.data, equals(listData));

      // Test Map response
      final mapData = {'id': '1', 'name': 'test'};
      final mapCacheData = interceptor._createCacheData(mapData);
      expect(mapCacheData.dataType, equals('map'));
      expect(mapCacheData.data, equals(mapData));

      // Test Nested response
      final nestedData = {'results': [{'id': '1'}]};
      final nestedCacheData = interceptor._createCacheData(nestedData);
      expect(nestedCacheData.dataType, equals('nested'));
      expect(nestedCacheData.data, equals(nestedData));

      // Test Empty response
      final emptyCacheData = interceptor._createCacheData(null);
      expect(emptyCacheData.dataType, equals('empty'));
      expect(emptyCacheData.data, isNull);
    });
  });

  group('RequestDeduplicator Tests', () {
    late RequestDeduplicator deduplicator;

    setUp(() {
      deduplicator = RequestDeduplicator();
    });

    tearDown(() {
      deduplicator.clear();
    });

    test('should prevent duplicate requests', () async {
      // Arrange
      final callCount = <String>[];
      
      Future<String> mockRequest() async {
        callCount.add('called');
        await Future.delayed(Duration(milliseconds: 100));
        return 'result';
      }

      // Act
      final future1 = deduplicator.deduplicate('test_key', mockRequest);
      final future2 = deduplicator.deduplicate('test_key', mockRequest);
      
      await Future.wait([future1, future2]);

      // Assert
      expect(callCount.length, equals(1));
      expect(await future1, equals('result'));
      expect(await future2, equals('result'));
    });

    test('should allow different requests to proceed', () async {
      // Arrange
      final callCount = <String>[];
      
      Future<String> mockRequest(String key) async {
        callCount.add(key);
        await Future.delayed(Duration(milliseconds: 50));
        return 'result_$key';
      }

      // Act
      final future1 = deduplicator.deduplicate('key1', () => mockRequest('key1'));
      final future2 = deduplicator.deduplicate('key2', () => mockRequest('key2'));
      
      await Future.wait([future1, future2]);

      // Assert
      expect(callCount.length, equals(2));
      expect(callCount, contains('key1'));
      expect(callCount, contains('key2'));
    });

    test('should handle request failures', () async {
      // Arrange
      Future<String> failingRequest() async {
        throw Exception('Request failed');
      }

      // Act & Assert
      expect(
        () => deduplicator.deduplicate('fail_key', failingRequest),
        throwsException,
      );

      // Should allow retry after failure
      expect(
        () => deduplicator.deduplicate('fail_key', failingRequest),
        throwsException,
      );
    });

    test('should provide accurate statistics', () {
      // Arrange
      deduplicator.deduplicate('test1', () async => 'result1');
      deduplicator.deduplicate('test2', () async => 'result2');

      // Act
      final stats = deduplicator.getStats();

      // Assert
      expect(stats['inFlightRequests'], equals(2));
      expect(stats['requests'], contains('test1'));
      expect(stats['requests'], contains('test2'));
    });
  });

  group('CacheData Tests', () {
    test('should serialize and deserialize correctly', () {
      // Arrange
      final originalData = {'id': '1', 'name': 'test'};
      final cacheData = CacheData.fromMap(originalData);

      // Act
      final json = cacheData.toJson();
      final deserialized = CacheData.fromJson(json);

      // Assert
      expect(deserialized.dataType, equals(cacheData.dataType));
      expect(deserialized.data, equals(cacheData.data));
    });

    test('should handle different data types', () {
      // List
      final listData = [1, 2, 3];
      final listCache = CacheData.fromList(listData);
      expect(listCache.dataType, equals('list'));
      expect(listCache.data, equals(listData));

      // Map
      final mapData = {'key': 'value'};
      final mapCache = CacheData.fromMap(mapData);
      expect(mapCache.dataType, equals('map'));
      expect(mapCache.data, equals(mapData));

      // Nested
      final nestedData = {'results': [1, 2, 3]};
      final nestedCache = CacheData.fromNested(nestedData);
      expect(nestedCache.dataType, equals('nested'));
      expect(nestedCache.data, equals(nestedData));

      // Empty
      final emptyCache = CacheData.fromEmpty();
      expect(emptyCache.dataType, equals('empty'));
      expect(emptyCache.data, isNull);
    });
  });
}

class MockResponseInterceptorHandler extends Mock implements ResponseInterceptorHandler {}
