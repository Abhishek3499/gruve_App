import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/app_dio.dart';
import '../../../core/parsing/safe_parsing_helpers.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Service responsible for handling all message-related API calls
class MessageService {
  static const String _conversationsEndpoint = '/conversations/';

  late final Dio _dio;

  MessageService() {
    _dio = AppDio.create();
    debugPrint('🏗️ [MessageService] Service initialized with Dio client');
  }

  /// Fetches the list of conversations from the API
  ///
  /// Returns a list of [ConversationModel] on success
  /// Throws [DioException] on API errors
  /// Throws [Exception] on other errors
  Future<List<ConversationModel>> getConversationList({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint(
        '📡 [MessageService] 🚀 Fetching conversations from $_conversationsEndpoint',
      );

      final response = await _dio.get<dynamic>(
        _conversationsEndpoint,
        queryParameters: page > 1
            ? {'page': page, 'page_size': pageSize}
            : null,
        options: forceRefresh
            ? Options(
                headers: {
                  'Cache-Control': 'no-cache, no-store, must-revalidate',
                  'Pragma': 'no-cache',
                  'Expires': '0',
                },
                extra: {
                  'skipCache': true,
                  'bypassCache': true,
                  'noCache': true,
                },
              )
            : null,
      );

      // Log detailed response information for debugging
      SafeParsingHelpers.logResponseInfo(
        response.data,
        '💬 Conversations API Response',
      );

      if (response.statusCode == 200) {
        // Safely parse response data
        final responseData = _extractConversationList(response.data);

        final conversations = <ConversationModel>[];
        for (int i = 0; i < responseData.length; i++) {
          try {
            debugPrint(
              '🔄 [MessageService] 📝 Processing conversation at index $i',
            );
            final conversationJson = SafeParsingHelpers.safeMapParse(
              responseData[i],
              context: '💬 getConversationList[$i]',
            );
            if (conversationJson.isNotEmpty) {
              final conversation = ConversationModel.fromJson(conversationJson);
              conversations.add(conversation);
              debugPrint(
                '✅ [MessageService] ✨ Successfully parsed conversation ${conversation.id}',
              );
            } else {
              debugPrint(
                '⚠️ [MessageService] 🚫 Skipping empty conversation data at index $i',
              );
            }
          } catch (e) {
            debugPrint(
              '💥 [MessageService] ❌ Failed to parse conversation at index $i: $e',
            );
            debugPrint(
              '📄 [MessageService] 📋 Problematic data: ${responseData[i]}',
            );
            // Continue processing other conversations instead of failing completely
          }
        }

        debugPrint(
          '🎉 [MessageService] 🏆 Successfully parsed ${conversations.length}/${responseData.length} conversations',
        );
        return conversations;
      } else {
        throw Exception(
          'Failed to fetch conversations: Status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('💥 [MessageService] DioException: ${e.message}');
      debugPrint(
        '[MessageService] Response status: ${e.response?.statusCode}',
      );

      // Handle different types of Dio exceptions
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          debugPrint('⏰ [MessageService] Connection timeout error');
          throw Exception(
            'Connection timeout. Please check your internet connection.',
          );
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final message = e.response?.data?['message'] ?? 'Unknown error';
          debugPrint(
            '🚫 [MessageService] Bad response: $statusCode - $message',
          );
          throw Exception('API Error ($statusCode): $message');
        case DioExceptionType.cancel:
          debugPrint('❌ [MessageService] Request was cancelled');
          throw Exception('Request was cancelled');
        case DioExceptionType.connectionError:
          debugPrint('📶 [MessageService] No internet connection');
          throw Exception('No internet connection');
        case DioExceptionType.unknown:
        default:
          debugPrint('❓ [MessageService] Unknown network error: ${e.message}');
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      debugPrint('💥 [MessageService] Unexpected error: $e');
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  /// Fetch messages for a conversation.
  ///
  /// The backend currently returns either a raw list or a paginated payload with
  /// a `results` array. Keeping the parser flexible makes the controller ready
  /// for server-side pagination without changing the UI contract later.
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    String? currentUserId,
    String? receiverUserId,
    int page = 1,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    final endpoint = '/conversations/$conversationId/messages/';

    try {
      debugPrint('[MessageService] 📡 GET $endpoint 📄 page=$page');

      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: page > 1 ? {'page': page} : null,
        options: Options(receiveTimeout: const Duration(seconds: 45)),
      );

      debugPrint(
        '[MessageService] 📊 Messages response status=${response.statusCode}',
      );

      // Log detailed response information for debugging
      SafeParsingHelpers.logResponseInfo(
        response.data,
        '💬 Messages API Response',
      );

      final rawMessages = _extractMessageList(response.data);
      debugPrint(
        '[MessageService] 📋 Extracted ${rawMessages.length} 📨 raw message items',
      );

      final messages = <MessageModel>[];
      for (int i = 0; i < rawMessages.length; i++) {
        try {
          debugPrint('🔄 [MessageService] 📝 Processing message at index $i');
          final messageJson = SafeParsingHelpers.safeMapParse(
            rawMessages[i],
            context: '💬 getMessages[$i]',
          );
          if (messageJson.isNotEmpty) {
            final message = MessageModel.fromJson(
              messageJson,
              currentUserId: currentUserId,
              receiverUserId: receiverUserId,
            );
            messages.add(message);
            debugPrint(
              '✅ [MessageService] ✨ Successfully parsed message ${message.id}',
            );
          } else {
            debugPrint(
              '⚠️ [MessageService] 🚫 Skipping empty message data at index $i',
            );
          }
        } catch (e) {
          debugPrint(
            '💥 [MessageService] ❌ Failed to parse message at index $i: $e',
          );
          debugPrint(
            '📄 [MessageService] 📋 Problematic data: ${rawMessages[i]}',
          );
          // Continue processing other messages instead of failing completely
        }
      }

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint(
        '[MessageService] 🎉 🏆 Parsed ${messages.length}/${rawMessages.length} 📨 messages for $conversationId',
      );
      return messages;
    } on DioException catch (e) {
      debugPrint('[MessageService] Messages DioException: ${e.message}');
      debugPrint(
        '[MessageService] Messages error response: ${e.response?.data}',
      );
      throw Exception(_mapDioException(e));
    } catch (e) {
      debugPrint('[MessageService] Messages unexpected error: $e');
      throw Exception('Failed to fetch messages: $e');
    }
  }

  List<dynamic> _extractMessageList(dynamic data) {
    debugPrint('🔍 [MessageService] 🚀 Starting message list extraction');

    SafeParsingHelpers.logResponseInfo(data, '📋 _extractMessageList input');

    // Direct list
    if (data is List) {
      return data;
    }

    // Map response
    if (data is Map<String, dynamic>) {
      // CASE 1: results
      if (data['results'] is List) {
        return data['results'];
      }

      // CASE 2: messages directly
      if (data['messages'] is List) {
        return data['messages'];
      }

      // CASE 3: nested data.messages
      if (data['data'] is Map<String, dynamic>) {
        final nestedData = data['data'] as Map<String, dynamic>;

        if (nestedData['messages'] is List) {
          return nestedData['messages'];
        }
      }
    }

    debugPrint('⚠️ [_extractMessageList] 🚫 No list found');

    return [];
  }

  List<dynamic> _extractConversationList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      if (data['results'] is List) {
        return data['results'];
      }
      if (data['conversations'] is List) {
        return data['conversations'];
      }
      if (data['data'] is List) {
        return data['data'];
      }
      if (data['data'] is Map<String, dynamic>) {
        final nestedData = data['data'] as Map<String, dynamic>;
        if (nestedData['results'] is List) {
          return nestedData['results'];
        }
        if (nestedData['conversations'] is List) {
          return nestedData['conversations'];
        }
      }
    }

    return SafeParsingHelpers.safeListParse(
      data,
      context: 'getConversationList',
    );
  }

