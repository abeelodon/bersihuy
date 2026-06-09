import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../repositories/order_repository.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  static const _repository = OrderRepository();

  String? _orderId;
  String? _orderNumber;
  String? _loadError;
  DateTime? _paymentDate;
  String? _paymentMethod;
  String? _paymentProvider;
  String? _paymentStatus;
  OrderDetail? _orderDetail;
  BersihuyOrder? _order; // fetched from Supabase — source of truth for pricing
  bool _didLoadRouteData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadRouteData) return;
    _didLoadRouteData = true;
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    final summary = _InvoiceSummary.fromRouteArgs(
      ModalRoute.of(context)?.settings.arguments,
    );

    var orderId = summary.orderId?.trim();
    final orderNumber = summary.orderNumber?.trim();

    if (mounted) {
      setState(() {
        _orderNumber = orderNumber;
        _loadError = null;
      });
    }

    if (orderId == null || orderId.isEmpty) {
      if (orderNumber == null || orderNumber.isEmpty) {
        debugPrint('InvoiceScreen opened without orderId or orderNumber');
        if (!mounted) return;
        setState(() => _loadError = 'Order ID belum tersedia.');
        return;
      }

      try {
        orderId = await _repository.getOrderIdByNumber(orderNumber);
      } catch (error, stackTrace) {
        debugPrint('INVOICE ORDER ID LOOKUP ERROR: $error');
        debugPrint('INVOICE ORDER ID LOOKUP STACKTRACE: $stackTrace');
        if (!mounted) return;
        setState(() {
          _loadError = 'Data pesanan tidak dapat dimuat. Silakan coba lagi.';
        });
        return;
      }
    }

    if (orderId == null || orderId.isEmpty) {
      if (!mounted) return;
      setState(() => _loadError = 'Data pesanan tidak ditemukan.');
      return;
    }

    debugPrint('InvoiceScreen opened orderId=$orderId');

    if (!mounted) return;
    setState(() {
      _orderId = orderId;
    });

    try {
      final detail = await _repository.getOrderWithDetails(orderId);
      if (!mounted) return;

      if (detail == null) {
        setState(() => _loadError = 'Data pesanan tidak ditemukan.');
        return;
      }

      setState(() {
        _orderDetail = detail;
        _order = detail.order;
        _orderNumber = detail.order.orderNumber;
        _paymentDate = detail.payment?.paidAt;
        _paymentMethod = detail.payment?.paymentMethod;
        _paymentProvider = detail.payment?.provider;
        _paymentStatus = detail.payment?.status;
        _loadError = null;
      });
    } catch (e, st) {
      debugPrint('INVOICE LOAD ERROR: $e');
      debugPrint('INVOICE STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _loadError = 'Data pesanan tidak dapat dimuat. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _InvoiceSummary.fromRouteArgs(
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
              child: Stack(
                children: [
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 164),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSuccessStatusHeader(),
                          if (_loadError != null) ...[
                            const SizedBox(height: 16),
                            _buildLoadErrorCard(),
                          ],
                          const SizedBox(height: 24),
                          _buildInvoiceInfoCard(summary),
                          const SizedBox(height: 20),
                          _buildOrderDetailsCard(summary),
                          const SizedBox(height: 20),
                          _buildPricingDetailsCard(summary),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomActions(context),
                  ),
                ],
              ),
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
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        },
      ),
      title: Text(
        'Invoice',
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

  Widget _buildSuccessStatusHeader() {
    final isPending =
        _paymentStatus == 'pending' || _paymentStatus == 'pending_payment';
    final isPaid = _paymentStatus == null || _paymentStatus == 'paid';

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            isPending ? Icons.schedule_rounded : Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 52,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isPending ? 'Pembayaran Menunggu Konfirmasi' : 'Pembayaran Berhasil',
          style: AppTextStyles.headlineSmall.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPending
              ? 'Selesaikan pembayaran agar pesanan dapat diproses.'
              : 'Pesanan kamu sudah dikonfirmasi dan sedang diproses.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isPaid ? 'Dibayar' : _paymentStatusLabel(_paymentStatus),
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceInfoCard(_InvoiceSummary summary) {
    final displayNumber = _orderNumber ?? summary.orderNumber ?? '-';
    final displayDateSource = _paymentDate ?? _order?.createdAt;
    final displayDate = displayDateSource != null
        ? _formatDate(displayDateSource)
        : '-';
    final displayMethod =
        _paymentMethod ??
        (_paymentProvider?.toLowerCase() == 'midtrans'
            ? 'Snap Sandbox'
            : 'QRIS Dummy');
    final displayProvider = _paymentProviderLabel(_paymentProvider);

    return _infoCard(
      children: [
        _buildInfoRow(
          'Nomor Invoice',
          displayNumber,
          isBoldValue: true,
          maxLines: 1,
        ),
        _divider(),
        _buildInfoRow('Tanggal', displayDate, isBoldValue: true),
        _divider(),
        _buildInfoRow('Metode Pembayaran', displayMethod, isBoldValue: true),
        _divider(),
        _buildInfoRow('Provider', displayProvider, isSecondaryValue: true),
        _divider(),
        _buildInfoRow(
          'Status Pembayaran',
          _paymentStatusLabel(_paymentStatus),
          isPrimaryValue: true,
        ),
      ],
    );
  }

  Widget _buildOrderDetailsCard(_InvoiceSummary summary) {
    final serviceName = _order?.serviceName ?? summary.serviceName;
    final schedule = _orderDetail != null
        ? _formatSchedule(_orderDetail!)
        : summary.schedule;
    final location = _order?.serviceAddress.isNotEmpty == true
        ? _order!.serviceAddress
        : summary.location;
    final staffName = _orderDetail?.hasAssignedStaff == true
        ? _orderDetail!.assignedStaffName!
        : _orderDetail?.hasAssignedStaffId == true
        ? 'Petugas ditugaskan'
        : 'Menunggu penugasan';
    return _infoCard(
      title: 'Detail Pesanan',
      children: [
        _buildInfoRow('Layanan', serviceName, isBoldValue: true),
        _divider(),
        _buildInfoRow('Jadwal', schedule, isBoldValue: true),
        _divider(),
        _buildInfoRow('Lokasi', location, isBoldValue: true),
        _divider(),
        _buildInfoRow('Durasi', summary.serviceDuration, isBoldValue: true),
        _divider(),
        _buildInfoRow('Staff', staffName, isSecondaryValue: true),
      ],
    );
  }

  Widget _buildPricingDetailsCard(_InvoiceSummary summary) {
    // Use real data from Supabase when available; fall back to route args
    final isFromSupabase = _order != null;
    final adminFee = isFromSupabase ? _order!.adminFee : summary.adminFee;
    final total = isFromSupabase ? _order!.totalAmount : summary.total;
    final orderItems = isFromSupabase
        ? _order!.orderItems
        : <BersihuyOrderItem>[];
    final serviceItem = orderItems
        .where((item) => item.itemType == 'service')
        .firstOrNull;

    // Derive add-on items from order_items or route args
    final List<({String name, int price})> addOns;
    if (isFromSupabase) {
      addOns = orderItems
          .where((i) => i.itemType == 'addon' || i.itemType == 'product')
          .map((i) => (name: i.itemName, price: i.totalPrice))
          .toList();
    } else {
      addOns = summary.selectedAddOns
          .map((a) => (name: a.title, price: a.price))
          .toList();
    }
    final addOnTotal = addOns.fold<int>(0, (sum, item) => sum + item.price);
    final servicePrice = isFromSupabase
        ? serviceItem?.totalPrice ?? (_order!.subtotalAmount - addOnTotal)
        : summary.servicePrice;

    return _infoCard(
      title: 'Rincian Harga',
      children: [
        _buildInfoRow('Harga layanan', _formatRupiah(servicePrice)),
        const SizedBox(height: 10),
        _buildInfoRow('Biaya admin', _formatRupiah(adminFee)),
        if (summary.selectedScentName != null) ...[
          const SizedBox(height: 10),
          _buildInfoRow('Aroma ${summary.selectedScentName}', _formatRupiah(0)),
        ],
        for (final addOn in addOns) ...[
          const SizedBox(height: 10),
          _buildInfoRow(addOn.name, _formatRupiah(addOn.price)),
        ],
        _divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Pembayaran',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              _formatRupiah(total),
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadError!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({String? title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBoldValue = false,
    bool isPrimaryValue = false,
    bool isSecondaryValue = false,
    int maxLines = 2,
  }) {
    Color valueColor = AppColors.onSurface;
    if (isPrimaryValue) {
      valueColor = AppColors.primary;
    } else if (isSecondaryValue) {
      valueColor = AppColors.outline;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: (isBoldValue || isPrimaryValue || isSecondaryValue)
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
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
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final orderId = _orderId?.trim();
                debugPrint('InvoiceScreen Lacak Pesanan orderId=$orderId');
                if (orderId != null && orderId.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.orderTracking,
                    arguments: {'orderId': orderId},
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_loadError ?? 'Order ID belum tersedia.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Lacak Pesanan',
                style: AppTextStyles.buttonLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur unduh invoice segera hadir.'),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.55),
                ),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Unduh Invoice',
                style: AppTextStyles.buttonLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _paymentStatusLabel(String? status) {
    return switch (status) {
      'paid' => 'Dibayar',
      'pending' || 'pending_payment' => 'Menunggu Pembayaran',
      'failed' => 'Gagal',
      'expired' => 'Kedaluwarsa',
      'cancelled' => 'Dibatalkan',
      'refunded' => 'Dikembalikan',
      null || '' => '-',
      _ => status,
    };
  }

  String _paymentProviderLabel(String? provider) {
    return switch (provider?.toLowerCase()) {
      'dummy' || 'sandbox' || 'midtrans_sandbox' => 'Dummy / Sandbox',
      'midtrans' => 'Midtrans Sandbox',
      null || '' => 'Dummy / Sandbox',
      _ => provider!,
    };
  }

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
    final dateText = date != null
        ? '${date.day} ${months[date.month - 1]} ${date.year}'
        : null;
    if (dateText != null && time != null && time.isNotEmpty) {
      return '$dateText, $time';
    }
    return dateText ?? time ?? 'Belum dijadwalkan';
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

// ── Data class ────────────────────────────────────────────────────────────────

class _InvoiceSummary {
  final String? orderId;
  final String? orderNumber;
  final String serviceName;
  final int servicePrice;
  final String serviceDuration;
  final int adminFee;
  final String? selectedScentName;
  final List<_InvoiceAddOn> selectedAddOns;
  final int total;
  final String schedule;
  final String location;

  const _InvoiceSummary({
    this.orderId,
    this.orderNumber,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    required this.adminFee,
    required this.selectedScentName,
    required this.selectedAddOns,
    required this.total,
    required this.schedule,
    required this.location,
  });

  factory _InvoiceSummary.fromRouteArgs(Object? args) {
    if (args is! Map) {
      return const _InvoiceSummary(
        serviceName: 'Layanan Bersihuy',
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

    final addOns = <_InvoiceAddOn>[];
    final rawAddOns = args['selectedAddOns'];
    if (rawAddOns is List) {
      for (final item in rawAddOns) {
        if (item is Map) {
          final title = item['title'];
          final price = item['price'];
          if (title is String && price is int) {
            addOns.add(_InvoiceAddOn(title: title, price: price));
          }
        }
      }
    }

    final scent = args['selectedScentName'];

    return _InvoiceSummary(
      orderId: args['orderId'] as String?,
      orderNumber: args['orderNumber'] as String?,
      serviceName: readString('serviceName', 'Layanan Bersihuy'),
      servicePrice: readInt('servicePrice', 0),
      serviceDuration: readString('serviceDuration', '-'),
      adminFee: readInt('adminFee', 0),
      selectedScentName: scent is String && scent.isNotEmpty ? scent : null,
      selectedAddOns: addOns,
      total: readInt('total', 0),
      schedule: readString('schedule', '-'),
      location: readString('location', '-'),
    );
  }
}

class _InvoiceAddOn {
  final String title;
  final int price;

  const _InvoiceAddOn({required this.title, required this.price});
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
