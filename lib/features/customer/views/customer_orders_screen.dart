import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/customer_bottom_nav.dart';
import '../repositories/order_repository.dart';
import '../services/customer_order_service.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  int _selectedTab = 0;
  static const _tabs = ['Aktif', 'Selesai', 'Dibatalkan'];

  static const _orderService = CustomerOrderService();
  static const _repository = OrderRepository();
  List<BersihuyOrder> _allOrders = [];
  Set<String> _reviewedOrderIds = {};
  Map<String, CustomerReview> _reviewsByOrderId = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    debugPrint('ORDERS SCREEN LOAD START');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ── Core orders fetch (must succeed) ──────────────────────────────
      debugPrint('ORDERS FETCH START');
      final orders = await _orderService.getMyOrders();
      debugPrint('ORDERS RAW DATA count=${orders.length}');
      debugPrint('ORDER PARSE SUCCESS count=${orders.length}');

      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _error = null;
      });

      // ── Optional: load order items for service names ──────────────────
      for (final order in orders) {
        final orderId = order.id?.trim();
        if (orderId == null || orderId.isEmpty) continue;
        try {
          final items = await _repository.loadOrderItemsForHome(orderId);
          if (items.isNotEmpty) {
            order.orderItems = items;
          }
        } catch (e) {
          debugPrint('ORDERS ITEMS LOAD ERROR ($orderId): $e');
        }
      }

      // ── Optional: review enrichment (never fails the screen) ─────────
      final reviewedOrderIds = <String>{};
      final reviewsByOrderId = <String, CustomerReview>{};
      for (final order in orders) {
        final orderId = order.id?.trim();
        if (order.status != 'completed' || orderId == null || orderId.isEmpty) {
          continue;
        }
        try {
          final review = await _repository.getReviewForOrder(orderId);
          if (review != null) {
            reviewedOrderIds.add(orderId);
            reviewsByOrderId[orderId] = review;
          }
        } catch (e) {
          debugPrint('ORDERS REVIEW CHECK ERROR ($orderId): $e');
          // safe — continue to next order
        }
      }

      if (mounted) {
        setState(() {
          _reviewedOrderIds = reviewedOrderIds;
          _reviewsByOrderId = reviewsByOrderId;
        });
      }
    } catch (e, st) {
      debugPrint('ORDERS SCREEN LOAD ERROR: $e');
      debugPrint('ORDERS STACKTRACE: $st');
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat pesanan.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('ORDERS SCREEN LOAD FINALLY loading=false');
      }
    }
  }

  List<BersihuyOrder> get _filteredOrders {
    final activeStatuses = {
      'created',
      'pending_payment',
      'paid',
      'scheduled',
      'in_progress',
    };
    final completedStatuses = {'completed', 'complained'};

    return switch (_selectedTab) {
      0 => _allOrders.where((o) => activeStatuses.contains(o.status)).toList(),
      1 =>
        _allOrders.where((o) => completedStatuses.contains(o.status)).toList(),
      2 => _allOrders.where((o) => o.status == 'cancelled').toList(),
      _ => _allOrders,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'scheduled' => 'Dijadwalkan',
      'completed' => 'Selesai',
      'cancelled' => 'Dibatalkan',
      'pending_payment' => 'Menunggu Pembayaran',
      'paid' => 'Dijadwalkan',
      'in_progress' => 'Dalam Proses',
      'assigned' => 'Ditugaskan',
      _ => status,
    };
  }

  IconData _serviceIcon(String? category) {
    return switch (category?.toLowerCase()) {
      'kos' => Icons.single_bed_outlined,
      'kantor' => Icons.apartment_outlined,
      'khusus' => Icons.yard_outlined,
      _ => Icons.cleaning_services_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _PremiumCustomerBackground(
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  20,
                                  22,
                                  118,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Pesanan Saya',
                                      style: AppTextStyles.headlineLarge
                                          .copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF142232),
                                            letterSpacing: 0,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pantau status layanan dan riwayat pesananmu',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTabs(),
                                    const SizedBox(height: 20),
                                    _buildOrderList(),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CustomerBottomNav(currentIndex: 2),
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
      titleSpacing: 20,
      centerTitle: false,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
      title: Image.asset(
        'assets/images/logo_full.png',
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text('Bersihuy'),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.customerNotifications);
          },
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: AppColors.onSurface,
            size: 22,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        for (final order in orders) ...[
          _buildOrderCard(order),
          if (order != orders.last) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(radius: 22),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB45A5A),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFFB45A5A),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loadOrders,
            child: Text(
              'Coba lagi',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(radius: 22),
      child: Text(
        'Belum ada pesanan dalam kategori ini.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildOrderCard(BersihuyOrder order) {
    final statusLabel = _statusLabel(order.status);
    final statusColor = _statusColor(order.status);
    final scheduleText = order.scheduleDate != null
        ? '${order.formattedScheduleDate}${order.scheduleTime != null ? ', ${order.scheduleTime}' : ''}'
        : '-';
    final cta = _ctaForStatus(order.status);
    final isPrimaryCta = cta == _OrderCta.track || cta == _OrderCta.payment;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _serviceIcon(null),
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scheduleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(statusLabel, statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          _metaRow(Icons.location_on_outlined, order.serviceAddress),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.formattedTotal,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (order.status == 'completed')
                _buildCompletedActions(order, scheduleText)
              else
                ElevatedButton(
                  onPressed: () {
                    final orderId = order.id?.trim();
                    if (cta == _OrderCta.payment) {
                      _openPayment(orderId);
                    } else if (cta == _OrderCta.track) {
                      _openTracking(orderId);
                    } else if (cta == _OrderCta.invoice) {
                      _openInvoice(order, scheduleText);
                    } else {
                      Navigator.pushNamed(context, AppRoutes.customerServices);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPrimaryCta
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.08),
                    foregroundColor: isPrimaryCta
                        ? Colors.white
                        : AppColors.primary,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    cta.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isPrimaryCta ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedActions(BersihuyOrder order, String scheduleText) {
    final orderId = order.id?.trim();
    final hasReview = orderId != null && _reviewedOrderIds.contains(orderId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: hasReview
              ? () => _openReviewDetail(order)
              : () {
                  if (orderId == null || orderId.isEmpty) {
                    _showMissingOrderId('ulasan');
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    AppRoutes.ratingReview,
                    arguments: {'orderId': orderId},
                  ).then((_) => _loadOrders());
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          ),
          child: Text(
            hasReview ? 'Lihat Ulasan' : 'Beri Rating',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _openInvoice(order, scheduleText),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          ),
          child: Text(
            'Lihat Invoice',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openReviewDetail(BersihuyOrder order) async {
    final orderId = order.id?.trim();
    if (orderId == null || orderId.isEmpty) {
      _showMissingOrderId('ulasan');
      return;
    }

    CustomerReview? review = _reviewsByOrderId[orderId];
    if (review == null) {
      try {
        review = await _repository.getReviewForOrder(orderId);
        if (review != null && mounted) {
          setState(() {
            _reviewedOrderIds = {..._reviewedOrderIds, orderId};
            _reviewsByOrderId = {..._reviewsByOrderId, orderId: review!};
          });
        }
      } catch (e) {
        debugPrint('ORDERS REVIEW DETAIL ERROR ($orderId): $e');
      }
    }

    if (!mounted) return;
    if (review == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ulasan tidak ditemukan.')));
      return;
    }

    _showReviewDetail(review, order);
  }

  void _showReviewDetail(CustomerReview review, BersihuyOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ulasan Kamu',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      final filled = index < review.rating;
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: filled
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        size: 24,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${review.rating}/5',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _reviewDetailRow(
                  'Pesanan',
                  review.orderNumber ?? order.orderNumber,
                ),
                _reviewDetailRow(
                  'Layanan',
                  review.serviceName ?? order.serviceName,
                ),
                _reviewDetailRow(
                  'Petugas',
                  review.staffName ?? 'Data petugas belum tersedia',
                ),
                _reviewDetailRow('Tanggal', _formatDate(review.createdAt)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    review.comment.trim().isEmpty
                        ? 'Tidak ada komentar.'
                        : review.comment.trim(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reviewDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
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
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  void _openTracking(String? orderId) {
    debugPrint('CustomerOrdersScreen Lacak Pesanan orderId=$orderId');
    if (orderId == null || orderId.isEmpty) {
      _showMissingOrderId('pelacakan');
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.orderTracking,
      arguments: {'orderId': orderId},
    );
  }

  void _openPayment(String? orderId) {
    debugPrint('CustomerOrdersScreen continue payment orderId=$orderId');
    if (orderId == null || orderId.isEmpty) {
      _showMissingOrderId('pembayaran');
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.payment,
      arguments: {'orderId': orderId},
    ).then((_) => _loadOrders());
  }

  void _openInvoice(BersihuyOrder order, String scheduleText) {
    final orderId = order.id?.trim();
    debugPrint('CustomerOrdersScreen open invoice orderId=$orderId');
    if (orderId == null || orderId.isEmpty) {
      _showMissingOrderId('invoice');
      return;
    }
    final serviceItem = order.orderItems
        .where((item) => item.itemType == 'service')
        .firstOrNull;
    Navigator.pushNamed(
      context,
      AppRoutes.invoice,
      arguments: {
        'orderId': orderId,
        'orderNumber': order.orderNumber,
        'serviceName': order.serviceName,
        'servicePrice': serviceItem?.totalPrice ?? order.subtotalAmount,
        'serviceDuration': '-',
        'adminFee': order.adminFee,
        'selectedScentName': order.selectedScent,
        'selectedAddOns': <Map<String, Object>>[],
        'total': order.totalAmount,
        'schedule': scheduleText,
        'location': order.serviceAddress,
      },
    );
  }

  void _showMissingOrderId(String target) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ID kosong saat membuka $target.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
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
      'cancelled' => AppColors.error,
      'completed' => const Color(0xFF2E7D32),
      'scheduled' || 'paid' => const Color(0xFF9A6A00),
      _ => AppColors.primary,
    };
  }

  _OrderCta _ctaForStatus(String status) {
    return switch (status) {
      'created' || 'pending_payment' => _OrderCta.payment,
      'completed' => _OrderCta.invoice,
      'cancelled' => _OrderCta.reorder,
      _ => _OrderCta.track,
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
}

class _PremiumCustomerBackground extends StatelessWidget {
  final Widget child;

  const _PremiumCustomerBackground({required this.child});

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

enum _OrderCta {
  payment('Lanjutkan Pembayaran'),
  track('Lacak Pesanan'),
  invoice('Lihat Invoice'),
  reorder('Pesan Lagi');

  final String label;

  const _OrderCta(this.label);
}
