import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/app_dio.dart';
import '../models/conversation_model.dart';

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
  Future<List<ConversationModel>> getConversationList() async {
    try {
      debugPrint('📡 [MessageService] Fetching conversations from $_conversationsEndpoint');
      
      final response = await _dio.get<List<dynamic>>(_conversationsEndpoint);
      
      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data ?? [];
        
        final conversations = responseData
            .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        debugPrint('✅ [MessageService] Successfully fetched ${conversations.length} conversations');
        return conversations;
      } else {
        throw Exception('Failed to fetch conversations: Status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('💥 [MessageService] DioException: ${e.message}');
      debugPrint('📄 [MessageService] Response: ${e.response?.data}');

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
        '🔍 [MessageService] Fetching conversation by ID: $conversationId',
      );

      final response = await _dio.get<Map<String, dynamic>>(
        '$_conversationsEndpoint/$conversationId',
      );

      if (response.statusCode == 200) {
        final conversationData = response.data;
        if (conversationData != null) {
          final conversation = ConversationModel.fromJson(conversationData);
          debugPrint(
            '✅ [MessageService] Successfully fetched conversation: ${conversation.id}',
          );
          return conversation;
        } else {
          debugPrint('❌ [MessageService] Conversation data is null');
          throw Exception('Conversation data is null');
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

      // TODO: Implement backend API call when endpoint is available
      // For now, just return true to simulate successful mark as read
      debugPrint(
        '✅ [MessageService] Conversation marked as read locally (backend API not implemented)',
      );
      return true;
      
    } catch (e) {
      debugPrint(
        '💥 [MessageService] Error marking conversation as read: $e',
      );
      return false;
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
      debugPrint('🗑️ [MessageService] Deleting conversation locally: $conversationId');

      // TODO: Implement backend API call when endpoint is available
      // For now, just return true to simulate successful deletion
      debugPrint(
        '✅ [MessageService] Conversation deleted locally (backend API not implemented)',
      );
      return true;
      
    } catch (e) {
      debugPrint(
        '💥 [MessageService] Error deleting conversation: $e',
      );
      return false;
    }
  }
}
