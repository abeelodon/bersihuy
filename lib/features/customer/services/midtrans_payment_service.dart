import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

class MidtransTransaction {
  final String token;
  final String redirectUrl;

  const MidtransTransaction({required this.token, required this.redirectUrl});
}

/// Result of calling create-midtrans-transaction.
/// Either returns a [transaction] (new or existing Snap URL),
/// or indicates that the payment was [alreadyPaid] at Midtrans,
/// or the transaction is [pendingWithoutUrl] (exists at Midtrans but no stored URL).
class MidtransCreateResult {
  final MidtransTransaction? transaction;
  final bool alreadyPaid;
  final bool pendingWithoutUrl;
  final String? message;

  const MidtransCreateResult({
    this.transaction,
    this.alreadyPaid = false,
    this.pendingWithoutUrl = false,
    this.message,
  });
}

class MidtransPaymentStatus {
  final String status;
  final String? midtransStatus;
  final String? paymentMethod;
  final String? orderStatus;
  final bool isPaid;

  const MidtransPaymentStatus({
    required this.status,
    this.midtransStatus,
    this.paymentMethod,
    this.orderStatus,
    required this.isPaid,
  });

  bool get isPending => status == 'pending';
}

class MidtransPaymentException implements Exception {
  final String message;
  final String? code;
  final bool isConfigurationError;

  const MidtransPaymentException(
    this.message, {
    this.code,
    this.isConfigurationError = false,
  });

  @override
  String toString() => message;
}

class MidtransPaymentService {
  const MidtransPaymentService();

  /// Creates a Midtrans Snap transaction, or returns existing/already-paid status.
  Future<MidtransCreateResult> createTransaction({
    required String orderId,
    required int grossAmount,
  }) async {
    const functionName = 'create-midtrans-transaction';
    final normalizedOrderId = orderId.trim();
    final currentUserId = SupabaseService.currentUser?.id;

    if (normalizedOrderId.isEmpty) {
      throw const MidtransPaymentException('Order ID belum tersedia.');
    }

    debugPrint('MIDTRANS FUNCTION: $functionName');
    debugPrint('MIDTRANS CREATE orderId=$normalizedOrderId');
    debugPrint('MIDTRANS CREATE grossAmount=$grossAmount');
    debugPrint('MIDTRANS CREATE currentUserId=$currentUserId');

    try {
      final response = await SupabaseService.client.functions.invoke(
        functionName,
        body: {'order_id': normalizedOrderId, 'gross_amount': grossAmount},
      );
      debugPrint(
        'MIDTRANS CREATE RAW RESPONSE status=${response.status} '
        'data=${response.data}',
      );
      final data = _readMap(response.data);

      // Check if the edge function returned "already paid" status
      final isPaid = data['is_paid'] == true;
      final status = data['status']?.toString().trim() ?? '';
      if (isPaid || status == 'paid') {
        debugPrint('MIDTRANS CREATE ALREADY PAID');
        return const MidtransCreateResult(alreadyPaid: true);
      }

      // Check if it returned "pending without URL" (transaction exists but no stored redirect)
      if (status == 'pending' && data['token'] == null) {
        debugPrint('MIDTRANS CREATE PENDING WITHOUT URL');
        return MidtransCreateResult(
          pendingWithoutUrl: true,
          message: data['message']?.toString(),
        );
      }

      final token = data['token']?.toString().trim() ?? '';
      final redirectUrl = data['redirect_url']?.toString().trim() ?? '';

      if (token.isEmpty || redirectUrl.isEmpty) {
        throw const MidtransPaymentException(
          'Midtrans Sandbox tidak mengembalikan tautan pembayaran.',
        );
      }

      return MidtransCreateResult(
        transaction: MidtransTransaction(
          token: token,
          redirectUrl: redirectUrl,
        ),
      );
    } on FunctionException catch (error) {
      debugPrint(
        'MIDTRANS CREATE FUNCTION ERROR status=${error.status} '
        'reason=${error.reasonPhrase}',
      );
      debugPrint('MIDTRANS CREATE FUNCTION ERROR BODY: ${error.details}');
      throw _functionError(error);
    } catch (error, stackTrace) {
      debugPrint('MIDTRANS CREATE CLIENT ERROR: $error');
      debugPrint('MIDTRANS CREATE CLIENT STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  Future<MidtransPaymentStatus> checkPayment({required String orderId}) async {
    const functionName = 'check-midtrans-payment';
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      throw const MidtransPaymentException('Order ID belum tersedia.');
    }

    debugPrint('MIDTRANS FUNCTION: $functionName');
    debugPrint('MIDTRANS CHECK orderId=$normalizedOrderId');
    debugPrint(
      'MIDTRANS CHECK currentUserId=${SupabaseService.currentUser?.id}',
    );

    try {
      final response = await SupabaseService.client.functions.invoke(
        functionName,
        body: {'order_id': normalizedOrderId},
      );
      debugPrint(
        'MIDTRANS CHECK RAW RESPONSE status=${response.status} '
        'data=${response.data}',
      );
      final data = _readMap(response.data);
      final status = data['status']?.toString().trim() ?? '';
      if (status.isEmpty) {
        throw const MidtransPaymentException(
          'Status pembayaran Midtrans tidak tersedia.',
        );
      }

      final isPaid = data['is_paid'] == true || status == 'paid';

      return MidtransPaymentStatus(
        status: status,
        midtransStatus: data['midtrans_status']?.toString(),
        paymentMethod: data['payment_method']?.toString(),
        orderStatus: data['order_status']?.toString(),
        isPaid: isPaid,
      );
    } on FunctionException catch (error) {
      debugPrint(
        'MIDTRANS CHECK FUNCTION ERROR status=${error.status} '
        'reason=${error.reasonPhrase}',
      );
      debugPrint('MIDTRANS CHECK FUNCTION ERROR BODY: ${error.details}');
      throw _functionError(error);
    } catch (error, stackTrace) {
      debugPrint('MIDTRANS CHECK CLIENT ERROR: $error');
      debugPrint('MIDTRANS CHECK CLIENT STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  Map<String, Object?> _readMap(Object? data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return {'error': data.trim()};
      }
    }
    return const {};
  }

  MidtransPaymentException _functionError(FunctionException error) {
    final details = _readMap(error.details);
    final code = details['code']?.toString();
    final message =
        details['error']?.toString().trim() ??
        details['message']?.toString().trim();
    final isMissingFunction =
        error.status == 404 && (code == null || code == 'not_found');
    final isConfigurationError =
        code == 'midtrans_not_configured' ||
        code == 'supabase_not_configured' ||
        isMissingFunction;

    final displayMessage = (message == null || message.isEmpty)
        ? (isConfigurationError
              ? 'Midtrans Sandbox belum dikonfigurasi. Gunakan pembayaran demo.'
              : 'Layanan Midtrans Sandbox tidak dapat dihubungi.')
        : message;

    return MidtransPaymentException(
      displayMessage,
      code: code,
      isConfigurationError: isConfigurationError,
    );
  }
}
