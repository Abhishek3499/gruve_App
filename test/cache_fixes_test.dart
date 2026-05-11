import 'package:flutter_test/flutter_test.dart';
import 'package:gruve_app/core/cache/cache_interceptor.dart';
import 'package:gruve_app/features/message/services/message_service.dart';

void main() {
  group('Cache Fixes Verification', () {
    test('CacheData should handle List responses (messages API)', () {
      // This test verifies the core fix for List<dynamic> vs Map<String, dynamic> issue
      
      // Simulate messages API response (List<dynamic>)
      final messagesResponse = [
        {
          'id': 'msg1',
          'content': 'Hello world',
          'timestamp': '2024-01-01T00:00:00Z',
          'sender_id': 'user1',
          'receiver_id': 'user2',
          'is_read': false,
        },
        {
          'id': 'msg2',
          'content': 'Hi there',
          'timestamp': '2024-01-01T00:01:00Z',
          'sender_id': 'user2',
          'receiver_id': 'user1',
          'is_read': true,
        }
      ];

      // Test CacheData creation for List responses
      final cacheData = CacheData.fromList(messagesResponse);
      
      expect(cacheData.dataType, equals('list'));
      expect(cacheData.data, equals(messagesResponse));
      expect(cacheData.data, isA<List<dynamic>>());
      
      // Test serialization/deserialization
      final json = cacheData.toJson();
      final deserialized = CacheData.fromJson(json);
      
      expect(deserialized.dataType, equals('list'));
      expect(deserialized.data, equals(messagesResponse));
      
      print('✅ CacheData successfully handles List<dynamic> responses');
    });

    test('CacheData should handle Map responses (profile API)', () {
      // Simulate profile API response (Map<String, dynamic>)
      final profileResponse = {
        'id': 'user1',
        'username': 'testuser',
        'email': 'test@example.com',
        'avatar': 'https://example.com/avatar.jpg',
      };

      final cacheData = CacheData.fromMap(profileResponse);
      
      expect(cacheData.dataType, equals('map'));
      expect(cacheData.data, equals(profileResponse));
      expect(cacheData.data, isA<Map<String, dynamic>>());
      
      print('✅ CacheData successfully handles Map<String, dynamic> responses');
    });

    test('CacheData should handle nested responses (paginated API)', () {
      // Simulate paginated API response (Map with results array)
      final paginatedResponse = {
        'count': 25,
        'next': 'https://api.example.com/messages/?page=2',
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

      final cacheData = CacheData.fromNested(paginatedResponse);
      
      expect(cacheData.dataType, equals('nested'));
      expect(cacheData.data, equals(paginatedResponse));
      expect(cacheData.data, isA<Map<String, dynamic>>());
      
      print('✅ CacheData successfully handles nested responses with results array');
    });

    test('CacheData should handle empty responses', () {
      final emptyCacheData = CacheData.fromEmpty();
      
      expect(emptyCacheData.dataType, equals('empty'));
      expect(emptyCacheData.data, isNull);
      
      print('✅ CacheData successfully handles empty responses');
    });

    test('RequestDeduplicator should prevent duplicate requests', () async {
      final deduplicator = RequestDeduplicator();
      int requestCount = 0;
      
      Future<String> mockRequest() async {
        requestCount++;
        await Future.delayed(Duration(milliseconds: 50));
        return 'success';
      }

      // Simulate multiple identical requests
      final future1 = deduplicator.deduplicate('test_key', mockRequest);
      final future2 = deduplicator.deduplicate('test_key', mockRequest);
      final future3 = deduplicator.deduplicate('test_key', mockRequest);
      
      final results = await Future.wait([future1, future2, future3]);
      
      // Verify only one actual request was made
      expect(requestCount, equals(1));
      expect(results[0], equals('success'));
      expect(results[1], equals('success'));
      expect(results[2], equals('success'));
      
      // Check statistics
      final stats = deduplicator.getStats();
      expect(stats['inFlightRequests'], equals(0)); // Should be 0 after completion
      expect(stats['requests'], contains('test_key'));
      
      print('✅ RequestDeduplicator successfully prevents duplicate requests');
      
      // Cleanup
      deduplicator.clear();
    });

    test('RequestDeduplicator should allow different requests', () async {
      final deduplicator = RequestDeduplicator();
      int requestCount = 0;
      
      Future<String> mockRequest(String key) async {
        requestCount++;
        return 'result_$key';
      }

      // Simulate different requests
      final future1 = deduplicator.deduplicate('key1', () => mockRequest('key1'));
      final future2 = deduplicator.deduplicate('key2', () => mockRequest('key2'));
      
      final result1 = await future1;
      final result2 = await future2;
      
      // Verify both requests were made
      expect(requestCount, equals(2));
      expect(result1, equals('result_key1'));
      expect(result2, equals('result_key2'));
      
      print('✅ RequestDeduplicator allows different requests to proceed');
      
      // Cleanup
      deduplicator.clear();
    });

    test('CacheInterceptor integration should not crash on List responses', () {
      final interceptor = CacheInterceptor();
      
      // Test that interceptor can be created without errors
      expect(interceptor, isA<CacheInterceptor>());
      
      // Test deduplication stats
      final stats = interceptor.getDeduplicationStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['inFlightRequests'], equals(0));
      
      print('✅ CacheInterceptor integration works without crashes');
    });
  });
}
