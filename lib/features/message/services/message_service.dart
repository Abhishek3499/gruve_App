import 'package:dio/dio.dart';
import '../../../core/network/app_dio.dart';
import '../../../core/parsing/safe_parsing_helpers.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Service responsible for handling all message-related API calls
class MessageService {
  static const String _conversationsEndpoint = '/conversations/';

  late final Dio _dio;

  MessageService() {
    _dio = AppDio.getInstance();
    AppLogger.d('🏗️ [MessageService] Service initialized with Dio client');
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
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.d(
        '📡 [MessageService] 🚀 Fetching conversations from $_conversationsEndpoint',
      );

      final response = await _dio.get<dynamic>(
        _conversationsEndpoint,
        queryParameters: page > 1
            ? {'page': page, 'page_size': pageSize}
            : null,
        cancelToken: cancelToken,
        options: Options(
          headers: forceRefresh
              ? {
                  'Cache-Control': 'no-cache, no-store, must-revalidate',
                  'Pragma': 'no-cache',
                  'Expires': '0',
                }
              : null,
          extra: {
            'skipCache': true,
            'bypassCache': true,
            'noCache': true,
          },
        ),
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
            AppLogger.d(
              '🔄 [MessageService] 📝 Processing conversation at index $i',
            );
            final conversationJson = SafeParsingHelpers.safeMapParse(
              responseData[i],
              context: '💬 getConversationList[$i]',
            );
            if (conversationJson.isNotEmpty) {
              final conversation = ConversationModel.fromJson(conversationJson);
              conversations.add(conversation);
              AppLogger.d(
                '✅ [MessageService] ✨ Successfully parsed conversation ${conversation.id}',
              );
            } else {
              AppLogger.d(
                '⚠️ [MessageService] 🚫 Skipping empty conversation data at index $i',
              );
            }
          } catch (e) {
            AppLogger.d(
              '💥 [MessageService] ❌ Failed to parse conversation at index $i: $e',
            );
            AppLogger.d(
              '📄 [MessageService] 📋 Problematic data: ${responseData[i]}',
            );
            // Continue processing other conversations instead of failing completely
          }
        }

