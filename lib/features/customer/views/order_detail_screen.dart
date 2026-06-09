import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = _OrderDetailData.fromRouteArgs(
      ModalRoute.of(context)?.settings.arguments,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: _PremiumOrderBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(order),
                      const SizedBox(height: 16),
                      _buildDetailCard(order),
                      const SizedBox(height: 16),
                      _buildPaymentCard(order),
                      const SizedBox(height: 22),
                      _buildActionButton(context, order),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
        'Detail Pesanan',
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 0,
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

  Widget _buildHeaderCard(_OrderDetailData order) {
    final statusColor = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.serviceName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.invoiceNumber,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(order.status, statusColor),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.schedule,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(_OrderDetailData order) {
    return _infoCard(
      title: 'Informasi Pesanan',
      children: [
        _infoRow('Kategori', order.category),
        _divider(),
        _infoRow('Alamat', order.address),
        _divider(),
        _infoRow('Petugas', order.staffName),
        _divider(),
        _infoRow('Catatan', order.notes),
      ],
    );
  }

  Widget _buildPaymentCard(_OrderDetailData order) {
    return _infoCard(
      title: 'Pembayaran',
      children: [
        _infoRow('Status pembayaran', order.paymentStatus, isStrong: true),
        _divider(),
        _infoRow('Harga layanan', _formatRupiah(order.servicePrice)),
        _divider(),
        _infoRow(
          'Total pembayaran',
          _formatRupiah(order.total),
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, _OrderDetailData order) {
    final label = switch (order.status) {
      'Selesai' => 'Lihat Invoice',
      'Dibatalkan' => 'Pesan Lagi',
      _ => 'Lacak Pesanan',
    };

    return ElevatedButton(
      onPressed: () {
        if (order.status == 'Selesai') {
          Navigator.pushNamed(
            context,
            AppRoutes.invoice,
            arguments: order.toInvoiceArguments(),
          );
        } else if (order.status == 'Dibatalkan') {
          Navigator.pushNamed(context, AppRoutes.customerServices);
        } else {
          final orderId = order.orderId?.trim();
          debugPrint('OrderDetailScreen Lacak Pesanan orderId=$orderId');
          if (orderId == null || orderId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order ID kosong saat membuka pelacakan.'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
          Navigator.pushNamed(
            context,
            AppRoutes.orderTracking,
            arguments: {'orderId': orderId},
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        label,
        style: AppTextStyles.buttonLabel.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isStrong = false,
    bool isPrimary = false,
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
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isPrimary ? AppColors.primary : AppColors.onSurface,
              fontWeight: isStrong || isPrimary
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: AppColors.outlineVariant.withValues(alpha: 0.72),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Dibatalkan' => AppColors.error,
      'Menunggu Jadwal' => const Color(0xFF9A6A00),
      'Selesai' => const Color(0xFF2E7D32),
      _ => AppColors.primary,
    };
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

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final positionFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp$buffer';
  }
}

class _OrderDetailData {
  final String? orderId;
  final String serviceName;
  final String invoiceNumber;
  final String status;
  final String schedule;
  final String address;
  final String staffName;
  final int total;
  final int servicePrice;
  final String category;
  final String paymentStatus;
  final String notes;

  const _OrderDetailData({
    this.orderId,
    required this.serviceName,
    required this.invoiceNumber,
    required this.status,
    required this.schedule,
    required this.address,
    required this.staffName,
    required this.total,
    required this.servicePrice,
    required this.category,
    required this.paymentStatus,
    required this.notes,
  });

  factory _OrderDetailData.fromRouteArgs(Object? args) {
    if (args is! Map) {
      return const _OrderDetailData(
        serviceName: 'Layanan Bersihuy',
        invoiceNumber: '-',
        status: 'Dijadwalkan',
        schedule: '-',
        address: '-',
        staffName: 'Menunggu penugasan',
        total: 0,
        servicePrice: 0,
        category: '-',
        paymentStatus: '-',
        notes: '-',
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

    return _OrderDetailData(
      orderId: args['orderId'] as String?,
      serviceName: readString('serviceName', 'Layanan Bersihuy'),
      invoiceNumber: readString('invoiceNumber', '-'),
      status: readString('status', 'Dijadwalkan'),
      schedule: readString('schedule', '-'),
      address: readString('address', '-'),
      staffName: readString('staffName', 'Menunggu penugasan'),
      total: readInt('total', 0),
      servicePrice: readInt('servicePrice', 0),
      category: readString('category', '-'),
      paymentStatus: readString('paymentStatus', '-'),
      notes: readString('notes', '-'),
    );
  }

  Map<String, Object?> toInvoiceArguments() {
    final adminFee = total > servicePrice ? total - servicePrice : 0;
    return {
      'orderId': orderId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'serviceDuration': '-',
      'adminFee': adminFee,
      'selectedScentName': null,
      'selectedAddOns': <Map<String, Object>>[],
      'total': total,
      'schedule': schedule,
      'location': address,
    };
  }
}

class _PremiumOrderBackground extends StatelessWidget {
  final Widget child;

  const _PremiumOrderBackground({required this.child});

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
