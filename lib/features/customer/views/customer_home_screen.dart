import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/bersihuy_data_service.dart';
import '../../../shared/widgets/customer_bottom_nav.dart';
import '../repositories/order_repository.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedCategoryIndex = 0;
  bool _showAllActiveOrders = false;

  // ── Real active orders from Supabase ──────────────────────────────────────
  List<BersihuyOrder> _activeOrders = [];
  bool _ordersLoading = true;
  String? _ordersError;
  // Lazy-loaded order items per orderId (fetched safely, never breaks home)
  final Map<String, List<BersihuyOrderItem>> _orderItemsCache = {};
  bool _itemsLoaded = false;

  // ── Popular services (from local data) ───────────────────────────────────
  List<BersihuyService> _popularServices = [];
  bool _popularServicesLoading = true;
  String? _popularServicesError;

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
    _loadPopularServices();
  }

  Future<void> _loadActiveOrders() async {
    if (!mounted) return;
    debugPrint('HOME ACTIVE LOAD START');
    setState(() {
      _ordersLoading = true;
      _ordersError = null;
    });

    try {
      final orders = await const OrderRepository().getActiveOrders();
      debugPrint('HOME ACTIVE CORE FETCH SUCCESS count=${orders.length}');

      if (!mounted) return;
      setState(() {
        _activeOrders = orders;
      });

      // Lazily load order items for service name (non-blocking, safe)
      _loadOrderItemsForOrders(orders);
    } catch (e, st) {
      debugPrint('HOME ACTIVE LOAD ERROR: $e');
      debugPrint('HOME ACTIVE LOAD STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _ordersError = 'Gagal memuat pesanan aktif.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _ordersLoading = false;
        });
        debugPrint('HOME ACTIVE LOAD FINALLY loading=false');
      }
    }
  }

  /// Lazily loads order items for orders that need them (service name).
  /// Safe to call — does not throw, does not break the home screen.
  Future<void> _loadOrderItemsForOrders(List<BersihuyOrder> orders) async {
    final loaded = _itemsLoaded;
    if (loaded) return;
    _itemsLoaded = true;

    for (final order in orders) {
      final orderId = order.id;
      if (orderId == null || orderId.trim().isEmpty) continue;
      if (_orderItemsCache.containsKey(orderId)) continue;

      try {
        final items =
            await const OrderRepository().loadOrderItemsForHome(orderId);
        if (!mounted) return;
        if (items.isNotEmpty) {
          // Update order.orderItems so serviceName getter works
          order.orderItems = items;
          setState(() {
            _orderItemsCache[orderId] = items;
          });
        }
      } catch (e) {
        debugPrint('HOME ORDER ITEMS LOAD ERROR orderId=$orderId: $e');
        // safe — continue to next order
      }
    }
  }

  Future<void> _loadPopularServices() async {
    if (!mounted) return;
    setState(() {
      _popularServicesLoading = true;
      _popularServicesError = null;
    });
    try {
      final services = await BersihuyDataService.getPopularServices(limit: 4);
      if (!mounted) return;
      setState(() {
        _popularServices = services;
        _popularServicesLoading = false;
      });
    } catch (e, st) {
      debugPrint('CustomerHomeScreen: failed to load popular services — $e');
      debugPrint('CustomerHomeScreen popular services stacktrace: $st');
      if (!mounted) return;
      setState(() {
        _popularServicesError = 'Gagal memuat layanan populer.';
        _popularServicesLoading = false;
      });
    }
  }

  static const _categories = ['Semua', 'Kos', 'Rumah', 'Kantor', 'Khusus'];

  // ── Compute category for an order based on service name heuristics ───────
  // Falls back to 'Rumah' when no order_items data is available to hint.
  String _categoryForOrder(BersihuyOrder order) {
    final name = order.serviceName.toLowerCase();
    if (name.contains('kos')) return 'Kos';
    if (name.contains('kantor') || name.contains('office')) return 'Kantor';
    return 'Rumah';
  }

  List<BersihuyOrder> get _visibleActiveOrders {
    final category = _categories[_selectedCategoryIndex];
    if (category == 'Semua') {
      return _activeOrders;
    }
    return _activeOrders
        .where((o) => _categoryForOrder(o) == category)
        .toList();
  }

  // ── Status label ───────────────────────────────────────────────────────────
  String _statusLabel(String status) {
    return switch (status) {
      'created' => 'Dibuat',
      'pending_payment' => 'Menunggu Pembayaran',
      'paid' => 'Dibayar',
      'scheduled' => 'Dijadwalkan',
      'in_progress' => 'Dalam Proses',
      'completed' => 'Selesai',
      'cancelled' => 'Dibatalkan',
      'complained' => 'Komplain',
      _ => status,
    };
  }

  static const _featuredProduct = _ProductItem(
    title: 'Bersihuy Aroma Diffuser',
    price: 'Rp199.000',
    imagePath: 'assets/images/products/bersihuy_aroma_diffuser.png',
    description: 'Bikin ruangan tetap segar setelah dibersihkan.',
  );

  void _openServices() {
    Navigator.pushNamed(context, AppRoutes.customerServices);
  }

  void _openBersihuyPlus() {
    Navigator.pushNamed(context, AppRoutes.bersihuyPlus);
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 104),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMembershipBanner(),
                          const SizedBox(height: 24),
                          Text(
                            'Halo, Fathan',
                            style: AppTextStyles.headlineLarge.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF142232),
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mau bersihin apa hari ini?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF65737D),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildPromoCard(),
                          const SizedBox(height: 24),
                          _buildCategoriesSection(),
                          const SizedBox(height: 22),
                          _buildActiveOrderSection(),
                          const SizedBox(height: 24),
                          _buildPopularServicesSection(),
                          const SizedBox(height: 24),
                          _buildFeaturedProductSection(),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: const CustomerBottomNav(currentIndex: 0),
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
        errorBuilder: (context, error, stackTrace) => const Text(
          'Bersihuy',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.customerNotifications);
          },
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: Color(0xFF172331),
            size: 22,
          ),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEAF7F5),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildPromoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F8F8A), Color(0xFF45BDB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F8F8A).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -34,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bersih kos jadi lebih mudah',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pesan layanan kebersihan hanya dalam beberapa langkah',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _openServices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF287A76),
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Pesan Sekarang',
                    style: AppTextStyles.buttonLabel.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF287A76),
                      letterSpacing: 0,
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

  Widget _buildMembershipBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerHeight = constraints.maxWidth >= 420 ? 168.0 : 156.0;

        return Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF247D78).withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/promos/bersihuy_plus_membership_banner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFEAF7F5),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF2F8F8A),
                        size: 52,
                      ),
                    );
                  },
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openBersihuyPlus,
                  splashColor: Colors.white.withValues(alpha: 0.16),
                  highlightColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = index == _selectedCategoryIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                }
              },
              labelStyle: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF65737D),
              ),
              selectedColor: const Color(0xFF2F8F8A),
              backgroundColor: const Color(0xFFFEFFFF),
              showCheckmark: false,
              elevation: isSelected ? 1 : 0,
              shadowColor: const Color(0xFF247D78).withValues(alpha: 0.08),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF2F8F8A)
                    : const Color(0xFFDDE8E6).withValues(alpha: 0.84),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveOrderSection() {
    final orders = _visibleActiveOrders;
    final displayedOrders = _showAllActiveOrders
        ? orders
        : orders.take(1).toList();
    final canToggle = orders.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pesanan Aktif',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: const Color(0xFF142232),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (canToggle)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllActiveOrders = !_showAllActiveOrders;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  _showAllActiveOrders
                      ? 'Tampilkan Lebih Sedikit'
                      : 'Tampilkan Semua',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_ordersLoading)
          _buildLoadingActiveOrder()
        else if (_ordersError != null)
          _buildErrorActiveOrder(_ordersError!)
        else if (displayedOrders.isEmpty)
          _buildEmptyActiveOrder()
        else
          Column(
            children: [
              for (final order in displayedOrders) ...[
                _buildActiveOrderCard(order),
                if (order != displayedOrders.last) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildLoadingActiveOrder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(radius: 22),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _buildErrorActiveOrder(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loadActiveOrders,
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

  Widget _buildEmptyActiveOrder() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: Text(
        'Belum ada pesanan aktif untuk kategori ini.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          color: const Color(0xFF65737D),
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(BersihuyOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFDDE8E6).withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    _orderIcon(_categoryForOrder(order)),
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
                        order.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.orderNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _activeStatusBadge(_statusLabel(order.status)),
              ],
            ),
            const SizedBox(height: 16),
            _buildActiveOrderMetaRow(
              Icons.schedule_rounded,
              _formatSchedule(order),
            ),
            const SizedBox(height: 8),
            _buildActiveOrderMetaRow(Icons.location_on_rounded, order.serviceAddress),
            const SizedBox(height: 8),
            _buildActiveOrderMetaRow(
              Icons.person_rounded,
              order.assignedStaffName != null && order.assignedStaffName!.isNotEmpty
                  ? 'Petugas: ${order.assignedStaffName}'
                  : 'Menunggu penugasan',
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                final orderId = order.id;
                debugPrint('CustomerHomeScreen Lihat Detail orderId=$orderId');
                if (orderId == null || orderId.trim().isEmpty) {
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
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size.fromHeight(42),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Detail',
                    style: AppTextStyles.buttonLabel.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSchedule(BersihuyOrder order) {
    final date = order.scheduleDate;
    final time = order.scheduleTime;
    if (date == null && (time == null || time.isEmpty)) {
      return 'Belum dijadwalkan';
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dateStr = date != null
        ? '${date.day} ${months[date.month - 1]} ${date.year}'
        : null;
    if (dateStr != null && time != null && time.isNotEmpty) {
      return '$dateStr, $time';
    }
    return dateStr ?? time ?? 'Belum dijadwalkan';
  }

  Widget _activeStatusBadge(String text) {
    final isWaiting = text == 'Menunggu Jadwal';
    final isScheduled = text == 'Dijadwalkan';
    final backgroundColor = isWaiting
        ? const Color(0xFFFFF4D8)
        : isScheduled
        ? const Color(0xFFEFF3F7)
        : AppColors.primary.withValues(alpha: 0.1);
    final textColor = isWaiting
        ? const Color(0xFF9A6A00)
        : isScheduled
        ? AppColors.onSurfaceVariant
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActiveOrderMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  IconData _orderIcon(String category) {
    return switch (category) {
      'Kos' => Icons.single_bed_outlined,
      'Khusus' => Icons.yard_outlined,
      'Kantor' => Icons.apartment_outlined,
      _ => Icons.cleaning_services_outlined,
    };
  }

  Widget _buildPopularServicesSection() {
    if (_popularServicesLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layanan Populer',
            style: AppTextStyles.headlineSmall.copyWith(
              color: const Color(0xFF142232),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionState(
            icon: Icons.hourglass_empty_rounded,
            message: 'Memuat layanan populer...',
          ),
        ],
      );
    }

    if (_popularServicesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layanan Populer',
            style: AppTextStyles.headlineSmall.copyWith(
              color: const Color(0xFF142232),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionState(
            icon: Icons.error_outline_rounded,
            message: _popularServicesError!,
            onTap: _loadPopularServices,
          ),
        ],
      );
    }

    if (_popularServices.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layanan Populer',
            style: AppTextStyles.headlineSmall.copyWith(
              color: const Color(0xFF142232),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionState(
            icon: Icons.cleaning_services_outlined,
            message: 'Belum ada layanan populer tersedia.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Populer',
          style: AppTextStyles.headlineSmall.copyWith(
            color: const Color(0xFF142232),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 0.76,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          children: _popularServices.map(_buildServiceCard).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionState({
    required IconData icon,
    required String message,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(radius: 22),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BersihuyService service) {
    return InkWell(
      onTap: () {
        debugPrint(
          'CustomerHomeScreen popular service tap: '
          'id=${service.id}, name=${service.name}',
        );
        Navigator.pushNamed(
          context,
          AppRoutes.serviceDetail,
          arguments: {
            'serviceId': service.id,
            'id': service.id,
            'title': service.name,
            'category': service.category ?? '',
            'description': service.description ?? '',
            'price': service.formattedPrice,
            'duration': service.formattedDuration,
            'rating': service.formattedRating,
            'imagePath': service.imageAssetPath ?? '',
          },
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: _cardDecoration(radius: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        service.imageAssetPath != null &&
                                service.imageAssetPath!.isNotEmpty
                            ? service.imageAssetPath!
                            : 'assets/images/services/placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFEAF7F5),
                            child: const Icon(
                              Icons.cleaning_services_outlined,
                              color: Color(0xFF2F8F8A),
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _ratingChip(service.formattedRating),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF172331),
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              service.formattedDuration,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 11,
                                color: const Color(0xFF65737D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        service.formattedPrice,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF287A76),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produk Populer',
          style: AppTextStyles.headlineSmall.copyWith(
            color: const Color(0xFF142232),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _cardDecoration(radius: 22),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: 122,
                height: 146,
                child: Image.asset(
                  _featuredProduct.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFEAF7F5),
                      child: const Icon(
                        Icons.spa_outlined,
                        color: Color(0xFF2F8F8A),
                        size: 34,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _featuredProduct.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF172331),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _featuredProduct.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF65737D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _featuredProduct.price,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF287A76),
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _openServices,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F8F8A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Lihat Produk',
                          style: AppTextStyles.buttonLabel.copyWith(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ratingChip(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Color(0xFFFFB400)),
          const SizedBox(width: 2),
          Text(
            rating,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172331),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: const Color(0xFFFEFFFF),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFFDDE8E6).withValues(alpha: 0.72),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF247D78).withValues(alpha: 0.055),
          blurRadius: 20,
          offset: const Offset(0, 9),
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

class _ProductItem {
  final String title;
  final String price;
  final String imagePath;
  final String description;

  const _ProductItem({
    required this.title,
    required this.price,
    required this.imagePath,
    required this.description,
  });
}
