import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../repositories/order_repository.dart';
import '../services/customer_order_service.dart';
import '../services/midtrans_payment_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _isCheckingPayment = false;
  bool _isLoadingExistingOrder = false;
  bool _didReadRoute = false;
  bool _didSubmitSuccessfully = false;
  bool _hasCheckedPayment = false;
  bool _showDemoFallback = false;
  bool _isPolling = false;
  BersihuyOrder? _pendingOrder;
  _PaymentSummary? _summary;
  String? _existingOrderId;
  String? _loadError;
  String? _redirectUrl;
  String? _paymentMessage;
  Timer? _pollingTimer;

  static const _orderService = CustomerOrderService();
  static const _midtransService = MidtransPaymentService();

  bool get _isBusy =>
      _isProcessing || _isCheckingPayment || _isLoadingExistingOrder;

  @override
  void dispose() {
    _stopPaymentPolling();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadRoute) return;
    _didReadRoute = true;

    final summary = _PaymentSummary.fromRouteArgs(
      ModalRoute.of(context)?.settings.arguments,
    );
    _summary = summary;
    _existingOrderId = summary.orderId?.trim();

    if (_existingOrderId?.isNotEmpty == true) {
      _isLoadingExistingOrder = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingOrder(_existingOrderId!, summary);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary =
        _summary ??
        _PaymentSummary.fromRouteArgs(
          ModalRoute.of(context)?.settings.arguments,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _PremiumFlowBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: _isLoadingExistingOrder
                  ? _buildExistingOrderLoading()
                  : _loadError != null &&
                        _pendingOrder == null &&
                        summary.total <= 0
                  ? _buildExistingOrderError()
                  : Stack(
                      children: [
                        ScrollConfiguration(
                          behavior: ScrollConfiguration.of(
                            context,
                          ).copyWith(scrollbars: false),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              22,
                              20,
                              22,
                              _redirectUrl != null || _showDemoFallback
                                  ? 260
                                  : 140,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildOrderSummaryCard(summary),
                                const SizedBox(height: 20),
                                _buildMidtransPaymentArea(),
                                if (_paymentMessage != null) ...[
                                  const SizedBox(height: 14),
                                  _buildPaymentMessage(),
                                ],
                                const SizedBox(height: 16),
                                Text(
                                  'Transaksi ini menggunakan lingkungan Midtrans Sandbox.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.outline,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildBottomActionArea(summary),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingOrderLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(height: 14),
          Text('Memuat pembayaran pesanan...'),
        ],
      ),
    );
  }

  Widget _buildExistingOrderError() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _existingOrderId == null
                ? null
                : () => _loadExistingOrder(_existingOrderId!, _summary!),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Pembayaran',
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(_PaymentSummary summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Ringkasan Pembayaran',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              _paymentStatusBadge(),
            ],
          ),
          const SizedBox(height: 18),
          _buildSummaryItem('Layanan', summary.serviceName, isTitleStyle: true),
          _softDivider(),
          _buildSummaryItem('Jadwal', summary.schedule),
          _softDivider(),
          _buildSummaryItem('Lokasi', summary.location),
          _softDivider(),
          _buildSummaryItem(
            'Harga Layanan',
            _formatRupiah(summary.servicePrice),
          ),
          _softDivider(),
          _buildSummaryItem('Biaya admin', _formatRupiah(summary.adminFee)),
          if (summary.selectedScentName != null) ...[
            _softDivider(),
            _buildSummaryItem(
              'Aroma ${summary.selectedScentName}',
              _formatRupiah(0),
            ),
          ],
          for (final addOn in summary.selectedAddOns) ...[
            _softDivider(),
            _buildSummaryItem(addOn.title, _formatRupiah(addOn.price)),
          ],
          _softDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                _formatRupiah(summary.total),
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE4B548).withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        'Menunggu Pembayaran',
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF9A6A00),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value, {
    bool isTitleStyle = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isTitleStyle ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMidtransPaymentArea() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Midtrans Sandbox',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pembayaran diproses melalui halaman Midtrans Snap di lingkungan sandbox.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAF9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _redirectUrl == null
                      ? 'Tekan Bayar Sekarang untuk membuka pilihan pembayaran Midtrans Sandbox.'
                      : 'Halaman Midtrans Sandbox sudah disiapkan. Selesaikan simulasi pembayaran, lalu kembali ke aplikasi.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sandbox only. Tidak ada transaksi produksi yang diproses.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMessage() {
    final isFallback = _showDemoFallback;
    final color = isFallback ? const Color(0xFF9A6A00) : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isFallback ? Icons.info_outline_rounded : Icons.open_in_new_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _paymentMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea(_PaymentSummary summary) {
    final buttonChild = _isProcessing
        ? const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Membuka Midtrans...',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          )
        : Text(
            _redirectUrl == null
                ? 'Bayar Sekarang'
                : 'Buka Ulang Midtrans Sandbox',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isBusy ? null : () => _startMidtransPayment(summary),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
            ),
            child: buttonChild,
          ),
          if (_redirectUrl != null) ...[
            const SizedBox(height: 9),
            OutlinedButton(
              onPressed: _isBusy ? null : () => _checkMidtransPayment(summary),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.55),
                ),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isCheckingPayment
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 9),
                        Text('Memeriksa Pembayaran...'),
                      ],
                    )
                  : Text(
                      _hasCheckedPayment
                          ? 'Cek Status Pembayaran'
                          : 'Saya Sudah Menyelesaikan Pembayaran',
                    ),
            ),
          ],
          if (_showDemoFallback) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: _isBusy ? null : () => _completeDemoPayment(summary),
              child: const Text('Gunakan Pembayaran Demo'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadExistingOrder(
    String orderId,
    _PaymentSummary fallbackSummary,
  ) async {
    if (mounted) {
      setState(() {
        _isLoadingExistingOrder = true;
        _loadError = null;
      });
    }

    try {
      final detail = await _orderService.preparePendingPaymentOrder(orderId);
      final paymentStatus = detail.payment?.status;
      final orderStatus = detail.order.status;

      if (paymentStatus == 'paid' ||
          {'paid', 'scheduled', 'in_progress'}.contains(orderStatus)) {
        if (!mounted) return;
        _didSubmitSuccessfully = true;
        _openInvoice(orderId);
        return;
      }

      final loadedSummary = _PaymentSummary.fromOrderDetail(detail);
      if (!mounted) return;
      setState(() {
        _pendingOrder = detail.order;
        _summary = loadedSummary;
        _loadError = null;
        _paymentMessage = switch (paymentStatus) {
          'expired' =>
            'Pembayaran sebelumnya kedaluwarsa. Kamu dapat membuat transaksi sandbox baru.',
          'cancelled' =>
            'Pembayaran sebelumnya dibatalkan. Kamu dapat mencoba kembali.',
          'failed' =>
            'Pembayaran sebelumnya gagal. Kamu dapat mencoba kembali.',
          _ => null,
        };
      });

      // Auto-check Midtrans status if payment is pending and has been submitted
      if (paymentStatus == 'pending') {
        await _autoCheckMidtransStatus(orderId, loadedSummary);
      }
    } catch (error, stackTrace) {
      debugPrint('PAYMENT EXISTING ORDER LOAD ERROR: $error');
      debugPrint('PAYMENT EXISTING ORDER LOAD STACKTRACE: $stackTrace');
      if (!mounted) return;

      final message = _readableError(error);
      final canCallWithKnownData =
          fallbackSummary.total > 0 &&
          orderId.trim().isNotEmpty &&
          !_isNonPayableOrderError(error);
      setState(() {
        _loadError = message;
        _paymentMessage = canCallWithKnownData ? message : null;
        _showDemoFallback = canCallWithKnownData;
        if (canCallWithKnownData) {
          _pendingOrder = fallbackSummary.toFallbackOrder(orderId);
        }
      });
    } finally {
      if (mounted && !_didSubmitSuccessfully) {
        setState(() => _isLoadingExistingOrder = false);
      }
    }
  }

  /// Auto-checks Midtrans payment status when resuming a pending order.
  /// If already paid at Midtrans, navigates to invoice immediately.
  /// Otherwise starts auto-polling for future status changes.
  Future<void> _autoCheckMidtransStatus(
    String orderId,
    _PaymentSummary summary,
  ) async {
    try {
      debugPrint('AUTO CHECK MIDTRANS STATUS orderId=$orderId');
      final status = await _midtransService.checkPayment(orderId: orderId);
      if (!mounted) return;

      if (status.isPaid) {
        debugPrint('AUTO CHECK MIDTRANS: already paid, navigating to invoice');
        _stopPaymentPolling();
        _didSubmitSuccessfully = true;
        _openInvoice(orderId, summary: summary, order: _pendingOrder);
        return;
      }

      if (status.isPending) {
        debugPrint('AUTO CHECK MIDTRANS: still pending, starting polling');
        setState(() {
          _paymentMessage =
              'Pembayaran masih menunggu konfirmasi Midtrans.';
          _showDemoFallback = true;
        });
        _startPaymentPolling(orderId);
        return;
      }

      // expired / cancelled / failed — show status message, no polling
      _stopPaymentPolling();
      final message = switch (status.status) {
        'expired' =>
          'Pembayaran sebelumnya kedaluwarsa. Kamu dapat membuat transaksi sandbox baru.',
        'cancelled' =>
          'Pembayaran sebelumnya dibatalkan. Kamu dapat mencoba kembali.',
        _ =>
          'Pembayaran sebelumnya gagal. Kamu dapat mencoba kembali.',
      };
      setState(() {
        _paymentMessage = message;
        _showDemoFallback = true;
        _redirectUrl = null;
      });
    } catch (error) {
      // Non-fatal: auto-check failure should not block the screen
      debugPrint('AUTO CHECK MIDTRANS ERROR: $error');
      // Still start polling on error — webhook may have updated DB
      _startPaymentPolling(orderId);
    }
  }

  // ── Auto-polling ──────────────────────────────────────────────────────────

  void _startPaymentPolling(String orderId) {
    if (_pollingTimer != null) return;
    debugPrint('PAYMENT POLLING STARTED orderId=$orderId (every 4s)');
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollPaymentStatus(orderId),
    );
  }

  void _stopPaymentPolling() {
    if (_pollingTimer == null) return;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('PAYMENT POLLING STOPPED');
  }

  Future<void> _pollPaymentStatus(String orderId) async {
    if (_isPolling || _didSubmitSuccessfully || !mounted) return;
    _isPolling = true;
    try {
      debugPrint('PAYMENT POLL orderId=$orderId');
      final status = await _midtransService.checkPayment(orderId: orderId);
      if (!mounted) return;

      debugPrint(
        'PAYMENT POLL RESULT status=${status.status} '
        'isPaid=${status.isPaid} orderStatus=${status.orderStatus}',
      );

      if (status.isPaid) {
        debugPrint('PAYMENT POLL: PAID detected — navigating to invoice');
        _stopPaymentPolling();
        _didSubmitSuccessfully = true;
        _openInvoice(
          orderId,
          summary: _summary,
          order: _pendingOrder,
        );
        return;
      }

      if (!status.isPending) {
        // expired / cancelled / failed — stop polling, show message
        debugPrint('PAYMENT POLL: terminal status ${status.status} — stopping');
        _stopPaymentPolling();
        final message = switch (status.status) {
          'expired' =>
            'Pembayaran kedaluwarsa. Kamu dapat membuat transaksi baru.',
          'cancelled' =>
            'Pembayaran dibatalkan. Kamu dapat mencoba kembali.',
          _ => 'Pembayaran gagal. Kamu dapat mencoba kembali.',
        };
        setState(() {
          _paymentMessage = message;
          _showDemoFallback = true;
          _redirectUrl = null;
        });
      }
    } catch (error) {
      debugPrint('PAYMENT POLL ERROR: $error');
      // Non-fatal — keep polling, next tick will retry
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _startMidtransPayment(_PaymentSummary summary) async {
    if (_isBusy || _didSubmitSuccessfully) return;
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _paymentMessage = null;
    });

    try {
      final order = await _ensurePendingOrder(summary);
      var redirectUrl = _redirectUrl;

      if (redirectUrl == null || redirectUrl.isEmpty) {
        final result = await _midtransService.createTransaction(
          orderId: order.id!,
          grossAmount: order.totalAmount,
        );

        // Handle already-paid response from idempotent create-transaction
        if (result.alreadyPaid) {
          if (!mounted) return;
          _didSubmitSuccessfully = true;
          _openInvoice(
            order.id!,
            summary: _summary,
            order: _pendingOrder,
          );
          return;
        }

        // Handle pending-without-URL (existing Midtrans transaction, no stored redirect)
        if (result.pendingWithoutUrl) {
          if (!mounted) return;
          setState(() {
            _paymentMessage =
                result.message ??
                'Transaksi Midtrans sudah ada. Silakan cek status pembayaran atau gunakan pembayaran demo.';
            _showDemoFallback = true;
          });
          return;
        }

        redirectUrl = result.transaction!.redirectUrl;
        if (!mounted) return;
        setState(() {
          _redirectUrl = redirectUrl;
          _showDemoFallback = false;
          _hasCheckedPayment = false;
        });
      }

      await _launchMidtrans(redirectUrl);
      if (!mounted) return;
      setState(() {
        _paymentMessage =
            'Selesaikan pembayaran di Midtrans Sandbox, lalu kembali dan periksa status pembayaran.';
      });

      // Start auto-polling after launching Midtrans
      final pollOrderId = order.id;
      if (pollOrderId != null && pollOrderId.trim().isNotEmpty) {
        _startPaymentPolling(pollOrderId);
      }
    } on MidtransPaymentException catch (error, stackTrace) {
      debugPrint('MIDTRANS CREATE ERROR: $error');
      debugPrint('MIDTRANS CREATE STACKTRACE: $stackTrace');
      if (!mounted) return;
      if (error.code == 'already_paid') {
        final orderId = _pendingOrder?.id ?? _existingOrderId;
        if (orderId != null && orderId.trim().isNotEmpty) {
          _didSubmitSuccessfully = true;
          _openInvoice(orderId, summary: _summary, order: _pendingOrder);
          return;
        }
      }
      final message = error.message;
      final canUseDemoFallback = !{
        'already_paid',
        'order_not_payable',
        'forbidden',
      }.contains(error.code);
      setState(() {
        _showDemoFallback = canUseDemoFallback;
        _paymentMessage = message;
      });
      _showError(message);
    } catch (error, stackTrace) {
      debugPrint('MIDTRANS PAYMENT START ERROR: $error');
      debugPrint('MIDTRANS PAYMENT START STACKTRACE: $stackTrace');
      if (!mounted) return;
      const message =
          'Midtrans Sandbox tidak dapat dibuka. Gunakan pembayaran demo.';
      setState(() {
        _showDemoFallback = true;
        _paymentMessage = message;
      });
      _showError(message);
    } finally {
      if (!_didSubmitSuccessfully && mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<BersihuyOrder> _ensurePendingOrder(_PaymentSummary summary) async {
    final existingOrder = _pendingOrder;
    if (existingOrder?.id?.trim().isNotEmpty == true) {
      return existingOrder!;
    }

    final existingOrderId = _existingOrderId?.trim();
    if (existingOrderId != null && existingOrderId.isNotEmpty) {
      try {
        final detail = await _orderService.preparePendingPaymentOrder(
          existingOrderId,
        );
        if (detail.payment?.status == 'paid') {
          throw const MidtransPaymentException(
            'Pembayaran sudah selesai.',
            code: 'already_paid',
          );
        }
        final loadedSummary = _PaymentSummary.fromOrderDetail(detail);
        if (mounted) {
          setState(() {
            _pendingOrder = detail.order;
            _summary = loadedSummary;
            _loadError = null;
          });
        }
        return detail.order;
      } catch (error) {
        if (error is MidtransPaymentException ||
            _isNonPayableOrderError(error)) {
          rethrow;
        }
        if (summary.total <= 0) rethrow;
        debugPrint(
          'PAYMENT DIRECT FUNCTION FALLBACK orderId=$existingOrderId '
          'reason=$error',
        );
        final fallbackOrder = summary.toFallbackOrder(existingOrderId);
        if (mounted) {
          setState(() => _pendingOrder = fallbackOrder);
        }
        return fallbackOrder;
      }
    }

    final addOns = summary.selectedAddOns
        .map(
          (addOn) => AddOnItem(
            productId: addOn.productId,
            name: addOn.title,
            price: addOn.price,
            quantity: 1,
          ),
        )
        .toList();
    final order = await _orderService.createPendingCustomerOrder(
      serviceId: summary.serviceId,
      serviceName: summary.serviceName,
      servicePrice: summary.servicePrice,
      adminFee: summary.adminFee,
      selectedScent: summary.selectedScentName,
      selectedAddOns: addOns,
      scheduleDate: summary.scheduleDate,
      scheduleTime: summary.scheduleTime,
      serviceAddress: summary.location,
      customerNote: summary.customerNote,
    );

    if (order.id == null || order.id!.trim().isEmpty) {
      throw StateError('Order ID belum tersedia.');
    }
    if (!mounted) return order;
    setState(() => _pendingOrder = order);
    return order;
  }

  Future<void> _launchMidtrans(String redirectUrl) async {
    final uri = Uri.tryParse(redirectUrl);
    if (uri == null ||
        !{'https', 'http'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const MidtransPaymentException(
        'Tautan pembayaran Midtrans tidak valid.',
      );
    }

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('MIDTRANS EXTERNAL LAUNCH ERROR: $error');
    }
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
    if (!launched) {
      throw const MidtransPaymentException(
        'Halaman Midtrans Sandbox tidak dapat dibuka.',
      );
    }
  }

  Future<void> _checkMidtransPayment(_PaymentSummary summary) async {
    if (_isBusy || _didSubmitSuccessfully) return;
    final order = _pendingOrder;
    final orderId = order?.id?.trim();
    if (order == null || orderId == null || orderId.isEmpty) {
      _showError('Order ID belum tersedia.');
      return;
    }

    setState(() => _isCheckingPayment = true);
    try {
      final status = await _midtransService.checkPayment(orderId: orderId);
      if (!mounted) return;

      if (status.isPaid) {
        _didSubmitSuccessfully = true;
        _openInvoice(orderId, summary: summary, order: order);
        return;
      }

      if (status.isPending) {
        const message = 'Pembayaran masih menunggu konfirmasi Midtrans.';
        setState(() {
          _hasCheckedPayment = true;
          _paymentMessage = message;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(message)));
        return;
      }

      final message = switch (status.status) {
        'expired' => 'Pembayaran Midtrans sudah kedaluwarsa.',
        'cancelled' => 'Pembayaran Midtrans dibatalkan.',
        _ => 'Pembayaran Midtrans gagal diproses. Silakan coba lagi.',
      };
      setState(() {
        _hasCheckedPayment = true;
        _redirectUrl = null;
        _paymentMessage = message;
        _showDemoFallback = true;
      });
      _showError(message);
    } on MidtransPaymentException catch (error, stackTrace) {
      debugPrint('MIDTRANS STATUS ERROR: $error');
      debugPrint('MIDTRANS STATUS STACKTRACE: $stackTrace');
      if (!mounted) return;
      setState(() {
        _hasCheckedPayment = true;
        _paymentMessage = error.message;
        _showDemoFallback = !{
          'already_paid',
          'order_not_payable',
          'forbidden',
        }.contains(error.code);
      });
      _showError(error.message);
    } catch (error, stackTrace) {
      debugPrint('MIDTRANS STATUS UNKNOWN ERROR: $error');
      debugPrint('MIDTRANS STATUS UNKNOWN STACKTRACE: $stackTrace');
      if (!mounted) return;
      const message =
          'Status pembayaran gagal diperiksa. Gunakan pembayaran demo jika diperlukan.';
      setState(() {
        _paymentMessage = message;
        _showDemoFallback = true;
      });
      _showError(message);
    } finally {
      if (!_didSubmitSuccessfully && mounted) {
        setState(() => _isCheckingPayment = false);
      }
    }
  }

  Future<void> _completeDemoPayment(_PaymentSummary summary) async {
    if (_isBusy || _didSubmitSuccessfully) return;
    setState(() => _isProcessing = true);

    try {
      final pendingOrder = await _ensurePendingOrder(summary);
      final order = await _orderService.completeDemoPayment(pendingOrder.id!);
      if (!mounted) return;
      _didSubmitSuccessfully = true;
      _openInvoice(order.id!, summary: summary, order: order);
    } catch (error, stackTrace) {
      debugPrint('DEMO PAYMENT ERROR: $error');
      debugPrint('DEMO PAYMENT STACKTRACE: $stackTrace');
      if (!mounted) return;
      final reason = _readableError(error);
      _showError(
        reason == error.toString()
            ? 'Pembayaran demo gagal diproses. $reason'
            : reason,
      );
    } finally {
      if (!_didSubmitSuccessfully && mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openInvoice(
    String orderId, {
    _PaymentSummary? summary,
    BersihuyOrder? order,
  }) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.invoice,
      arguments: summary != null && order != null
          ? summary.toInvoiceArguments(order)
          : {'orderId': orderId},
    );
  }

  String _readableError(Object error) {
    final message = error.toString().trim();
    for (final prefix in [
      'Bad state: ',
      'Invalid argument(s): ',
      'Exception: ',
    ]) {
      if (message.startsWith(prefix)) {
        return message.substring(prefix.length);
      }
    }
    return message.isEmpty ? 'Data pesanan gagal dimuat.' : message;
  }

  bool _isNonPayableOrderError(Object error) {
    final message = _readableError(error).toLowerCase();
    return message.contains('tidak dapat dibayar') ||
        message.contains('akses pesanan tidak valid') ||
        message.contains('pembayaran sudah selesai');
  }

  Widget _softDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        color: AppColors.outlineVariant.withValues(alpha: 0.7),
      ),
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final positionFromEnd = digits.length - index;
      buffer.write(digits[index]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp$buffer';
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: const Color(0xFFFEFFFF),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.72),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF247D78).withValues(alpha: 0.055),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _PaymentSummary {
  final String? orderId;
  final String? serviceId;
  final String serviceName;
  final String serviceCategory;
  final int servicePrice;
  final String serviceDuration;
  final int adminFee;
  final String? selectedScentName;
  final List<_PaymentAddOn> selectedAddOns;
  final int total;
  final String schedule;
  final String location;
  final DateTime? scheduleDate;
  final String? scheduleTime;
  final String? customerNote;

  const _PaymentSummary({
    this.orderId,
    this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    required this.servicePrice,
    required this.serviceDuration,
    required this.adminFee,
    required this.selectedScentName,
    required this.selectedAddOns,
    required this.total,
    required this.schedule,
    required this.location,
    this.scheduleDate,
    this.scheduleTime,
    this.customerNote,
  });

  factory _PaymentSummary.fromOrderDetail(OrderDetail detail) {
    BersihuyOrderItem? serviceItem;
    final addOns = <_PaymentAddOn>[];

    for (final item in detail.orderItems) {
      if (item.itemType == 'service' && serviceItem == null) {
        serviceItem = item;
      } else if (item.itemType == 'addon' || item.itemType == 'product') {
        addOns.add(
          _PaymentAddOn(
            productId: item.productId,
            title: item.itemName,
            price: item.totalPrice,
          ),
        );
      }
    }

    final order = detail.order;
    final scheduleParts = <String>[
      if (order.scheduleDate != null) order.formattedScheduleDate,
      if (order.scheduleTime?.trim().isNotEmpty == true)
        order.scheduleTime!.trim(),
    ];

    return _PaymentSummary(
      orderId: order.id,
      serviceId: serviceItem?.serviceId,
      serviceName: serviceItem?.itemName ?? detail.serviceName,
      serviceCategory: '-',
      servicePrice:
          serviceItem?.totalPrice ??
          (order.subtotalAmount -
              addOns.fold<int>(0, (sum, item) => sum + item.price)),
      serviceDuration: '-',
      adminFee: order.adminFee,
      selectedScentName: order.selectedScent,
      selectedAddOns: addOns,
      total: order.totalAmount,
      schedule: scheduleParts.isEmpty ? '-' : scheduleParts.join(', '),
      location: order.serviceAddress,
      scheduleDate: order.scheduleDate,
      scheduleTime: order.scheduleTime,
      customerNote: order.customerNote,
    );
  }

  factory _PaymentSummary.fromRouteArgs(Object? args) {
    if (args is! Map) {
      return const _PaymentSummary(
        serviceName: 'Layanan Bersihuy',
        serviceCategory: '-',
        servicePrice: 0,
        serviceDuration: '-',
        adminFee: 0,
        selectedScentName: null,
        selectedAddOns: [],
        total: 0,
        schedule: '-',
        location: '-',
      );
    }

    String readString(String key, String fallback) {
      final value = args[key];
      return value is String && value.isNotEmpty ? value : fallback;
    }

    int readInt(String key, int fallback) {
      final value = args[key];
      return value is int ? value : fallback;
    }

    DateTime? readDate(String key) {
      final value = args[key];
      if (value is DateTime) return value;
      return null;
    }

    final addOns = <_PaymentAddOn>[];
    final rawAddOns = args['selectedAddOns'];
    if (rawAddOns is List) {
      for (final item in rawAddOns) {
        if (item is Map) {
          final title = item['title'];
          final price = item['price'];
          final productId = item['productId'];
          if (title is String && price is int) {
            final parsedProductId =
                productId is String && productId.trim().isNotEmpty
                ? productId.trim()
                : null;
            addOns.add(
              _PaymentAddOn(
                productId: parsedProductId,
                title: title,
                price: price,
              ),
            );
          }
        }
      }
    }

    final scent = args['selectedScentName'];
    final date = readDate('scheduleDate');
    final time = args['scheduleTime'] as String?;

    return _PaymentSummary(
      orderId:
          (args['orderId'] ?? args['order_id'])?.toString().trim().isEmpty ==
              true
          ? null
          : (args['orderId'] ?? args['order_id'])?.toString().trim(),
      serviceId: args['serviceId'] as String?,
      serviceName: readString('serviceName', 'Layanan Bersihuy'),
      serviceCategory: readString('serviceCategory', '-'),
      servicePrice: readInt('servicePrice', 0),
      serviceDuration: readString('serviceDuration', '-'),
      adminFee: readInt('adminFee', 0),
      selectedScentName: scent is String && scent.isNotEmpty ? scent : null,
      selectedAddOns: addOns,
      total: readInt('total', 0),
      schedule: readString('schedule', '-'),
      location: readString('location', '-'),
      scheduleDate: date,
      scheduleTime: time,
      customerNote: args['customerNote'] as String?,
    );
  }

  BersihuyOrder toFallbackOrder(String existingOrderId) {
    return BersihuyOrder(
      id: existingOrderId,
      orderNumber: '-',
      customerId: '',
      status: 'pending_payment',
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      serviceAddress: location,
      customerNote: customerNote,
      subtotalAmount: servicePrice + selectedAddOnsTotal,
      adminFee: adminFee,
      discountAmount: 0,
      totalAmount: total,
      selectedScent: selectedScentName,
    );
  }

  int get selectedAddOnsTotal =>
      selectedAddOns.fold<int>(0, (sum, item) => sum + item.price);

  Map<String, Object?> toInvoiceArguments(BersihuyOrder order) {
    return {
      'orderId': order.id,
      'orderNumber': order.orderNumber,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'servicePrice': servicePrice,
      'serviceDuration': serviceDuration,
      'adminFee': adminFee,
      'selectedScentName': selectedScentName,
      'selectedScentPrice': 0,
      'selectedAddOns': selectedAddOns
          .map(
            (addOn) => {
              'productId': addOn.productId,
              'title': addOn.title,
              'price': addOn.price,
            },
          )
          .toList(),
      'total': order.totalAmount,
      'schedule': schedule,
      'location': location,
    };
  }
}

class _PaymentAddOn {
  final String? productId;
  final String title;
  final int price;

  const _PaymentAddOn({
    this.productId,
    required this.title,
    required this.price,
  });
}

class _PremiumFlowBackground extends StatelessWidget {
  final Widget child;

  const _PremiumFlowBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFB), Color(0xFFF4FAF9), Color(0xFFEEF8F7)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        child,
      ],
    );
  }
}
