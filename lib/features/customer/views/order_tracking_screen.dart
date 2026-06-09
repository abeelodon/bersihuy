import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../repositories/order_repository.dart';
import '../services/midtrans_payment_service.dart';
import '../../chat/screens/order_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderDetail? _orderDetail;
  bool _isLoading = true;
  bool _isRefreshingPayment = false;
  bool _isPollingStatus = false;
  bool _hasReview = false;
  String? _error;
  Timer? _pollingTimer;

  static const _midtransService = MidtransPaymentService();

  @override
  void dispose() {
    _stopTrackingPolling();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetail();
    });
  }

  Future<void> _loadOrderDetail() async {
    final orderId = widget.orderId.trim();
    debugPrint('OrderTrackingScreen received orderId=$orderId');

    if (orderId.isEmpty) {
      debugPrint('Order ID kosong saat membuka TrackOrderScreen');
      setState(() {
        _error = 'Order ID belum tersedia.';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final detail = await const OrderRepository().getOrderWithDetails(orderId);
      var hasReview = false;
      if (detail?.order.status == 'completed') {
        try {
          hasReview = await const OrderRepository().hasReviewForOrder(orderId);
        } catch (e) {
          debugPrint('OrderTrackingScreen: failed to check review — $e');
        }
      }
      if (!mounted) return;
      setState(() {
        _orderDetail = detail;
        _hasReview = hasReview;
        _isLoading = false;
        _error = null;
      });

      // Start/stop polling based on order status
      if (detail != null && _isPendingPayment(detail)) {
        _startTrackingPolling(orderId);
      } else {
        _stopTrackingPolling();
      }
    } catch (e) {
      debugPrint('OrderTrackingScreen: failed to load order — $e');
      if (!mounted) return;
      setState(() {
        _error = 'Data pesanan tidak dapat dimuat. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  _TrackingState _trackingState(OrderDetail detail) {
    if (_isPendingPayment(detail)) {
      return const _TrackingState(
        title: 'Menunggu Pembayaran',
        description:
            'Selesaikan pembayaran agar pesanan dapat dikonfirmasi dan diproses.',
      );
    }

    if (!detail.hasTask) {
      return const _TrackingState(
        title: 'Menunggu Penugasan',
        description:
            'Pesanan sudah tercatat dan sedang menunggu penugasan petugas oleh admin.',
      );
    }

    return switch (detail.taskStatus) {
      'assigned' => const _TrackingState(
        title: 'Petugas Ditugaskan',
        description: 'Petugas sudah dijadwalkan untuk pesanan ini.',
      ),
      'in_progress' => const _TrackingState(
        title: 'Sedang Dikerjakan',
        description: 'Petugas sedang mengerjakan layanan.',
      ),
      'proof_uploaded' => const _TrackingState(
        title: 'Bukti Pekerjaan Diunggah',
        description: 'Petugas telah mengunggah bukti pekerjaan.',
      ),
      'completed' => const _TrackingState(
        title: 'Pesanan Selesai',
        description: 'Layanan sudah selesai dikerjakan.',
      ),
      'cancelled' => const _TrackingState(
        title: 'Tugas Dibatalkan',
        description: 'Tugas untuk pesanan ini dibatalkan.',
      ),
      _ => _orderStatusFallback(detail.order.status),
    };
  }

  _TrackingState _orderStatusFallback(String status) {
    return switch (status) {
      'in_progress' => const _TrackingState(
        title: 'Sedang Dikerjakan',
        description: 'Pesanan sedang dalam proses pengerjaan.',
      ),
      'completed' => const _TrackingState(
        title: 'Pesanan Selesai',
        description: 'Layanan sudah selesai dikerjakan.',
      ),
      'cancelled' => const _TrackingState(
        title: 'Pesanan Dibatalkan',
        description: 'Pesanan ini telah dibatalkan.',
      ),
      _ => const _TrackingState(
        title: 'Pesanan Diproses',
        description: 'Pesanan sudah tercatat dan sedang diproses.',
      ),
    };
  }

  String _paymentStatusLabel(String? status) {
    return switch (status) {
      'paid' => 'Dibayar',
      'pending' => 'Menunggu Pembayaran',
      'failed' => 'Gagal',
      'expired' => 'Kedaluwarsa',
      null || '' => 'Belum ada pembayaran',
      _ => status,
    };
  }

  String _taskStatusLabel(String? status) {
    return switch (status) {
      'assigned' => 'Ditugaskan',
      'scheduled' => 'Dijadwalkan',
      'in_progress' => 'Dalam Proses',
      'proof_uploaded' => 'Bukti Diunggah',
      'completed' => 'Selesai',
      'cancelled' => 'Dibatalkan',
      null || '' => 'Menunggu penugasan',
      _ => status,
    };
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

  // ── Format schedule for display ─────────────────────────────────────────
  String _formatSchedule(OrderDetail detail) {
    final date = detail.order.scheduleDate;
    final time = detail.order.scheduleTime;
    if (date == null && (time == null || time.isEmpty)) {
      return 'Belum dijadwalkan';
    }
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final dateStr = date != null
        ? '${date.day} ${months[date.month - 1]} ${date.year}'
        : null;
    if (dateStr != null && time != null && time.isNotEmpty) {
      return '$dateStr, $time';
    }
    return dateStr ?? time ?? 'Belum dijadwalkan';
  }

  // ── Staff initials from full name ────────────────────────────────────────
  String _staffInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _PremiumFlowBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                  ? _buildErrorState()
                  : _orderDetail == null
                  ? _buildNotFoundState()
                  : _buildContent(),
            ),
          ),
        ),
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
        'Lacak Pesanan',
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

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _loadOrderDetail,
            child: Text(
              'Coba Lagi',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.outline,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Data pesanan tidak ditemukan.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final detail = _orderDetail!;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeroCard(detail),
            const SizedBox(height: 16),
            _buildOrderSummaryCard(detail),
            const SizedBox(height: 16),
            _buildStaffCard(detail),
            const SizedBox(height: 16),
            _buildTimeline(detail),
            const SizedBox(height: 16),
            _buildProofSection(detail),
            const SizedBox(height: 14),
            Text(
              'Status pesanan diperbarui secara otomatis.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 14),
            _buildActionButtons(detail),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeroCard(OrderDetail detail) {
    final trackingState = _trackingState(detail);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F8F8A), Color(0xFF45BDB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.serviceName,
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail.order.orderNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 14),
          _statusBadge(trackingState.title, onDark: true),
          const SizedBox(height: 8),
          Text(
            trackingState.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _heroMeta(Icons.calendar_month_rounded, _formatSchedule(detail)),
          const SizedBox(height: 8),
          _heroMeta(Icons.location_on_rounded, detail.order.serviceAddress),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(OrderDetail detail) {
    final addOns = detail.orderItems
        .where((item) => item.itemType == 'addon' || item.itemType == 'product')
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pesanan',
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Nomor Pesanan', detail.order.orderNumber, maxLines: 1),
          const SizedBox(height: 10),
          _detailRow('Layanan', detail.serviceName),
          for (final addOn in addOns) ...[
            const SizedBox(height: 10),
            _detailRow(
              addOn.quantity > 1
                  ? '${addOn.itemName} x${addOn.quantity}'
                  : addOn.itemName,
              _formatRupiah(addOn.totalPrice),
            ),
          ],
          const SizedBox(height: 10),
          _detailRow('Total', _formatRupiah(detail.order.totalAmount)),
          const SizedBox(height: 10),
          _detailRow(
            'Status Pembayaran',
            _paymentStatusLabel(detail.payment?.status),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {int maxLines = 2}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffCard(OrderDetail detail) {
    final hasStaff = detail.hasAssignedStaff;
    final hasAssignedStaffId = detail.hasAssignedStaffId;
    final staffTitle = hasStaff
        ? detail.assignedStaffName!
        : hasAssignedStaffId
        ? 'Petugas ditugaskan'
        : detail.hasTask
        ? 'Petugas belum ditugaskan'
        : 'Menunggu Penugasan';
    final staffDescription = detail.hasTask
        ? 'Status tugas: ${_taskStatusLabel(detail.taskStatus)}'
        : 'Menunggu penugasan petugas oleh admin.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Petugas',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: hasStaff
                      ? Text(
                          _staffInitials(detail.assignedStaffName),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.person_search_rounded,
                          color: AppColors.primary,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffTitle,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: hasAssignedStaffId
                            ? AppColors.onSurface
                            : AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staffDescription,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasStaff)
                IconButton(
                  onPressed: () => _openChatPetugas(detail),
                  icon: const Icon(Icons.chat_bubble_outline),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.07),
                  ),
                ),
            ],
          ),
          if (hasStaff) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _openChatPetugas(detail),
              icon: const Icon(Icons.chat_rounded, size: 16),
              label: const Text('Chat Petugas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 11),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openChatPetugas(OrderDetail detail) {
    if (!detail.hasAssignedStaffId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat tersedia setelah petugas ditugaskan.')),
      );
      return;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderChatScreen(
          orderId: detail.order.id!,
          currentUserId: currentUserId,
          customerId: detail.order.customerId,
          staffId: detail.assignedStaffId!,
          orderNumber: detail.order.orderNumber,
          receiverName: detail.assignedStaffName,
          serviceAddress: detail.order.serviceAddress,
          title: 'Chat Petugas',
        ),
      ),
    );
  }

  void _openInvoice(OrderDetail detail) {
    final orderId = detail.order.id?.trim();
    debugPrint('OrderTrackingScreen Lihat Invoice orderId=$orderId');
    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID kosong saat membuka invoice.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.invoice,
      arguments: {'orderId': orderId},
    );
  }

  Widget _buildTimeline(OrderDetail detail) {
    final steps = _timelineSteps(detail);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Pesanan',
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < steps.length; i++) ...[
            _buildTimelineStep(
              steps[i].title,
              steps[i].subtitle,
              isLast: i == steps.length - 1,
              isCompleted: steps[i].isCompleted,
              isActive: steps[i].isActive,
            ),
          ],
        ],
      ),
    );
  }

  List<_TimelineStep> _timelineSteps(OrderDetail detail) {
    final status = detail.order.status;
    final taskStatus = detail.taskStatus ?? status;
    final activeSteps = <int>{};

    if (_isPendingPayment(detail)) {
      activeSteps.add(0);
    } else {
      switch (status) {
        case 'scheduled':
          activeSteps.addAll({0, 1, 2});
          break;
        case 'in_progress':
          activeSteps.addAll({0, 1, 2, 3, 4});
          break;
        case 'completed':
          activeSteps.addAll({0, 1, 2, 3, 4, 5});
          break;
        case 'paid':
          // Legacy: treat paid same as scheduled
          activeSteps.addAll({0, 1, 2});
          break;
        case 'created':
        case 'pending_payment':
        default:
          activeSteps.add(0);
          break;
      }
    }

    if (!_isPendingPayment(detail)) {
      if (detail.hasAssignedStaff) {
        activeSteps.addAll({0, 1, 2, 3});
      }
      if (taskStatus == 'in_progress') {
        activeSteps.addAll({0, 1, 2, 3, 4});
      }
      if (taskStatus == 'proof_uploaded') {
        activeSteps.addAll({0, 1, 2, 3, 4});
      }
      if (taskStatus == 'completed') {
        activeSteps.addAll({0, 1, 2, 3, 4, 5});
      }
    }

    final currentIndex = activeSteps.isEmpty
        ? 0
        : activeSteps.reduce((a, b) => a > b ? a : b);
    const templates = [
      (
        title: 'Menunggu Pembayaran',
        subtitle: 'Selesaikan pembayaran untuk mengonfirmasi pesanan.',
      ),
      (
        title: 'Pesanan Dikonfirmasi',
        subtitle: 'Pembayaran berhasil dan pesanan masuk ke sistem.',
      ),
      (
        title: 'Menunggu Penugasan Petugas',
        subtitle: 'Admin sedang menyesuaikan jadwal dan petugas layanan.',
      ),
      (
        title: 'Petugas Ditugaskan',
        subtitle: 'Petugas sudah ditentukan untuk pesanan kamu.',
      ),
      (
        title: 'Pembersihan Berlangsung',
        subtitle: 'Petugas sedang mengerjakan layanan.',
      ),
      (
        title: 'Pesanan Selesai',
        subtitle:
            'Layanan sudah selesai. Beri ulasan untuk membantu kami menjaga kualitas.',
      ),
    ];

    return List.generate(templates.length, (index) {
      return _TimelineStep(
        title: templates[index].title,
        subtitle: templates[index].subtitle,
        isCompleted: activeSteps.contains(index),
        isActive: index == currentIndex,
      );
    });
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle, {
    bool isLast = false,
    bool isCompleted = false,
    bool isActive = false,
  }) {
    final activeColor = isCompleted
        ? AppColors.primary
        : AppColors.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.primary : Colors.white,
                  border: Border.all(color: activeColor, width: 2),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: activeColor.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: (isCompleted || isActive)
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : (isCompleted
                                ? AppColors.onSurface
                                : AppColors.outline),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive ? AppColors.primary : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofSection(OrderDetail detail) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bukti Pekerjaan',
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProofCard(
                  title: 'Sebelum',
                  imageUrl: detail.beforePhotoUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProofCard(
                  title: 'Sesudah',
                  imageUrl: detail.afterPhotoUrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard({required String title, required String? imageUrl}) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    return Container(
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.outline,
                  size: 34,
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 34,
                    color: AppColors.outline.withValues(alpha: 0.72),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Belum diunggah',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.onSurface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderDetail detail) {
    final status = detail.order.status;
    final orderId = detail.order.id;
    final canComplain = {
      'paid',
      'scheduled',
      'in_progress',
      'completed',
    }.contains(status);
    final isPendingPayment = _isPendingPayment(detail);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPendingPayment) ...[
          ElevatedButton(
            onPressed: () => _continuePayment(detail),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Lanjutkan Pembayaran',
              style: AppTextStyles.buttonLabel.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _isRefreshingPayment
                ? null
                : () => _refreshPaymentStatus(detail),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isRefreshingPayment
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
                    'Perbarui Status Pembayaran',
                    style: AppTextStyles.buttonLabel.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
        ],
        if (!isPendingPayment &&
            detail.hasAssignedStaff &&
            status != 'completed') ...[
          ElevatedButton(
            onPressed: () => _openChatPetugas(detail),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Hubungi Petugas',
              style: AppTextStyles.buttonLabel.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (status == 'completed') ...[
          ElevatedButton(
            onPressed: () {
              if (_hasReview) return;
              Navigator.pushNamed(
                context,
                AppRoutes.ratingReview,
                arguments: {
                  'orderId': orderId,
                  'staffId': detail.assignedStaffId,
                },
              ).then((_) => _loadOrderDetail());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasReview
                  ? AppColors.outlineVariant
                  : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _hasReview ? 'Ulasan Terkirim' : 'Beri Rating',
              style: AppTextStyles.buttonLabel.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (canComplain && !isPendingPayment) ...[
          OutlinedButton(
            onPressed: () {
              if (orderId == null || orderId.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order ID kosong saat membuka keluhan.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pushNamed(
                context,
                AppRoutes.complaint,
                arguments: {'orderId': orderId},
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Ajukan Keluhan',
              style: AppTextStyles.buttonLabel.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => _openInvoice(detail),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Lihat Invoice',
              style: AppTextStyles.buttonLabel.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _isPendingPayment(OrderDetail detail) {
    if ({'completed', 'cancelled'}.contains(detail.order.status)) {
      return false;
    }
    return detail.order.status == 'pending_payment' ||
        detail.order.status == 'created' ||
        detail.payment?.status == 'pending';
  }

  void _continuePayment(OrderDetail detail) {
    final orderId = detail.order.id?.trim();
    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID belum tersedia.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    debugPrint('OrderTrackingScreen continue payment orderId=$orderId');
    Navigator.pushNamed(
      context,
      AppRoutes.payment,
      arguments: {'orderId': orderId},
    ).then((_) => _loadOrderDetail());
  }

  Future<void> _refreshPaymentStatus(OrderDetail detail) async {
    final orderId = detail.order.id?.trim();
    if (orderId == null || orderId.isEmpty) return;

    setState(() => _isRefreshingPayment = true);
    try {
      final status = await _midtransService.checkPayment(orderId: orderId);
      if (!mounted) return;

      if (status.isPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil dikonfirmasi!'),
            backgroundColor: AppColors.primary,
          ),
        );
        await _loadOrderDetail();
        return;
      }

      final message = switch (status.status) {
        'pending' => 'Pembayaran masih menunggu konfirmasi Midtrans.',
        'expired' => 'Pembayaran Midtrans sudah kedaluwarsa.',
        'cancelled' => 'Pembayaran Midtrans dibatalkan.',
        _ => 'Pembayaran Midtrans gagal diproses.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (status.status != 'pending') {
        await _loadOrderDetail();
      }
    } on MidtransPaymentException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status pembayaran gagal diperiksa.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshingPayment = false);
      }
    }
  }

  // ── Auto-polling ──────────────────────────────────────────────────────────

  void _startTrackingPolling(String orderId) {
    if (_pollingTimer != null) return;
    debugPrint('TRACKING POLLING STARTED orderId=$orderId (every 5s)');
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollTrackingStatus(orderId),
    );
  }

  void _stopTrackingPolling() {
    if (_pollingTimer == null) return;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('TRACKING POLLING STOPPED');
  }

  Future<void> _pollTrackingStatus(String orderId) async {
    if (_isPollingStatus || _isRefreshingPayment || !mounted) return;
    _isPollingStatus = true;
    try {
      debugPrint('TRACKING POLL orderId=$orderId');
      final status = await _midtransService.checkPayment(orderId: orderId);
      if (!mounted) return;

      debugPrint(
        'TRACKING POLL RESULT status=${status.status} '
        'isPaid=${status.isPaid} orderStatus=${status.orderStatus}',
      );

      if (status.isPaid) {
        debugPrint('TRACKING POLL: PAID detected — reloading order detail');
        _stopTrackingPolling();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil dikonfirmasi!'),
            backgroundColor: AppColors.primary,
          ),
        );
        await _loadOrderDetail();
        return;
      }

      if (!status.isPending) {
        // expired / cancelled / failed — stop polling, reload detail
        debugPrint(
          'TRACKING POLL: terminal status ${status.status} — stopping',
        );
        _stopTrackingPolling();
        await _loadOrderDetail();
      }
    } catch (error) {
      debugPrint('TRACKING POLL ERROR: $error');
      // Non-fatal — keep polling, next tick will retry
    } finally {
      _isPollingStatus = false;
    }
  }

  Widget _heroMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text, {bool onDark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.24)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: onDark ? Colors.white : AppColors.primary,
        ),
      ),
    );
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

class _TrackingState {
  final String title;
  final String description;

  const _TrackingState({required this.title, required this.description});
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isActive = false,
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