        AppLogger.d(
          '🎉 [MessageService] 🏆 Successfully parsed ${conversations.length}/${responseData.length} conversations',
        );
        return conversations;
      } else {
        throw Exception(
          'Failed to fetch conversations: Status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] getConversationList cancelled');
        return [];
      }
      AppLogger.d('💥 [MessageService] DioException: ${e.message}');
      AppLogger.d(
        '[MessageService] Response status: ${e.response?.statusCode}',
      );

      // Handle different types of Dio exceptions
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          AppLogger.d('⏰ [MessageService] Connection timeout error');
          throw Exception(
            'Connection timeout. Please check your internet connection.',
          );
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final message = e.response?.data?['message'] ?? 'Unknown error';
          AppLogger.d(
            '🚫 [MessageService] Bad response: $statusCode - $message',
          );
          throw Exception('API Error ($statusCode): $message');
        case DioExceptionType.cancel:
          AppLogger.d('❌ [MessageService] Request was cancelled');
          throw Exception('Request was cancelled');
        case DioExceptionType.connectionError:
          AppLogger.d('📶 [MessageService] No internet connection');
          throw Exception('No internet connection');
        case DioExceptionType.unknown:
        default:
          AppLogger.d('❓ [MessageService] Unknown network error: ${e.message}');
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.d('💥 [MessageService] Unexpected error: $e');
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
    CancelToken? cancelToken,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    final endpoint = '/conversations/$conversationId/messages/';

    try {
      AppLogger.d('[MessageService] 📡 GET $endpoint 📄 page=$page');

      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: page > 1 ? {'page': page} : null,
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(seconds: 45)),
      );

      AppLogger.d(
        '[MessageService] 📊 Messages response status=${response.statusCode}',
      );

      // Log detailed response information for debugging
      SafeParsingHelpers.logResponseInfo(
        response.data,
        '💬 Messages API Response',
      );

      final rawMessages = _extractMessageList(response.data);
      AppLogger.d(
        '[MessageService] 📋 Extracted ${rawMessages.length} 📨 raw message items',
      );

      final messages = <MessageModel>[];
      for (int i = 0; i < rawMessages.length; i++) {
        try {
          AppLogger.d('🔄 [MessageService] 📝 Processing message at index $i');
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
            AppLogger.d(
              '✅ [MessageService] ✨ Successfully parsed message ${message.id}',
            );
          } else {
            AppLogger.d(
              '⚠️ [MessageService] 🚫 Skipping empty message data at index $i',
            );
          }
        } catch (e) {
          AppLogger.d(
            '💥 [MessageService] ❌ Failed to parse message at index $i: $e',
          );
          AppLogger.d(
            '📄 [MessageService] 📋 Problematic data: ${rawMessages[i]}',
          );
          // Continue processing other messages instead of failing completely
        }
      }

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      AppLogger.d(
        '[MessageService] 🎉 🏆 Parsed ${messages.length}/${rawMessages.length} 📨 messages for $conversationId',
      );
      return messages;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] getMessages cancelled');
        return [];
      }
      AppLogger.d('[MessageService] Messages DioException: ${e.message}');
      AppLogger.d(
        '[MessageService] Messages error response: ${e.response?.data}',
      );
      throw Exception(_mapDioException(e));
    } catch (e) {
      AppLogger.d('[MessageService] Messages unexpected error: $e');
      throw Exception('Failed to fetch messages: $e');
    }
  }

  List<dynamic> _extractMessageList(dynamic data) {
    AppLogger.d('🔍 [MessageService] 🚀 Starting message list extraction');

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

    AppLogger.d('⚠️ [_extractMessageList] 🚫 No list found');

    return [];
  }

  List<dynamic> _extractConversationList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final map = SafeParsingHelpers.safeMapParse(
        data,
        context: '_extractConversationList',
      );
      if (map['results'] is List) {
        return map['results'];
      }
      if (map['conversations'] is List) {
        return map['conversations'];
      }
      if (map['data'] is List) {
        return map['data'];
      }
      if (map['data'] is Map) {
        final nestedData = SafeParsingHelpers.safeMapParse(
          map['data'],
          context: '_extractConversationList.data',
        );
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
    CancelToken? cancelToken,
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
      AppLogger.d('[MessageService] 📤 POST $endpoint');
      AppLogger.d(
        '[MessageService] 📦 Request body: {"content": "${trimmedContent.substring(0, trimmedContent.length.clamp(0, 50))}${trimmedContent.length > 50 ? "..." : ""}"}',
      );
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {'content': trimmedContent},
        cancelToken: cancelToken,
      );

      AppLogger.d(
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
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] sendMessage cancelled');
        return null;
      }
      AppLogger.d('[MessageService] Send message DioException: ${e.message}');
      AppLogger.d(
        '[MessageService] Send message error response: ${e.response?.data}',
      );
      throw Exception(_mapDioException(e));
    } catch (e) {
      AppLogger.d('[MessageService] Send message unexpected error: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Fetches a single conversation by ID
  ///
  /// [conversationId] - The ID of the conversation to fetch
  /// Returns [ConversationModel] on success
  /// Throws [DioException] on API errors
  /// Throws [Exception] on other errors
  Future<ConversationModel> getConversationById(String conversationId, {CancelToken? cancelToken}) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    try {
      AppLogger.d(
        '🔍 [MessageService] 🚀 Fetching conversation by ID: $conversationId',
      );

      final response = await _dio.get<Map<String, dynamic>>(
        '$_conversationsEndpoint/$conversationId',
        cancelToken: cancelToken,
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
          AppLogger.d(
            '✅ [MessageService] 🎉 Successfully fetched conversation: ${conversation.id}',
          );
          return conversation;
        } else {
          AppLogger.d(
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
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] getConversationById cancelled');
        rethrow;
      }
      AppLogger.d(
        '💥 [MessageService] DioException fetching conversation: ${e.message}',
      );

      switch (e.type) {
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 404) {
            AppLogger.d('🚫 [MessageService] Conversation not found (404)');
            throw Exception('Conversation not found');
          }
          final message = e.response?.data?['message'] ?? 'Unknown error';
          AppLogger.d('🚫 [MessageService] API Error: $message');
          throw Exception('API Error: $message');
        default:
          AppLogger.d('📶 [MessageService] Network error: ${e.message}');
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.d(
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
      AppLogger.d(
        '👁️ [MessageService] Marking conversation as read locally: $conversationId',
      );

      // Implement backend API call when endpoint is available
      // For now, just return true to simulate successful mark as read
      AppLogger.d(
        '✅ [MessageService] Conversation marked as read locally (backend API not implemented)',
      );
      return true;
    } catch (e) {
      AppLogger.d('💥 [MessageService] Error marking conversation as read: $e');
      return false;
    }
  }

  /// Creates or gets an existing conversation with a user
  ///
  /// [receiverId] - The ID of the user to create/retrieve conversation with
  /// Returns [ConversationModel] on success
  /// Throws [DioException] on API errors
  /// Throws [Exception] on other errors
  Future<ConversationModel> createOrGetConversation(String receiverId, {CancelToken? cancelToken}) async {
    if (receiverId.isEmpty) {
      throw ArgumentError('Receiver ID cannot be empty');
    }

    try {
      AppLogger.d(
        '🚀 [MessageService] Creating/getting conversation with receiver: $receiverId',
      );

      final response = await _dio.post<Map<String, dynamic>>(
        '/conversations/',
        data: {'receiver_id': receiverId},
        cancelToken: cancelToken,
      );

      AppLogger.d(
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
          AppLogger.d(
            '✅ [MessageService] 🎉 Successfully created/retrieved conversation: ${conversation.id}',
          );
          AppLogger.d(
            '💬 [MessageService] 👤 Participants: ${conversation.participant1Id} & ${conversation.participant2Id}',
          );
          return conversation;
        } else {
          AppLogger.d(
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
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] createOrGetConversation cancelled');
        rethrow;
      }
      AppLogger.d(
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
          AppLogger.d('🚫 [MessageService] API Error: $statusCode - $message');
          throw Exception('API Error ($statusCode): $message');
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          AppLogger.d('⏰ [MessageService] Connection timeout error');
          throw Exception(
            'Connection timeout. Please check your internet connection.',
          );
        case DioExceptionType.cancel:
          AppLogger.d('❌ [MessageService] Request was cancelled');
          throw Exception('Request was cancelled');
        case DioExceptionType.connectionError:
          AppLogger.d('📶 [MessageService] No internet connection');
          throw Exception('No internet connection');
        case DioExceptionType.unknown:
        default:
          AppLogger.d('❓ [MessageService] Unknown network error: ${e.message}');
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.d(
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
      AppLogger.d(
        '🗑️ [MessageService] Deleting conversation locally: $conversationId',
      );

      // Implement backend API call when endpoint is available
      // For now, just return true to simulate successful deletion
      AppLogger.d(
        '✅ [MessageService] Conversation deleted locally (backend API not implemented)',
      );
      return true;
    } catch (e) {
      AppLogger.d('💥 [MessageService] Error deleting conversation: $e');
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
    CancelToken? cancelToken,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }
    if (messageId.isEmpty) {
      throw ArgumentError('Message ID cannot be empty');
    }

    final endpoint = '/conversations/$conversationId/messages/$messageId';

    try {
      AppLogger.d('🗑️ [MessageService] 🚀 DELETE $endpoint');
      AppLogger.d('💬 [MessageService] 🆔 Conversation: $conversationId');
      AppLogger.d('📨 [MessageService] 🆔 Message: $messageId');

      final response = await _dio.delete<dynamic>(endpoint, cancelToken: cancelToken);

      AppLogger.d(
        '📊 [MessageService] ✅ Delete response status: ${response.statusCode}',
      );

      // Accept both 200 and 204 as success
      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.d('✅ [MessageService] 🎉 Message deleted successfully');
        return true;
      } else {
        AppLogger.d(
          '⚠️ [MessageService] ❌ Unexpected status code: ${response.statusCode}',
        );
        throw Exception(
          'Failed to delete message: Status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] deleteMessage cancelled');
        return false;
      }
      AppLogger.d(
        '💥 [MessageService] ❌ DioException deleting message: ${e.message}',
      );
      AppLogger.d(
        '[MessageService] Response status: ${e.response?.statusCode}',
      );

      switch (e.type) {
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            AppLogger.d('🚫 [MessageService] ⚠️ Message not found (404)');
            throw Exception('Message not found');
          }
          if (statusCode == 403) {
            AppLogger.d(
              '🚫 [MessageService] 🔒 Forbidden - not your message (403)',
            );
            throw Exception('You can only delete your own messages');
          }
          final message = e.response?.data is Map<String, dynamic>
              ? e.response?.data['message'] ??
                    e.response?.data['detail'] ??
                    'Unknown error'
              : 'Unknown error';
          AppLogger.d('🚫 [MessageService] ❌ API Error: $statusCode - $message');
          throw Exception('API Error ($statusCode): $message');
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          AppLogger.d('⏰ [MessageService] ⏱️ Connection timeout error');
          throw Exception(
            'Connection timeout. Please check your internet connection.',
          );
        case DioExceptionType.cancel:
          AppLogger.d('❌ [MessageService] 🚫 Request was cancelled');
          throw Exception('Request was cancelled');
        case DioExceptionType.connectionError:
          AppLogger.d('📶 [MessageService] 📡 No internet connection');
          throw Exception('No internet connection');
        case DioExceptionType.unknown:
        default:
          AppLogger.d(
            '❓ [MessageService] ❌ Unknown network error: ${e.message}',
          );
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.d('💥 [MessageService] ❌ Unexpected error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }
}
