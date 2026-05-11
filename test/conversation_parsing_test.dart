import 'package:flutter_test/flutter_test.dart';
import 'package:gruve_app/core/parsing/safe_parsing_helpers.dart';
import 'package:gruve_app/features/message/models/conversation_model.dart';
import 'package:gruve_app/features/message/models/message_model.dart';
import 'package:gruve_app/features/message/data/models/user_model.dart';
import 'package:gruve_app/api_calls/profile/model/profile_model.dart';

void main() {
  group('Conversation Parsing Tests', () {
    test('SafeParsingHelpers handles _Map<dynamic, dynamic> correctly', () {
      // Simulate the problematic _Map<dynamic, dynamic> from cache/API
      final dynamicMap = <dynamic, dynamic>{
        'id': '123',
        'other_user': <dynamic, dynamic>{
          'id': '456',
          'name': 'Test User',
          'avatar': 'https://example.com/avatar.jpg',
        },
        'last_message': <dynamic, dynamic>{
          'content': 'Hello world',
          'created_at': '2024-01-01T12:00:00Z',
        },
        'unread_count': 5,
      };

      // This should not throw an exception
      final safeMap = SafeParsingHelpers.safeMapParse(dynamicMap, context: 'Test');
      
      expect(safeMap, isA<Map<String, dynamic>>());
      expect(safeMap['id'], equals('123'));
      expect(safeMap['other_user'], isA<Map>());
      expect(safeMap['last_message'], isA<Map>());
      expect(safeMap['unread_count'], equals(5));
    });

    test('ConversationModel.fromJson handles dynamic maps safely', () {
      final dynamicConversation = <dynamic, dynamic>{
        'id': 'conv_123',
        'other_user': <dynamic, dynamic>{
          'id': 'user_456',
          'name': 'John Doe',
          'avatar': 'avatar_url',
        },
        'last_message': <dynamic, dynamic>{
          'content': 'Last message content',
          'created_at': '2024-01-01T10:30:00Z',
        },
        'updated_at': '2024-01-01T10:30:00Z',
        'unread_count': 2,
      };

      // Convert dynamic map to Map<String, dynamic> before passing to model
      final stringKeyedMap = Map<String, dynamic>.from(dynamicConversation);
      
      // This should not throw a type cast exception
      final conversation = ConversationModel.fromJson(stringKeyedMap);
      
      expect(conversation.id, equals('conv_123'));
      expect(conversation.otherUser.id, equals('user_456'));
      expect(conversation.otherUser.name, equals('John Doe'));
      expect(conversation.lastMessage.content, equals('Last message content'));
      expect(conversation.unreadCount, equals(2));
    });

    test('MessageModel.fromJson handles dynamic maps safely', () {
      final dynamicMessage = <dynamic, dynamic>{
        'id': 'msg_789',
        'content': 'Test message',
        'sender_id': 'user_456',
        'created_at': '2024-01-01T11:00:00Z',
        'is_read': true,
      };

      // Convert dynamic map to Map<String, dynamic> before passing to model
      final stringKeyedMap = Map<String, dynamic>.from(dynamicMessage);
      
      // This should not throw a type cast exception
      final message = MessageModel.fromJson(stringKeyedMap);
      
      expect(message.id, equals('msg_789'));
      expect(message.text, equals('Test message'));
      expect(message.senderId, equals('user_456'));
      expect(message.isRead, equals(true));
    });

    test('UserModel.fromJson handles dynamic maps safely', () {
      final dynamicUser = <dynamic, dynamic>{
        'user_id': 'user_123',
        'username': 'testuser',
        'full_name': 'Test User',
        'profile_picture': 'profile_url',
      };

      // Convert dynamic map to Map<String, dynamic> before passing to model
      final stringKeyedMap = Map<String, dynamic>.from(dynamicUser);
      
      // This should not throw a type cast exception
      final user = UserModel.fromJson(stringKeyedMap);
      
      expect(user.userId, equals('user_123'));
      expect(user.username, equals('testuser'));
      expect(user.fullName, equals('Test User'));
      expect(user.profilePicture, equals('profile_url'));
    });

    test('ProfileModel.fromJson handles dynamic maps safely', () {
      final dynamicProfile = <dynamic, dynamic>{
        'id': 'profile_123',
        'username': 'profile_user',
        'full_name': 'Profile User',
        'profile_picture': 'profile_image_url',
        'is_following': true,
        'has_active_story': false,
        'story_count': 3,
      };

      // Convert dynamic map to Map<String, dynamic> before passing to model
      final stringKeyedMap = Map<String, dynamic>.from(dynamicProfile);
      
      // This should not throw a type cast exception
      final profile = ProfileModel.fromJson(stringKeyedMap);
      
      expect(profile.id, equals('profile_123'));
      expect(profile.username, equals('profile_user'));
      expect(profile.fullName, equals('Profile User'));
      expect(profile.profileImage, equals('profile_image_url'));
      expect(profile.isFollowing, equals(true));
      expect(profile.hasActiveStory, equals(false));
      expect(profile.storyCount, equals(3));
    });

    test('SafeParsingHelpers handles null and empty values', () {
      // Test null handling
      final nullResult = SafeParsingHelpers.safeMapParse(null, context: 'NullTest');
      expect(nullResult, isEmpty);

      // Test empty list handling
      final emptyListResult = SafeParsingHelpers.safeListParse(null, context: 'EmptyListTest');
      expect(emptyListResult, isEmpty);

      // Test string extraction with fallbacks
      final testMap = {'name': 'John', 'age': 30};
      final name = SafeParsingHelpers.safeString(testMap, ['full_name', 'name'], fallback: 'Unknown');
      expect(name, equals('John'));

      final missing = SafeParsingHelpers.safeString(testMap, ['missing_field'], fallback: 'Default');
      expect(missing, equals('Default'));
    });

    test('SafeParsingHelpers logs response information correctly', () {
      // This test ensures the logging doesn't crash
      final testData = {
        'id': '123',
        'data': {'nested': 'value'},
        'items': ['item1', 'item2']
      };

      // Should not throw any exceptions
      SafeParsingHelpers.logResponseInfo(testData, 'TestContext');
      SafeParsingHelpers.logResponseInfo(null, 'NullTest');
      SafeParsingHelpers.logResponseInfo([], 'EmptyListTest');
    });

    test('Conversation parsing with missing fields uses defaults', () {
      final incompleteConversation = <dynamic, dynamic>{
        'id': 'conv_123',
        // Missing other_user and last_message
        'unread_count': 1,
      };

      // Convert dynamic map to Map<String, dynamic> before passing to model
      final stringKeyedMap = Map<String, dynamic>.from(incompleteConversation);
      
      final conversation = ConversationModel.fromJson(stringKeyedMap);
      
      expect(conversation.id, equals('conv_123'));
      expect(conversation.otherUser.name, equals('Unknown')); // Default fallback
      expect(conversation.lastMessage.content, equals('')); // Default fallback
      expect(conversation.unreadCount, equals(1));
    });

    test('Paginated response parsing handles dynamic maps safely', () {
      final dynamicPaginatedResponse = <dynamic, dynamic>{
        'data': <dynamic, dynamic>{
          'results': <dynamic>[
            <dynamic, dynamic>{
              'user_id': 'user_1',
              'username': 'user1',
              'full_name': 'User One',
            },
            <dynamic, dynamic>{
              'user_id': 'user_2',
              'username': 'user2',
              'full_name': 'User Two',
            },
          ],
          'page': 1,
          'has_next': true,
          'limit': 20,
        },
      };

      // Convert dynamic map to Map<String, dynamic> before passing to model
      final stringKeyedMap = Map<String, dynamic>.from(dynamicPaginatedResponse);
      
      final paginatedResponse = PaginatedUserResponse.fromJson(stringKeyedMap);
      
      expect(paginatedResponse.users.length, equals(2));
      expect(paginatedResponse.users[0].userId, equals('user_1'));
      expect(paginatedResponse.users[1].username, equals('user2'));
      expect(paginatedResponse.page, equals(1));
      expect(paginatedResponse.hasNext, equals(true));
      expect(paginatedResponse.limit, equals(20));
    });
  });
}
