import 'package:flutter_test/flutter_test.dart';
import 'package:gruve_app/features/message/utils/shared_post_message_parser.dart';
import 'package:gruve_app/features/message/models/message_model.dart';

void main() {
  group('SharedPostMessageParser Tests', () {
    group('extractPostIdFromText', () {
      test('extracts legacy pst_ prefixed post IDs', () {
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'View post: pst_123456',
          ),
          equals('123456'),
        );
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'View post:   pst_abc_123',
          ),
          equals('abc_123'),
        );
      });

      test('extracts non-prefixed MongoDB ObjectIds', () {
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'View post: 60ad4f7b9b7c4c6d9d4f7b9b',
          ),
          equals('60ad4f7b9b7c4c6d9d4f7b9b'),
        );
      });

      test('extracts non-prefixed UUIDs', () {
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'View post: d3b07384-d113-4c6d-9d4f-7b9b7c4c6d9d',
          ),
          equals('d3b07384-d113-4c6d-9d4f-7b9b7c4c6d9d'),
        );
      });

      test('extracts tagged post IDs with legacy prefix', () {
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'Abhishek tagged you in a post pst_123',
          ),
          equals('123'),
        );
      });

      test('extracts tagged post IDs without prefix (space separated)', () {
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'Abhishek tagged you in a post 60ad4f7b9b7c',
          ),
          equals('60ad4f7b9b7c'),
        );
      });

      test('extracts tagged post IDs without prefix (colon separated)', () {
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'Abhishek tagged you in a post: 60ad4f7b9b7c',
          ),
          equals('60ad4f7b9b7c'),
        );
      });

      test('returns null for unrelated text', () {
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'Hello this is a normal message',
          ),
          isNull,
        );
        expect(SharedPostMessageParser.extractPostIdFromText(''), isNull);
      });

      test('returns null when tagged phrase has no post id in text', () {
        expect(
          SharedPostMessageParser.extractPostIdFromText(
            'Abhishek tagged you in a post.',
          ),
          isNull,
        );
      });
    });

    group('extractPostId from payload', () {
      test('reads post_id from root when text has no id', () {
        expect(
          SharedPostMessageParser.extractPostId(
            {
              'message_type': 'post_tag',
              'post_id': 'pst_60ad4f7b9b7c',
              'content': 'Abhishek tagged you in a post.',
            },
            'Abhishek tagged you in a post.',
          ),
          equals('60ad4f7b9b7c'),
        );
      });
    });

    group('extractPreviewUrl', () {
      test('reads media_url from tagged_post payload', () {
        expect(
          SharedPostMessageParser.extractPreviewUrl(
            {
              'tagged_post': {
                'id': '60ad4f7b9b7c',
                'media_url': 'https://example.com/post.jpg',
              },
            },
            postId: '60ad4f7b9b7c',
          ),
          equals('https://example.com/post.jpg'),
        );
      });
    });

    group('isTaggedPostMessage', () {
      test('detects tagged post message', () {
        expect(
          SharedPostMessageParser.isTaggedPostMessage(
            'Abhishek tagged you in a post pst_123',
          ),
          isTrue,
        );
        expect(
          SharedPostMessageParser.isTaggedPostMessage(
            'tagged you in a post 60ad4f7b9b7c',
          ),
          isTrue,
        );
      });

      test('returns false for normal shared post message', () {
        expect(
          SharedPostMessageParser.isTaggedPostMessage('View post: pst_123'),
          isFalse,
        );
      });
    });

    group('companionText', () {
      test('extracts companion text and removes post share prefix/ID', () {
        expect(
          SharedPostMessageParser.companionText(
            'Check this out! View post: 60ad4f7b9b7c',
            '60ad4f7b9b7c',
          ),
          equals('Check this out!'),
        );
      });

      test(
        'extracts companion text from tagged post message and keeps other words',
        () {
          expect(
            SharedPostMessageParser.companionText(
              'Awesome! Abhishek tagged you in a post 60ad4f7b9b7c',
              '60ad4f7b9b7c',
            ),
            equals('Awesome! Abhishek'),
          );
        },
      );

      test('returns null when there is no companion text', () {
        expect(
          SharedPostMessageParser.companionText(
            'View post: 60ad4f7b9b7c',
            '60ad4f7b9b7c',
          ),
          isNull,
        );
        expect(
          SharedPostMessageParser.companionText(
            'Abhishek tagged you in a post: 60ad4f7b9b7c',
            '60ad4f7b9b7c',
          ),
          equals('Abhishek'),
        );
      });
    });

    group('MessageModel shared post parsing', () {
      test('correctly parses shared_post object with creator and media', () {
        final payload = {
          'id': 'msg_123',
          'content': 'View post: pst_999',
          'sender_id': 'user_111',
          'created_at': '2026-06-30T10:00:00Z',
          'shared_post': {
            'id': 'pst_999',
            'caption': 'Check out my new track!',
            'media_url': 'https://example.com/audio.mp3',
            'creator': {
              'id': 'user_222',
              'username': 'creator_user',
              'profile_picture': 'https://example.com/pic.jpg',
            },
          },
        };

        final message = MessageModel.fromJson(payload);
        expect(message.sharedPostId, equals('999'));
        expect(message.sharedPost, isNotNull);
        expect(message.sharedPost!.id, equals('999'));
        expect(message.sharedPost!.caption, equals('Check out my new track!'));
        expect(
          message.sharedPost!.media,
          equals('https://example.com/audio.mp3'),
        );
        expect(message.sharedPost!.username, equals('creator_user'));
        expect(
          message.sharedPost!.profilePicture,
          equals('https://example.com/pic.jpg'),
        );
      });

      test('keeps tagged_post with media even when username is unknown', () {
        final payload = {
          'id': 'msg_tag_1',
          'content': 'Abhishek tagged you in a post.',
          'message_type': 'post_tag',
          'post_id': '60ad4f7b9b7c',
          'tagged_post': {
            'id': '60ad4f7b9b7c',
            'media_url': 'https://example.com/tagged.jpg',
            'thumbnail_url': 'https://example.com/tagged-thumb.jpg',
          },
        };

        final message = MessageModel.fromJson(payload);
        expect(message.sharedPostId, equals('60ad4f7b9b7c'));
        expect(message.sharedPost, isNotNull);
        expect(message.sharedPost!.media, equals('https://example.com/tagged.jpg'));
        expect(
          message.sharedPostPreviewUrl,
          equals('https://example.com/tagged-thumb.jpg'),
        );
      });
    });
  });
}