  dynamic _unwrapResponseData(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return data['data'];
    }
    return data;
  }

  String _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        final message = responseData is Map<String, dynamic>
            ? responseData['detail'] ??
                  responseData['error'] ??
                  responseData['message'] ??
                  'Unknown error'
            : 'Unknown error';
        return 'API Error ($statusCode): $message';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.unknown:
      default:
        return 'Network error: ${e.message}';
    }
  }

  /// Sends a message over the authenticated REST endpoint.
  ///
  /// The chat UI primarily uses WebSocket for realtime delivery, but this
  /// endpoint gives us an authenticated fallback and surfaces 401/send errors
  /// instead of failing silently when the socket is unavailable.
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String content,
    String? currentUserId,
    String? receiverUserId,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw ArgumentError('Message content cannot be empty');
    }

    final endpoint = '/conversations/$conversationId/messages/';

    try {
      debugPrint('[MessageService] 📤 POST $endpoint');
      debugPrint(
        '[MessageService] 📦 Request body: {"content": "${trimmedContent.substring(0, trimmedContent.length.clamp(0, 50))}${trimmedContent.length > 50 ? "..." : ""}"}',
      );
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {'content': trimmedContent},
      );

      debugPrint(
        '[MessageService] 📊 Send message response status=${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final messageData =
            responseData is Map<String, dynamic> &&
                responseData['data'] is Map<String, dynamic>
            ? responseData['data']
            : responseData;
        final responseMap = SafeParsingHelpers.safeMapParse(
          messageData,
          context: '📤 sendMessage',
        );

        if (responseMap.isEmpty) {
          return null;
        }

        return MessageModel.fromJson(
          responseMap,
          currentUserId: currentUserId,
          receiverUserId: receiverUserId,
        );
      }

      throw Exception(
        'Failed to send message: Status code ${response.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint('[MessageService] Send message DioException: ${e.message}');
      debugPrint(
        '[MessageService] Send message error response: ${e.response?.data}',
      );
      throw Exception(_mapDioException(e));
    } catch (e) {
      debugPrint('[MessageService] Send message unexpected error: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Fetches a single conversation by ID
  ///
  /// [conversationId] - The ID of the conversation to fetch
  /// Returns [ConversationModel] on success
  /// Throws [DioException] on API errors
  /// Throws [Exception] on other errors
  Future<ConversationModel> getConversationById(String conversationId) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    try {
      debugPrint(
        '🔍 [MessageService] 🚀 Fetching conversation by ID: $conversationId',
      );

      final response = await _dio.get<Map<String, dynamic>>(
        '$_conversationsEndpoint/$conversationId',
      );

      if (response.statusCode == 200) {
        // Log detailed response information for debugging
        SafeParsingHelpers.logResponseInfo(
          response.data,
          '💬 Conversation by ID Response',
        );

        final conversationData = SafeParsingHelpers.safeMapParse(
          _unwrapResponseData(response.data),
          context: '🔍 getConversationById',
        );
        if (conversationData.isNotEmpty) {
          final conversation = ConversationModel.fromJson(conversationData);
          debugPrint(
            '✅ [MessageService] 🎉 Successfully fetched conversation: ${conversation.id}',
          );
          return conversation;
        } else {
          debugPrint(
            '❌ [MessageService] 🚫 Conversation data is empty after parsing',
          );
          throw Exception('Conversation data is empty');
        }
      } else {
        throw Exception(
          'Failed to fetch conversation: Status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '💥 [MessageService] DioException fetching conversation: ${e.message}',
      );

      switch (e.type) {
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 404) {
            debugPrint('🚫 [MessageService] Conversation not found (404)');
            throw Exception('Conversation not found');
          }
          final message = e.response?.data?['message'] ?? 'Unknown error';
          debugPrint('🚫 [MessageService] API Error: $message');
          throw Exception('API Error: $message');
        default:
          debugPrint('📶 [MessageService] Network error: ${e.message}');
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      debugPrint(
        '💥 [MessageService] Unexpected error fetching conversation: $e',
      );
      throw Exception('Failed to fetch conversation: $e');
    }
  }

  /// Marks messages as read for a specific conversation
  ///
  /// [conversationId] - The ID of the conversation
  /// Returns true if successful, false otherwise
  /// NOTE: This is a local-only operation since the backend endpoint doesn't exist yet
  Future<bool> markConversationAsRead(String conversationId) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    try {
      debugPrint(
        '👁️ [MessageService] Marking conversation as read locally: $conversationId',
      );

      // Implement backend API call when endpoint is available
      // For now, just return true to simulate successful mark as read
      debugPrint(
        '✅ [MessageService] Conversation marked as read locally (backend API not implemented)',
      );
      return true;
    } catch (e) {
      debugPrint('💥 [MessageService] Error marking conversation as read: $e');
      return false;
    }
  }

  /// Creates or gets an existing conversation with a user
  ///
  /// [receiverId] - The ID of the user to create/retrieve conversation with
  /// Returns [ConversationModel] on success
  /// Throws [DioException] on API errors
  /// Throws [Exception] on other errors
  Future<ConversationModel> createOrGetConversation(String receiverId) async {
    if (receiverId.isEmpty) {
      throw ArgumentError('Receiver ID cannot be empty');
    }

    try {
      debugPrint(
        '🚀 [MessageService] Creating/getting conversation with receiver: $receiverId',
      );

      final response = await _dio.post<Map<String, dynamic>>(
        '/conversations/',
        data: {'receiver_id': receiverId},
      );

      debugPrint(
        '📊 [MessageService] Conversation creation response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Log detailed response information for debugging
        SafeParsingHelpers.logResponseInfo(
          response.data,
          '💬 Create/Get Conversation Response',
        );

        final conversationData = SafeParsingHelpers.safeMapParse(
          _unwrapResponseData(response.data),
          context: '🚀 createOrGetConversation',
        );
        if (conversationData.isNotEmpty) {
          final conversation = ConversationModel.fromJson(conversationData);
          debugPrint(
            '✅ [MessageService] 🎉 Successfully created/retrieved conversation: ${conversation.id}',
          );
          debugPrint(
            '💬 [MessageService] 👤 Participants: ${conversation.participant1Id} & ${conversation.participant2Id}',
          );
          return conversation;
        } else {
          debugPrint(
            '❌ [MessageService] 🚫 Conversation data is empty after parsing',
          );
          throw Exception('Conversation data is empty');
        }
      } else {
        throw Exception(
          'Failed to create/get conversation: Status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '💥 [MessageService] DioException creating/getting conversation: ${e.message}',
      );

      switch (e.type) {
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final responseData = e.response?.data;
          final message = responseData is Map<String, dynamic>
              ? responseData['message'] ??
                    responseData['detail'] ??
                    responseData['error'] ??
                    'Unknown error'
              : 'Unknown error';
          debugPrint('🚫 [MessageService] API Error: $statusCode - $message');
          throw Exception('API Error ($statusCode): $message');
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          debugPrint('⏰ [MessageService] Connection timeout error');
          throw Exception(
            'Connection timeout. Please check your internet connection.',
          );
        case DioExceptionType.cancel:
          debugPrint('❌ [MessageService] Request was cancelled');
          throw Exception('Request was cancelled');
        case DioExceptionType.connectionError:
          debugPrint('📶 [MessageService] No internet connection');
          throw Exception('No internet connection');
        case DioExceptionType.unknown:
        default:
          debugPrint('❓ [MessageService] Unknown network error: ${e.message}');
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      debugPrint(
        '💥 [MessageService] Unexpected error creating/getting conversation: $e',
      );
      throw Exception('Failed to create/get conversation: $e');
    }
  }

  /// Deletes a conversation
  ///
  /// [conversationId] - The ID of the conversation to delete
  /// Returns true if successful, false otherwise
  /// NOTE: This is a local-only operation since the backend endpoint doesn't exist yet
  Future<bool> deleteConversation(String conversationId) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    try {
      debugPrint(
        '🗑️ [MessageService] Deleting conversation locally: $conversationId',
      );

      // Implement backend API call when endpoint is available
      // For now, just return true to simulate successful deletion
      debugPrint(
        '✅ [MessageService] Conversation deleted locally (backend API not implemented)',
      );
      return true;
    } catch (e) {
      debugPrint('💥 [MessageService] Error deleting conversation: $e');
      return false;
    }
  }

  /// Deletes a specific message from a conversation
  ///
  /// [conversationId] - The ID of the conversation
  /// [messageId] - The ID of the message to delete
  /// Returns true if successful, false otherwise
  Future<bool> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }
    if (messageId.isEmpty) {
      throw ArgumentError('Message ID cannot be empty');
    }

    final endpoint = '/conversations/$conversationId/messages/$messageId';

    try {
      debugPrint('🗑️ [MessageService] 🚀 DELETE $endpoint');
      debugPrint('💬 [MessageService] 🆔 Conversation: $conversationId');
      debugPrint('📨 [MessageService] 🆔 Message: $messageId');

      final response = await _dio.delete<dynamic>(endpoint);

      debugPrint(
        '📊 [MessageService] ✅ Delete response status: ${response.statusCode}',
      );

      // Accept both 200 and 204 as success
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ [MessageService] 🎉 Message deleted successfully');
        return true;
      } else {
        debugPrint(
          '⚠️ [MessageService] ❌ Unexpected status code: ${response.statusCode}',
        );
        throw Exception(
          'Failed to delete message: Status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '💥 [MessageService] ❌ DioException deleting message: ${e.message}',
      );
      debugPrint(
        '[MessageService] Response status: ${e.response?.statusCode}',
      );

      switch (e.type) {
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            debugPrint('🚫 [MessageService] ⚠️ Message not found (404)');
            throw Exception('Message not found');
          }
          if (statusCode == 403) {
            debugPrint(
              '🚫 [MessageService] 🔒 Forbidden - not your message (403)',
            );
            throw Exception('You can only delete your own messages');
          }
          final message = e.response?.data is Map<String, dynamic>
              ? e.response?.data['message'] ??
                    e.response?.data['detail'] ??
                    'Unknown error'
              : 'Unknown error';
          debugPrint('🚫 [MessageService] ❌ API Error: $statusCode - $message');
          throw Exception('API Error ($statusCode): $message');
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          debugPrint('⏰ [MessageService] ⏱️ Connection timeout error');
          throw Exception(
            'Connection timeout. Please check your internet connection.',
          );
        case DioExceptionType.cancel:
          debugPrint('❌ [MessageService] 🚫 Request was cancelled');
          throw Exception('Request was cancelled');
        case DioExceptionType.connectionError:
          debugPrint('📶 [MessageService] 📡 No internet connection');
          throw Exception('No internet connection');
        case DioExceptionType.unknown:
        default:
          debugPrint(
            '❓ [MessageService] ❌ Unknown network error: ${e.message}',
          );
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      debugPrint('💥 [MessageService] ❌ Unexpected error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }
}
