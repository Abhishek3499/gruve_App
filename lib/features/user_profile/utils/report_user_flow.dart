import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/user_profile/data/datasource/report_user_api_service.dart';
import 'package:gruve_app/features/video_options/presentation/widgets/sheets/simple_report_sheet.dart';

class ReportUserFlow {
  ReportUserFlow._();

  static final ReportUserApiService _api = ReportUserApiService();

  static Future<void> showAndSubmit({
    required BuildContext context,
    required String userId,
    ReportSheetTarget target = ReportSheetTarget.user,
  }) async {
    if (userId.trim().isEmpty) return;

    final reasonKey = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SimpleReportSheet(target: target),
    );

    if (reasonKey == null || reasonKey.trim().isEmpty || !context.mounted) {
      return;
    }

    try {
      final response = await _api.reportUser(
        userId: userId,
        reasonKey: reasonKey,
      );

      if (!context.mounted) return;

      final message = response.success
          ? (response.message.trim().isNotEmpty
              ? response.message
              : 'User reported successfully.')
          : (response.error?.trim().isNotEmpty == true
              ? response.error!.trim()
              : 'Failed to report user.');

      _showSnackBar(
        context,
        message: message,
        isError: !response.success,
      );
    } on DioException catch (e) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: ReportUserApiService.errorMessageFromDio(e),
        isError: true,
      );
    } catch (_) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: 'Failed to report user. Please try again.',
        isError: true,
      );
    }
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF8B25C6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
