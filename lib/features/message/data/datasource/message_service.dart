import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/network/api_exception.dart';
import 'package:gruve_app/core/parsing/safe_parsing_helpers.dart';
import 'package:gruve_app/features/message/domain/entities/conversation_model.dart';
import 'package:gruve_app/features/message/domain/entities/message_media_model.dart';
import 'package:gruve_app/features/message/domain/entities/message_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Service responsible for handling all message-related API calls
class MessageService {
  static const String _conversationsEndpoint = ApiConstants.conversations;

  late final Dio _dio;

  MessageService() {
    _dio = AppDio.getInstance();
    AppLogger.d('🏗️ [MessageService] Service initialized with Dio client');
  }

  /// Fetches the list of conversations from the API
  ///
  /// Returns a list of [ConversationModel] on success
  /// Throws [ApiException] on errors
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
          extra: {'skipCache': true, 'bypassCache': true, 'noCache': true},
        ),
      );

      SafeParsingHelpers.logResponseInfo(
        response.data,
        '💬 Conversations API Response',
      );

      if (response.statusCode == 200) {
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
          }
        }

        AppLogger.d(
          '🎉 [MessageService] 🏆 Successfully parsed ${conversations.length}/${responseData.length} conversations',
        );
        return conversations;
      } else {
        throw ApiException(
          'Failed to fetch conversations',
          statusCode: response.statusCode,
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
      throw ApiException.fromDio(e, fallback: 'Failed to fetch conversations');
    } catch (e) {
      AppLogger.d('💥 [MessageService] Unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch conversations');
    }
  }

  /// Fetch messages for a conversation.
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

    final endpoint = ApiConstants.conversationMessages(conversationId);

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
      throw ApiException.fromDio(e, fallback: 'Failed to fetch messages');
    } catch (e) {
      AppLogger.d('[MessageService] Messages unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch messages');
    }
  }

  List<dynamic> _extractMessageList(dynamic data) {
    AppLogger.d('🔍 [MessageService] 🚀 Starting message list extraction');

    SafeParsingHelpers.logResponseInfo(data, '📋 _extractMessageList input');

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      if (data['results'] is List) {
        return data['results'];
      }

      if (data['messages'] is List) {
        return data['messages'];
      }

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

  dynamic _unwrapMessagePayload(dynamic responseData) {
    if (responseData is! Map) return responseData;

    final map = Map<String, dynamic>.from(responseData);
    final data = map['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap['message'] is Map) return dataMap['message'];
      if (dataMap.containsKey('id') ||
          dataMap.containsKey('message_id') ||
          dataMap.containsKey('content')) {
        return dataMap;
      }
    }
    if (map['message'] is Map) return map['message'];
    return map;
  }

  String? _sanitizeReplyToMessageId(String? replyToMessageId) {
    final id = replyToMessageId?.trim();
    if (id == null || id.isEmpty) return null;
    if (id.startsWith('local-') || id.startsWith('realtime_')) return null;
    return id;
  }

  DioMediaType? _getMediaType(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.mp4')) return DioMediaType('video', 'mp4');
    if (lower.endsWith('.mov')) return DioMediaType('video', 'quicktime');
    if (lower.endsWith('.webm')) return DioMediaType('video', 'webm');
    if (lower.endsWith('.m4v')) return DioMediaType('video', 'x-m4v');
    if (lower.endsWith('.3gp')) return DioMediaType('video', '3gpp');
    
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
    if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return DioMediaType('image', 'jpeg');
    
    if (lower.endsWith('.m4a')) return DioMediaType('audio', 'mp4');
    if (lower.endsWith('.aac')) return DioMediaType('audio', 'aac');
    if (lower.endsWith('.mp3')) return DioMediaType('audio', 'mpeg');
    if (lower.endsWith('.wav')) return DioMediaType('audio', 'wav');
    
    return DioMediaType('image', 'jpeg'); // Safe fallback
  }

  /// Upload image/video/audio before sending via POST .../messages/.
  Future<MessageMediaPayload> uploadMessageMedia({
    required String conversationId,
    required String filePath,
    CancelToken? cancelToken,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError('Media file not found: $filePath');
    }

    final endpoint = ApiConstants.conversationMessagesMedia(conversationId);
    final fileName = filePath.split('/').last.split('\\').last;

    try {
      AppLogger.d('[MessageService] 📤 POST multipart $endpoint');
      final mediaType = _getMediaType(filePath);
      final formData = FormData.fromMap({
        'media': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: mediaType,
        ),
      });

      final response = await _dio.post<dynamic>(
        endpoint,
        data: formData,
        cancelToken: cancelToken,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        final map = raw is Map<String, dynamic>
            ? raw
            : SafeParsingHelpers.safeMapParse(raw, context: 'uploadMessageMedia');
        return MessageMediaPayload.fromJson(map);
      }

      throw ApiException(
        'Failed to upload media',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] uploadMessageMedia cancelled');
        rethrow;
      }
      AppLogger.d('[MessageService] Upload media DioException: ${e.message}');
      throw ApiException.fromDio(e, fallback: 'Failed to upload media');
    }
  }

  /// Sends a message over the authenticated REST endpoint.
  Future<MessageModel?> sendMessage({
    required String conversationId,
    String? content,
    String? replyToMessageId,
    Map<String, dynamic>? media,
    String? currentUserId,
    String? receiverUserId,
    CancelToken? cancelToken,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    final trimmedContent = content?.trim() ?? '';
    if (trimmedContent.isEmpty && media == null) {
      throw ArgumentError('Message must have content or media');
    }

    final endpoint = ApiConstants.conversationMessages(conversationId);
    final body = <String, dynamic>{};
    if (media != null) {
      // API expects content key (possibly empty) when media is attached.
      body['content'] = trimmedContent;
    } else if (trimmedContent.isNotEmpty) {
      body['content'] = trimmedContent;
    }
    final sanitizedReplyId = _sanitizeReplyToMessageId(replyToMessageId);
    if (sanitizedReplyId != null) {
      body['reply_to_message_id'] = sanitizedReplyId;
    }
    if (media != null) body['media'] = media;

    try {
      AppLogger.d('[MessageService] 📤 POST $endpoint');
      final response = await _dio.post<dynamic>(
        endpoint,
        data: body,
        cancelToken: cancelToken,
      );

      AppLogger.d(
        '[MessageService] 📊 Send message response status=${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final messageData = _unwrapMessagePayload(response.data);
        final responseMap = SafeParsingHelpers.safeMapParse(
          messageData,
          context: '📤 sendMessage',
        );

        if (responseMap.isEmpty) {
          AppLogger.d(
            '[MessageService] Send accepted (${response.statusCode}) with empty body',
          );
          return null;
        }

        return MessageModel.fromJson(
          responseMap,
          currentUserId: currentUserId,
          receiverUserId: receiverUserId,
        );
      }

      throw ApiException(
        'Failed to send message',
        statusCode: response.statusCode,
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
      throw ApiException.fromDio(e, fallback: 'Failed to send message');
    } catch (e) {
      AppLogger.d('[MessageService] Send message unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to send message');
    }
  }

  /// Fetches a single conversation by ID
  Future<ConversationModel> getConversationById(
    String conversationId, {
    CancelToken? cancelToken,
  }) async {
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
          throw ApiException('Conversation data is empty');
        }
      } else {
        throw ApiException(
          'Failed to fetch conversation',
          statusCode: response.statusCode,
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

      if (e.response?.statusCode == 404) {
        throw ApiException('Conversation not found', statusCode: 404);
      }
      throw ApiException.fromDio(e, fallback: 'Failed to fetch conversation');
    } catch (e) {
      AppLogger.d(
        '💥 [MessageService] Unexpected error fetching conversation: $e',
      );
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch conversation');
    }
  }

  /// Marks messages as read for a specific conversation
  Future<bool> markConversationAsRead(
    String conversationId, {
    List<String>? messageIds,
    CancelToken? cancelToken,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    final endpoint = ApiConstants.conversationMessagesRead(conversationId);

    try {
      AppLogger.d('👁️ [MessageService] POST $endpoint');
      final data = messageIds != null ? {'message_ids': messageIds} : <String, dynamic>{};
      final response = await _dio.post<dynamic>(
        endpoint,
        data: data,
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.d(
          '✅ [MessageService] Conversation marked as read: $conversationId',
        );
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.d('💥 [MessageService] Error marking conversation as read: $e');
      return false;
    }
  }

  /// Creates or gets an existing conversation with a user
  Future<ConversationModel> createOrGetConversation(
    String receiverId, {
    CancelToken? cancelToken,
  }) async {
    if (receiverId.isEmpty) {
      throw ArgumentError('Receiver ID cannot be empty');
    }

    try {
      AppLogger.d(
        '🚀 [MessageService] Creating/getting conversation with receiver: $receiverId',
      );

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.conversations,
        data: {'receiver_id': receiverId},
        cancelToken: cancelToken,
      );

      AppLogger.d(
        '📊 [MessageService] Conversation creation response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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
          throw ApiException('Conversation data is empty');
        }
      } else {
        throw ApiException(
          'Failed to create/get conversation',
          statusCode: response.statusCode,
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
      throw ApiException.fromDio(
        e,
        fallback: 'Failed to create/get conversation',
      );
    } catch (e) {
      AppLogger.d(
        '💥 [MessageService] Unexpected error creating/getting conversation: $e',
      );
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create/get conversation');
    }
  }

  /// Deletes a conversation
  Future<bool> deleteConversation(
    String conversationId, {
    CancelToken? cancelToken,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }

    final endpoint = '$_conversationsEndpoint$conversationId';

    try {
      AppLogger.d('🗑️ [MessageService] 🚀 DELETE $endpoint');

      final response = await _dio.delete<dynamic>(
        endpoint,
        cancelToken: cancelToken,
      );

      AppLogger.d(
        '📊 [MessageService] ✅ Delete response status: ${response.statusCode}',
      );

      if (response.statusCode == 204) {
        AppLogger.d('✅ [MessageService] 🎉 Conversation deleted successfully');
        return true;
      } else {
        AppLogger.d(
          '⚠️ [MessageService] ❌ Unexpected status code: ${response.statusCode}',
        );
        throw ApiException(
          'Failed to delete conversation',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] deleteConversation cancelled');
        return false;
      }
      AppLogger.d('💥 [MessageService] ❌ DioException: ${e.message}');

      final statusCode = e.response?.statusCode;
      if (statusCode == 403) {
        throw ApiException(
          'You are not a participant of this conversation.',
          statusCode: 403,
        );
      }
      if (statusCode == 404) {
        throw ApiException('Conversation not found', statusCode: 404);
      }
      throw ApiException.fromDio(e, fallback: 'Failed to delete conversation');
    } catch (e) {
      AppLogger.d('💥 [MessageService] ❌ Unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete conversation');
    }
  }

  /// Deletes a specific message from a conversation
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

    final endpoint = ApiConstants.conversationMessage(
      conversationId,
      messageId,
    );

    try {
      AppLogger.d('🗑️ [MessageService] 🚀 DELETE $endpoint');
      AppLogger.d('💬 [MessageService] 🆔 Conversation: $conversationId');
      AppLogger.d('📨 [MessageService] 🆔 Message: $messageId');

      final response = await _dio.delete<dynamic>(
        endpoint,
        cancelToken: cancelToken,
      );

      AppLogger.d(
        '📊 [MessageService] ✅ Delete response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.d('✅ [MessageService] 🎉 Message deleted successfully');
        return true;
      } else {
        AppLogger.d(
          '⚠️ [MessageService] ❌ Unexpected status code: ${response.statusCode}',
        );
        throw ApiException(
          'Failed to delete message',
          statusCode: response.statusCode,
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

      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        throw ApiException('Message not found', statusCode: 404);
      }
      if (statusCode == 403) {
        throw ApiException(
          'You can only delete your own messages',
          statusCode: 403,
        );
      }
      throw ApiException.fromDio(e, fallback: 'Failed to delete message');
    } catch (e) {
      AppLogger.d(
        '💥 [MessageService] ❌ Unexpected error deleting message: $e',
      );
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete message');
    }
  }

  /// Edits a plain-text message. Only the sender can edit non-deleted messages.
  Future<MessageModel?> editMessage({
    required String conversationId,
    required String messageId,
    required String content,
    String? currentUserId,
    String? receiverUserId,
    CancelToken? cancelToken,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty');
    }
    if (messageId.isEmpty) {
      throw ArgumentError('Message ID cannot be empty');
    }

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw ArgumentError('Message content cannot be empty');
    }

    final endpoint = ApiConstants.conversationMessage(
      conversationId,
      messageId,
    );

    try {
      AppLogger.d('[MessageService] ✏️ PATCH $endpoint');

      final response = await _dio.patch<dynamic>(
        endpoint,
        data: {'content': trimmedContent},
        cancelToken: cancelToken,
      );

      AppLogger.d(
        '[MessageService] Edit message response status=${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final messageData =
            responseData is Map<String, dynamic> &&
                responseData['data'] is Map<String, dynamic>
            ? responseData['data']
            : responseData;
        final responseMap = SafeParsingHelpers.safeMapParse(
          messageData,
          context: '✏️ editMessage',
        );

        if (responseMap.isEmpty) return null;

        return MessageModel.fromJson(
          responseMap,
          currentUserId: currentUserId,
          receiverUserId: receiverUserId,
        );
      }

      throw ApiException(
        'Failed to edit message',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageService] editMessage cancelled');
        return null;
      }
      AppLogger.d('[MessageService] Edit message DioException: ${e.message}');
      AppLogger.d(
        '[MessageService] Edit message error response: ${e.response?.data}',
      );
      throw ApiException.fromDio(e, fallback: 'Failed to edit message');
    } catch (e) {
      AppLogger.d('[MessageService] Edit message unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to edit message');
    }
  }
}
