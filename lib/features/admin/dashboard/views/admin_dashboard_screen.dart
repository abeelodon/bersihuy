import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/supabase_service.dart';
import '../repositories/admin_dashboard_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repository = const AdminDashboardRepository();
  late Future<AdminDashboardData> _dashboardFuture;

  _AdminSection _section = _AdminSection.dashboard;
  _AdminOrderFilter _orderFilter = _AdminOrderFilter.all;
  _ComplaintFilter _complaintFilter = _ComplaintFilter.all;
  _CatalogTab _catalogTab = _CatalogTab.services;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _repository.loadDashboard();
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = _repository.loadDashboard();
    });
  }

  void _selectSection(_AdminSection section) {
    setState(() {
      _section = section;
      _query = '';
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Admin Panel?'),
        content: const Text(
          'Sesi admin akan diakhiri dan Anda kembali ke halaman login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: _primaryActionStyle(),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _openAssignDialog(AdminOrderRow order) async {
    final assigned = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AssignStaffDialog(order: order, repository: _repository);
      },
    );

    if (assigned == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Petugas berhasil ditugaskan.')),
      );
      _refreshDashboard();
    }
  }

  void _openOrderDetail(AdminOrderRow order) {
    showDialog<void>(
      context: context,
      builder: (context) => _OrderDetailDialog(order: order),
    );
  }

  void _openStaffDetail(AdminStaffProfile staff) {
    showDialog<void>(
      context: context,
      builder: (context) => _StaffDetailDialog(staff: staff),
    );
  }

  void _openServiceDetail(AdminServiceItem service) {
    showDialog<void>(
      context: context,
      builder: (context) => _CatalogDetailDialog.service(service),
    );
  }

  void _openProductDetail(AdminProductItem product) {
    showDialog<void>(
      context: context,
      builder: (context) => _CatalogDetailDialog.product(product),
    );
  }

  Future<void> _openComplaintDetail(AdminComplaintRow complaint) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _ComplaintDetailDialog(complaint: complaint, repository: _repository),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keluhan berhasil diperbarui.')),
      );
      _refreshDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useSidebar = constraints.maxWidth >= 980;
            return FutureBuilder<AdminDashboardData>(
              future: _dashboardFuture,
              builder: (context, snapshot) {
                final adminName = snapshot.data?.adminName ?? 'Admin';
                final content = _buildMainContent(
                  snapshot: snapshot,
                  adminName: adminName,
                  useSidebar: useSidebar,
                );

                if (!useSidebar) {
                  return Column(
                    children: [
                      _AdminTopNav(
                        selected: _section,
                        onSelect: _selectSection,
                      ),
                      Expanded(child: content),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AdminSidebar(
                      selected: _section,
                      adminName: adminName,
                      onSelect: _selectSection,
                    ),
                    Expanded(child: content),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent({
    required AsyncSnapshot<AdminDashboardData> snapshot,
    required String adminName,
    required bool useSidebar,
  }) {
    final isLoading = snapshot.connectionState == ConnectionState.waiting;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        useSidebar ? 28 : 18,
        useSidebar ? 24 : 18,
        useSidebar ? 30 : 18,
        36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(adminName),
              const SizedBox(height: 20),
              if (isLoading && !snapshot.hasData)
                const _LoadingPanel()
              else if (snapshot.hasError && !snapshot.hasData)
                _ErrorPanel(onRetry: _refreshDashboard)
              else ...[
                if (snapshot.data!.warnings.isNotEmpty) ...[
                  _DataWarningBanner(warnings: snapshot.data!.warnings),
                  const SizedBox(height: 14),
                ],
                _buildSection(snapshot.data!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String adminName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _section.label,
              style: AppTextStyles.headlineLarge.copyWith(
                color: _Palette.navy,
                fontSize: compact ? 24 : 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _section.subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _Palette.muted,
                fontSize: 13,
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 9,
          runSpacing: 9,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? math.min(constraints.maxWidth, 300) : 240,
              height: 42,
              child: TextField(
                key: ValueKey(_section),
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
                style: const TextStyle(fontSize: 13, color: _Palette.navy),
                decoration: InputDecoration(
                  hintText: 'Cari di ${_section.label.toLowerCase()}',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: _Palette.muted,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: _Palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _refreshDashboard,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              style: IconButton.styleFrom(
                minimumSize: const Size(42, 42),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: _Palette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded, size: 17),
              label: const Text('Keluar'),
              style: _secondaryActionStyle(),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 15), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 18),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildSection(AdminDashboardData data) {
    return switch (_section) {
      _AdminSection.dashboard => _buildDashboard(data),
      _AdminSection.analytics => _buildAnalytics(data),
      _AdminSection.orders => _buildOrders(data.orders),
      _AdminSection.staff => _buildStaff(data.staff),
      _AdminSection.catalog => _buildCatalog(data),
      _AdminSection.complaints => _buildComplaints(data.complaints),
      _AdminSection.settings => _buildSettings(data),
    };
  }

  Widget _buildDashboard(AdminDashboardData data) {
    final summary = data.summary;
    final stats = [
      _StatItem(
        label: 'Total Pesanan',
        value: '${summary.totalOrders}',
        helper: 'Seluruh pesanan',
        icon: Icons.receipt_long_rounded,
        tone: _Tone.teal,
      ),
      _StatItem(
        label: 'Pesanan Hari Ini',
        value: '${summary.todayOrders}',
        helper: 'Aktivitas hari ini',
        icon: Icons.today_rounded,
        tone: _Tone.blue,
      ),
      _StatItem(
        label: 'Menunggu Penugasan',
        value: '${summary.waitingAssignment}',
        helper: 'Perlu ditindaklanjuti',
        icon: Icons.assignment_late_outlined,
        tone: _Tone.amber,
      ),
      _StatItem(
        label: 'Dalam Proses',
        value: '${summary.inProgress}',
        helper: 'Sedang dikerjakan',
        icon: Icons.cleaning_services_outlined,
        tone: _Tone.blue,
      ),
      _StatItem(
        label: 'Selesai',
        value: '${summary.completed}',
        helper: 'Tugas selesai',
        icon: Icons.task_alt_rounded,
        tone: _Tone.green,
      ),
      _StatItem(
        label: 'Keluhan Terbuka',
        value: '${summary.openComplaints}',
        helper: 'Perlu review',
        icon: Icons.support_agent_rounded,
        tone: _Tone.red,
      ),
      _StatItem(
        label: 'Revenue Bulan Ini',
        value: formatAdminRupiah(summary.monthlyRevenue),
        helper: 'Pembayaran tercatat',
        icon: Icons.account_balance_wallet_outlined,
        tone: _Tone.teal,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minCardWidth: 205,
          maxColumns: 4,
          children: [for (final stat in stats) _StatCard(item: stat)],
        ),
        const SizedBox(height: 16),
        _ResponsiveSplit(
          primaryFlex: 7,
          secondaryFlex: 4,
          primary: _TrendCard(
            title: 'Tren Pesanan',
            subtitle: 'Volume pesanan 7 hari terakhir',
            points: data.trends,
            valueSelector: (point) => point.orders.toDouble(),
            valueLabel: (point) => '${point.orders}',
            accent: AppColors.primary,
          ),
          secondary: _StatusDistributionCard(summary: summary),
        ),
        const SizedBox(height: 16),
        _ResponsiveSplit(
          primary: _RankCard(
            title: 'Layanan Terlaris',
            subtitle: 'Berdasarkan item pesanan',
            items: data.topServices,
            emptyText: 'Belum ada data layanan.',
            icon: Icons.cleaning_services_rounded,
          ),
          secondary: _RankCard(
            title: 'Produk / Add-on Terlaris',
            subtitle: 'Produk tambahan yang paling sering dipilih',
            items: data.topProducts,
            emptyText: 'Belum ada data add-on.',
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _RecentOrdersCard(
          orders: _searchOrders(data.orders).take(5).toList(),
          onDetail: _openOrderDetail,
        ),
      ],
    );
  }

  Widget _buildAnalytics(AdminDashboardData data) {
    final summary = data.summary;
    final stats = [
      _StatItem(
        label: 'Total Revenue',
        value: formatAdminRupiah(summary.totalRevenue),
        helper: 'Pesanan terbayar',
        icon: Icons.payments_outlined,
        tone: _Tone.teal,
      ),
      _StatItem(
        label: 'Total Order',
        value: '${summary.totalOrders}',
        helper: 'Semua periode',
        icon: Icons.shopping_bag_outlined,
        tone: _Tone.blue,
      ),
      _StatItem(
        label: 'Rata-rata Order',
        value: formatAdminRupiah(summary.averageOrderValue),
        helper: 'Average order value',
        icon: Icons.trending_up_rounded,
        tone: _Tone.green,
      ),
      _StatItem(
        label: 'Order Selesai',
        value: '${summary.completed}',
        helper: 'Operasional selesai',
        icon: Icons.verified_outlined,
        tone: _Tone.green,
      ),
      _StatItem(
        label: 'Rating Rata-rata',
        value: summary.averageRating == 0
            ? '-'
            : summary.averageRating.toStringAsFixed(1),
        helper: 'Dari ulasan customer',
        icon: Icons.star_outline_rounded,
        tone: _Tone.amber,
      ),
      _StatItem(
        label: 'Keluhan Terbuka',
        value: '${summary.openComplaints}',
        helper: 'Butuh tindak lanjut',
        icon: Icons.report_gmailerrorred_rounded,
        tone: _Tone.red,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minCardWidth: 210,
          maxColumns: 3,
          children: [for (final stat in stats) _StatCard(item: stat)],
        ),
        const SizedBox(height: 16),
        _ResponsiveSplit(
          primaryFlex: 7,
          secondaryFlex: 4,
          primary: _TrendCard(
            title: 'Revenue Mingguan',
            subtitle: 'Nilai transaksi 7 hari terakhir',
            points: data.trends,
            valueSelector: (point) => point.revenue.toDouble(),
            valueLabel: (point) => _compactMoney(point.revenue),
            accent: const Color(0xFF3CB9A8),
          ),
          secondary: _StatusDistributionCard(summary: summary),
        ),
        const SizedBox(height: 16),
        _ResponsiveSplit(
          primary: _RankCard(
            title: 'Kontribusi Layanan',
            subtitle: 'Peringkat layanan berdasarkan volume',
            items: data.topServices,
            emptyText: 'Data layanan belum tersedia.',
            icon: Icons.auto_graph_rounded,
          ),
          secondary: _RankCard(
            title: 'Kontribusi Add-on',
            subtitle: 'Peringkat produk berdasarkan penjualan',
            items: data.topProducts,
            emptyText: 'Data add-on belum tersedia.',
            icon: Icons.stacked_bar_chart_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _ResponsiveSplit(
          primaryFlex: 6,
          secondaryFlex: 5,
          primary: _StaffPerformanceCard(staff: _searchStaff(data.staff)),
          secondary: _QualityCard(
            complaints: data.complaints,
            averageRating: summary.averageRating,
            onOpenComplaint: _openComplaintDetail,
          ),
        ),
      ],
    );
  }

  Widget _buildOrders(List<AdminOrderRow> orders) {
    final visibleOrders = _filteredOrders(_searchOrders(orders));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionIntro(
          title: 'Operasional Pesanan',
          subtitle: '${orders.length} pesanan tersinkron dari Supabase',
          trailing: const _LiveDataPill(),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in _AdminOrderFilter.values)
              _FilterButton(
                label: '${filter.label} (${_orderFilterCount(filter, orders)})',
                selected: _orderFilter == filter,
                onTap: () => setState(() => _orderFilter = filter),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (visibleOrders.isEmpty)
          const _PremiumEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Tidak ada pesanan',
            body: 'Belum ada pesanan yang cocok dengan filter dan pencarian.',
          )
        else
          _ResponsiveGrid(
            minCardWidth: 410,
            maxColumns: 2,
            children: [
              for (final order in visibleOrders)
                _OrderCard(
                  order: order,
                  onDetail: () => _openOrderDetail(order),
                  onAssign: () => _openAssignDialog(order),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildStaff(List<AdminStaffProfile> staff) {
    final visibleStaff = _searchStaff(staff);
    final activeCount = staff.where((person) => person.isActive).length;
    final completed = staff.fold<int>(
      0,
      (total, person) => total + person.completedTasks,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minCardWidth: 220,
          maxColumns: 3,
          children: [
            _StatCard(
              item: _StatItem(
                label: 'Total Petugas',
                value: '${staff.length}',
                helper: 'Profil role staff',
                icon: Icons.groups_rounded,
                tone: _Tone.teal,
              ),
            ),
            _StatCard(
              item: _StatItem(
                label: 'Petugas Aktif',
                value: '$activeCount',
                helper: 'Siap menerima tugas',
                icon: Icons.person_pin_circle_outlined,
                tone: _Tone.green,
              ),
            ),
            _StatCard(
              item: _StatItem(
                label: 'Tugas Diselesaikan',
                value: '$completed',
                helper: 'Akumulasi tim',
                icon: Icons.task_alt_rounded,
                tone: _Tone.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionIntro(
          title: 'Tim Operasional',
          subtitle: 'Data profil, area, shift, dan performa petugas',
          trailing: Text(
            '${visibleStaff.length} petugas',
            style: _smallStrongText(color: _Palette.muted),
          ),
        ),
        const SizedBox(height: 14),
        if (visibleStaff.isEmpty)
          const _PremiumEmptyState(
            icon: Icons.group_off_outlined,
            title: 'Petugas belum tersedia',
            body:
                'Profil staff belum tersedia atau tidak cocok dengan pencarian.',
          )
        else
          _ResponsiveGrid(
            minCardWidth: 330,
            maxColumns: 3,
            children: [
              for (final person in visibleStaff)
                _StaffCard(
                  staff: person,
                  onDetail: () => _openStaffDetail(person),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCatalog(AdminDashboardData data) {
    final services = data.services.where((item) {
      return _query.isEmpty ||
          item.name.toLowerCase().contains(_query) ||
          item.category.toLowerCase().contains(_query);
    }).toList();
    final products = data.products.where((item) {
      return _query.isEmpty ||
          item.name.toLowerCase().contains(_query) ||
          item.description.toLowerCase().contains(_query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionIntro(
          title: 'Katalog Bersihuy',
          subtitle: 'Kelola tampilan layanan dan produk tambahan',
          trailing: _SegmentedTabs(
            labels: const ['Layanan', 'Produk / Add-on'],
            selectedIndex: _catalogTab.index,
            onSelected: (index) {
              setState(() => _catalogTab = _CatalogTab.values[index]);
            },
          ),
        ),
        const SizedBox(height: 15),
        if (_catalogTab == _CatalogTab.services)
          if (services.isEmpty)
            const _PremiumEmptyState(
              icon: Icons.cleaning_services_outlined,
              title: 'Layanan belum tersedia',
              body: 'Data services belum tersedia atau tidak cocok.',
            )
          else
            _ResponsiveGrid(
              minCardWidth: 285,
              maxColumns: 3,
              children: [
                for (final service in services)
                  _CatalogCard(
                    imagePath: service.imageAssetPath,
                    fallbackIcon: Icons.cleaning_services_rounded,
                    title: service.name,
                    category: service.category,
                    price: formatAdminRupiah(service.price),
                    meta:
                        '${service.durationMinutes} menit  |  Rating ${service.rating == 0 ? '-' : service.rating.toStringAsFixed(1)}',
                    isActive: service.isActive,
                    onDetail: () => _openServiceDetail(service),
                  ),
              ],
            )
        else if (products.isEmpty)
          const _PremiumEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Produk belum tersedia',
            body: 'Data products belum tersedia atau tidak cocok.',
          )
        else
          _ResponsiveGrid(
            minCardWidth: 285,
            maxColumns: 3,
            children: [
              for (final product in products)
                _CatalogCard(
                  imagePath: product.imageAssetPath,
                  fallbackIcon: Icons.inventory_2_rounded,
                  title: product.name,
                  category: product.isAddon ? 'Add-on' : 'Produk',
                  price: formatAdminRupiah(product.price),
                  meta: product.isAddon
                      ? 'Produk tambahan layanan'
                      : 'Produk Bersihuy',
                  isActive: product.isActive,
                  onDetail: () => _openProductDetail(product),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildComplaints(List<AdminComplaintRow> complaints) {
    final visible = _filteredComplaints(complaints);
    final stats = [
      ('Keluhan Terbuka', 'open', _Tone.red, Icons.mark_email_unread_outlined),
      ('Dalam Review', 'in_review', _Tone.amber, Icons.manage_search_rounded),
      ('Selesai', 'resolved', _Tone.green, Icons.task_alt_rounded),
      ('Ditolak', 'rejected', _Tone.blue, Icons.block_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minCardWidth: 210,
          maxColumns: 4,
          children: [
            for (final stat in stats)
              _StatCard(
                item: _StatItem(
                  label: stat.$1,
                  value:
                      '${complaints.where((item) => item.status == stat.$2).length}',
                  helper: 'Status keluhan',
                  icon: stat.$4,
                  tone: stat.$3,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in _ComplaintFilter.values)
              _FilterButton(
                label:
                    '${filter.label} (${_complaintFilterCount(filter, complaints)})',
                selected: _complaintFilter == filter,
                onTap: () => setState(() => _complaintFilter = filter),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (visible.isEmpty)
          const _PremiumEmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'Tidak ada keluhan',
            body: 'Semua bersih. Belum ada keluhan pada filter ini.',
          )
        else
          _ResponsiveGrid(
            minCardWidth: 420,
            maxColumns: 2,
            children: [
              for (final complaint in visible)
                _ComplaintCard(
                  complaint: complaint,
                  onDetail: () => _openComplaintDetail(complaint),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSettings(AdminDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveSplit(
          primary: _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardHeading(
                  title: 'Profil Admin',
                  subtitle: 'Akun yang sedang aktif',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _InitialAvatar(
                      initials: _initials(data.admin.name),
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.admin.name,
                            style: _cardTitleText(fontSize: 17),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.admin.email,
                            style: _bodyText(color: _Palette.muted),
                          ),
                          const SizedBox(height: 8),
                          const _SoftBadge(
                            label: 'Administrator',
                            tone: _Tone.teal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded, size: 17),
                  label: const Text('Keluar dari akun'),
                  style: _secondaryActionStyle(),
                ),
              ],
            ),
          ),
          secondary: const _SettingsInfoCard(
            title: 'Business Settings',
            icon: Icons.storefront_outlined,
            rows: [
              ('Admin fee', 'Rp5.000'),
              ('Service area', 'Semarang'),
              ('Payment provider', 'Dummy / Midtrans later'),
              ('App mode', 'Development'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _ResponsiveSplit(
          primary: _SettingsInfoCard(
            title: 'Data & Security',
            icon: Icons.shield_outlined,
            rows: [
              ('Row Level Security', 'Aktif'),
              ('Supabase connection', 'Terhubung'),
              ('Frontend key', 'Anon key only'),
              ('Secret key', 'Tidak disimpan di aplikasi'),
            ],
          ),
          secondary: _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeading(
                  title: 'Status Sistem',
                  subtitle: 'Konfigurasi panel admin',
                ),
                SizedBox(height: 18),
                _SystemStatusRow(
                  icon: Icons.cloud_done_outlined,
                  label: 'Database',
                  value: 'Supabase connected',
                  tone: _Tone.green,
                ),
                SizedBox(height: 10),
                _SystemStatusRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Akses data',
                  value: 'RLS protected',
                  tone: _Tone.teal,
                ),
                SizedBox(height: 10),
                _SystemStatusRow(
                  icon: Icons.science_outlined,
                  label: 'Environment',
                  value: 'Development',
                  tone: _Tone.amber,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<AdminOrderRow> _searchOrders(List<AdminOrderRow> orders) {
    if (_query.isEmpty) return orders;
    return orders.where((order) {
      final haystack = [
        order.orderNumber,
        order.customerName,
        order.serviceName,
        order.assignmentLabel,
        order.address,
      ].join(' ').toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  List<AdminStaffProfile> _searchStaff(List<AdminStaffProfile> staff) {
    if (_query.isEmpty) return staff;
    return staff.where((person) {
      final haystack = [
        person.fullName,
        person.email ?? '',
        person.areaLabel,
        person.shiftLabel,
      ].join(' ').toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  List<AdminOrderRow> _filteredOrders(List<AdminOrderRow> orders) {
    return switch (_orderFilter) {
      _AdminOrderFilter.all => orders,
      _AdminOrderFilter.unassigned =>
        orders.where((order) => order.isUnassigned).toList(),
      _AdminOrderFilter.assigned =>
        orders.where((order) => order.isAssigned).toList(),
      _AdminOrderFilter.inProgress =>
        orders
            .where((order) => order.effectiveStatus == 'in_progress')
            .toList(),
      _AdminOrderFilter.completed =>
        orders.where((order) => order.effectiveStatus == 'completed').toList(),
      _AdminOrderFilter.cancelled =>
        orders.where((order) => order.status == 'cancelled').toList(),
    };
  }

  int _orderFilterCount(_AdminOrderFilter filter, List<AdminOrderRow> orders) {
    return switch (filter) {
      _AdminOrderFilter.all => orders.length,
      _AdminOrderFilter.unassigned =>
        orders.where((order) => order.isUnassigned).length,
      _AdminOrderFilter.assigned =>
        orders.where((order) => order.isAssigned).length,
      _AdminOrderFilter.inProgress =>
        orders.where((order) => order.effectiveStatus == 'in_progress').length,
      _AdminOrderFilter.completed =>
        orders.where((order) => order.effectiveStatus == 'completed').length,
      _AdminOrderFilter.cancelled =>
        orders.where((order) => order.status == 'cancelled').length,
    };
  }

  List<AdminComplaintRow> _filteredComplaints(
    List<AdminComplaintRow> complaints,
  ) {
    final searched = complaints.where((complaint) {
      if (_query.isEmpty) return true;
      final haystack = [
        complaint.orderNumber,
        complaint.customerName,
        complaint.serviceName,
        complaint.category,
        complaint.description,
      ].join(' ').toLowerCase();
      return haystack.contains(_query);
    });
    if (_complaintFilter == _ComplaintFilter.all) return searched.toList();
    return searched
        .where((complaint) => complaint.status == _complaintFilter.status)
        .toList();
  }

  int _complaintFilterCount(
    _ComplaintFilter filter,
    List<AdminComplaintRow> complaints,
  ) {
    if (filter == _ComplaintFilter.all) return complaints.length;
    return complaints
        .where((complaint) => complaint.status == filter.status)
        .length;
  }
}

class _Palette {
  static const background = Color(0xFFF2F8F7);
  static const sidebar = Color(0xFFFBFDFC);
  static const navy = Color(0xFF172535);
  static const muted = Color(0xFF6A7782);
  static const border = Color(0xFFDDEAE7);
  static const softMint = Color(0xFFEAF6F4);
}

enum _AdminSection {
  dashboard(
    'Dashboard',
    'Pantau operasional Bersihuy hari ini',
    Icons.dashboard_rounded,
  ),
  analytics(
    'Analytics',
    'Laporan performa layanan dan operasional Bersihuy',
    Icons.query_stats_rounded,
  ),
  orders(
    'Pesanan',
    'Kelola pesanan customer dan penugasan petugas',
    Icons.receipt_long_rounded,
  ),
  staff(
    'Petugas',
    'Kelola data dan performa petugas Bersihuy',
    Icons.groups_rounded,
  ),
  catalog(
    'Layanan & Produk',
    'Kelola katalog layanan dan produk tambahan Bersihuy',
    Icons.inventory_2_rounded,
  ),
  complaints(
    'Keluhan',
    'Pantau dan tindak lanjuti keluhan customer',
    Icons.support_agent_rounded,
  ),
  settings(
    'Settings',
    'Pengaturan admin dan konfigurasi aplikasi',
    Icons.settings_rounded,
  );

  final String label;
  final String subtitle;
  final IconData icon;

  const _AdminSection(this.label, this.subtitle, this.icon);
}

enum _AdminOrderFilter {
  all('Semua'),
  unassigned('Belum Ditugaskan'),
  assigned('Ditugaskan'),
  inProgress('Dalam Proses'),
  completed('Selesai'),
  cancelled('Dibatalkan');

  final String label;

  const _AdminOrderFilter(this.label);
}

enum _ComplaintFilter {
  all('Semua', null),
  open('Open', 'open'),
  inReview('In Review', 'in_review'),
  resolved('Resolved', 'resolved'),
  rejected('Rejected', 'rejected');

  final String label;
  final String? status;

  const _ComplaintFilter(this.label, this.status);
}

enum _CatalogTab { services, products }

enum _Tone { teal, blue, green, amber, red, neutral }

class _ToneColors {
  final Color foreground;
  final Color background;
  final Color border;

  const _ToneColors({
    required this.foreground,
    required this.background,
    required this.border,
  });
}

_ToneColors _toneColors(_Tone tone) {
  return switch (tone) {
    _Tone.teal => const _ToneColors(
      foreground: Color(0xFF247F78),
      background: Color(0xFFE5F5F2),
      border: Color(0xFFBDE4DE),
    ),
    _Tone.blue => const _ToneColors(
      foreground: Color(0xFF316FA8),
      background: Color(0xFFEAF2FB),
      border: Color(0xFFC7DCEF),
    ),
    _Tone.green => const _ToneColors(
      foreground: Color(0xFF2B7C52),
      background: Color(0xFFE9F6EE),
      border: Color(0xFFC7E7D3),
    ),
    _Tone.amber => const _ToneColors(
      foreground: Color(0xFFB57612),
      background: Color(0xFFFFF4DF),
      border: Color(0xFFEED39D),
    ),
    _Tone.red => const _ToneColors(
      foreground: Color(0xFFB34F43),
      background: Color(0xFFFFECE9),
      border: Color(0xFFEABEB8),
    ),
    _Tone.neutral => const _ToneColors(
      foreground: Color(0xFF65727C),
      background: Color(0xFFF2F5F5),
      border: Color(0xFFDDE6E4),
    ),
  };
}

class _AdminSidebar extends StatelessWidget {
  final _AdminSection selected;
  final String adminName;
  final ValueChanged<_AdminSection> onSelect;

  const _AdminSidebar({
    required this.selected,
    required this.adminName,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 242,
      decoration: const BoxDecoration(
        color: _Palette.sidebar,
        border: Border(right: BorderSide(color: _Palette.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: Image.asset(
                'assets/images/bersihuy_logo_wordmark.png',
                width: 150,
                alignment: Alignment.centerLeft,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: _Palette.softMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cleaning_services_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Bersihuy', style: _cardTitleText(fontSize: 19)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'MENU UTAMA',
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFF93A09F),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 9),
            for (final section in _AdminSection.values)
              _AdminNavButton(
                section: section,
                active: selected == section,
                compact: false,
                onTap: () => onSelect(section),
              ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _Palette.softMint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Palette.border),
              ),
              child: Row(
                children: [
                  _InitialAvatar(initials: _initials(adminName), size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _smallStrongText(color: _Palette.navy),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Admin Panel',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _Palette.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF47B881),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTopNav extends StatelessWidget {
  final _AdminSection selected;
  final ValueChanged<_AdminSection> onSelect;

  const _AdminTopNav({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _Palette.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Image.asset(
                'assets/images/bersihuy_logo_wordmark.png',
                width: 112,
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.cleaning_services_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
            for (final section in _AdminSection.values)
              _AdminNavButton(
                section: section,
                active: selected == section,
                compact: true,
                onTap: () => onSelect(section),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavButton extends StatelessWidget {
  final _AdminSection section;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  const _AdminNavButton({
    required this.section,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.primary : const Color(0xFF4F5D67);
    return Padding(
      padding: EdgeInsets.only(right: compact ? 7 : 0, bottom: compact ? 0 : 6),
      child: Material(
        color: active
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: compact ? null : double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 11 : 12,
              vertical: 11,
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(section.icon, color: foreground, size: 19),
                const SizedBox(width: 9),
                Text(
                  section.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final double minCardWidth;
  final int maxColumns;
  final List<Widget> children;

  const _ResponsiveGrid({
    required this.minCardWidth,
    required this.maxColumns,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 13.0;
        final possibleColumns =
            ((constraints.maxWidth + gap) / (minCardWidth + gap)).floor();
        final columns = math.max(1, math.min(maxColumns, possibleColumns));
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _ResponsiveSplit extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;

  const _ResponsiveSplit({
    required this.primary,
    required this.secondary,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 780) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: primary),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: secondary),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            const SizedBox(width: 14),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF287F79).withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final _Tone tone;

  const _StatItem({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.tone,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(item.tone);
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _smallStrongText(color: _Palette.muted),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(item.icon, color: colors.foreground, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 13),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: AppTextStyles.headlineLarge.copyWith(
                color: _Palette.navy,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: _Palette.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AdminTrendPoint> points;
  final double Function(AdminTrendPoint) valueSelector;
  final String Function(AdminTrendPoint) valueLabel;
  final Color accent;

  const _TrendCard({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.valueSelector,
    required this.valueLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(
      0,
      (current, point) => math.max(current, valueSelector(point)),
    );
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(title: title, subtitle: subtitle),
          const SizedBox(height: 22),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in points)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            valueLabel(point),
                            maxLines: 1,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _Palette.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: maxValue == 0
                                ? 8
                                : math.max(
                                    8,
                                    125 * valueSelector(point) / maxValue,
                                  ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  accent,
                                  accent.withValues(alpha: 0.35),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                                bottom: Radius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            point.dayLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _Palette.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

class _StatusDistributionCard extends StatelessWidget {
  final AdminDashboardSummary summary;

  const _StatusDistributionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = math.max(summary.totalOrders, 1);
    final rows = [
      ('Belum Ditugaskan', summary.waitingAssignment, _Tone.amber),
      ('Ditugaskan', summary.assigned, _Tone.blue),
      ('Dalam Proses', summary.inProgress, _Tone.teal),
      ('Selesai', summary.completed, _Tone.green),
    ];

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            title: 'Ringkasan Status',
            subtitle: 'Distribusi operasional pesanan',
          ),
          const SizedBox(height: 21),
          for (final row in rows) ...[
            _ProgressRow(
              label: row.$1,
              value: row.$2,
              progress: row.$2 / total,
              tone: row.$3,
            ),
            if (row != rows.last) const SizedBox(height: 17),
          ],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final double progress;
  final _Tone tone;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(tone);
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: _bodyText(color: _Palette.muted)),
            ),
            Text('$value', style: _smallStrongText(color: _Palette.navy)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: progress.clamp(0, 1),
            color: colors.foreground,
            backgroundColor: colors.background,
          ),
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AdminTopItem> items;
  final String emptyText;
  final IconData icon;

  const _RankCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.emptyText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _InlineEmpty(icon: icon, text: emptyText)
          else
            for (var index = 0; index < math.min(5, items.length); index++) ...[
              _RankRow(index: index, item: items[index], icon: icon),
              if (index < math.min(5, items.length) - 1)
                const Divider(height: 22, color: _Palette.border),
            ],
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int index;
  final AdminTopItem item;
  final IconData icon;

  const _RankRow({required this.index, required this.item, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: index == 0 ? _Palette.softMint : const Color(0xFFF4F7F7),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: index < 3
                ? Text(
                    '${index + 1}',
                    style: _smallStrongText(
                      color: index == 0 ? AppColors.primary : _Palette.muted,
                    ),
                  )
                : Icon(icon, size: 17, color: _Palette.muted),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _smallStrongText(color: _Palette.navy),
              ),
              const SizedBox(height: 3),
              Text(
                item.revenue == 0
                    ? '${item.count} dipesan'
                    : '${item.count} dipesan  |  ${formatAdminRupiah(item.revenue)}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: _Palette.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  final List<AdminOrderRow> orders;
  final ValueChanged<AdminOrderRow> onDetail;

  const _RecentOrdersCard({required this.orders, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            title: 'Pesanan Terbaru',
            subtitle: 'Aktivitas customer paling baru',
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            const _InlineEmpty(
              icon: Icons.receipt_long_outlined,
              text: 'Belum ada pesanan terbaru.',
            )
          else
            for (var index = 0; index < orders.length; index++) ...[
              _RecentOrderRow(order: orders[index], onDetail: onDetail),
              if (index < orders.length - 1)
                const Divider(height: 20, color: _Palette.border),
            ],
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  final AdminOrderRow order;
  final ValueChanged<AdminOrderRow> onDetail;

  const _RecentOrderRow({required this.order, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final identity = Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _Palette.softMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.orderNumber}  |  ${order.customerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _smallStrongText(color: _Palette.navy),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _bodyText(color: _Palette.muted),
                  ),
                ],
              ),
            ),
          ],
        );
        final trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(
              label: order.statusLabel,
              status: order.effectiveStatus,
            ),
            const SizedBox(width: 12),
            Text(
              order.totalLabel,
              style: _smallStrongText(color: _Palette.navy),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Detail',
              onPressed: () => onDetail(order),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              color: AppColors.primary,
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [identity, const SizedBox(height: 10), trailing],
          );
        }
        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 14),
            trailing,
          ],
        );
      },
    );
  }
}

class _SectionIntro extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionIntro({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _cardTitleText(fontSize: 17)),
              const SizedBox(height: 4),
              Text(subtitle, style: _bodyText(color: _Palette.muted)),
            ],
          );
          if (trailing == null) return heading;
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: 12), trailing!],
            );
          }
          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              trailing!,
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AdminOrderRow order;
  final VoidCallback onDetail;
  final VoidCallback onAssign;

  const _OrderCard({
    required this.order,
    required this.onDetail,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _cardTitleText(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyText(color: _Palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(
                label: order.statusLabel,
                status: order.effectiveStatus,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _PaymentBadge(
                label: order.paymentStatusLabel,
                status: order.paymentStatus ?? 'missing',
              ),
              _SoftBadge(
                label: order.assignmentLabel,
                tone: order.hasAssignedStaff ? _Tone.teal : _Tone.amber,
              ),
            ],
          ),
          const SizedBox(height: 15),
          _MetaRow(
            icon: Icons.cleaning_services_outlined,
            label: order.serviceName,
          ),
          _MetaRow(icon: Icons.event_rounded, label: order.scheduleLabel),
          _MetaRow(icon: Icons.location_on_outlined, label: order.address),
          _MetaRow(
            icon: Icons.payments_outlined,
            label: order.totalLabel,
            strong: true,
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onDetail,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Detail'),
                style: _secondaryActionStyle(),
              ),
              if (order.canAssign)
                FilledButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                  label: Text(
                    order.hasAssignedStaff ? 'Ubah Petugas' : 'Assign Petugas',
                  ),
                  style: _primaryActionStyle(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final AdminStaffProfile staff;
  final VoidCallback onDetail;

  const _StaffCard({required this.staff, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialAvatar(initials: staff.initials, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _cardTitleText(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      staff.email ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyText(color: _Palette.muted),
                    ),
                  ],
                ),
              ),
              _SoftBadge(
                label: staff.isActive ? 'Aktif' : 'Nonaktif',
                tone: staff.isActive ? _Tone.green : _Tone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _MetaPill(icon: Icons.map_outlined, label: staff.areaLabel),
              _MetaPill(icon: Icons.schedule_outlined, label: staff.shiftLabel),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Ditugaskan',
                  value: '${staff.assignedTasks}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Selesai',
                  value: '${staff.completedTasks}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Rating',
                  value: staff.averageRating == 0
                      ? '-'
                      : staff.averageRating.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDetail,
              icon: const Icon(Icons.person_search_outlined, size: 17),
              label: const Text('Lihat Detail'),
              style: _secondaryActionStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffPerformanceCard extends StatelessWidget {
  final List<AdminStaffProfile> staff;

  const _StaffPerformanceCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    final ranked = [...staff]
      ..sort((a, b) => b.completedTasks.compareTo(a.completedTasks));
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            title: 'Performa Petugas',
            subtitle: 'Ringkasan produktivitas tim',
          ),
          const SizedBox(height: 15),
          if (ranked.isEmpty)
            const _InlineEmpty(
              icon: Icons.groups_outlined,
              text: 'Data petugas belum tersedia.',
            )
          else
            for (
              var index = 0;
              index < math.min(5, ranked.length);
              index++
            ) ...[
              _StaffPerformanceRow(staff: ranked[index]),
              if (index < math.min(5, ranked.length) - 1)
                const Divider(height: 22, color: _Palette.border),
            ],
        ],
      ),
    );
  }
}

class _StaffPerformanceRow extends StatelessWidget {
  final AdminStaffProfile staff;

  const _StaffPerformanceRow({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InitialAvatar(initials: staff.initials, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staff.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _smallStrongText(color: _Palette.navy),
              ),
              const SizedBox(height: 3),
              Text(
                '${staff.completedTasks} selesai dari ${staff.assignedTasks} tugas',
                style: _bodyText(color: _Palette.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE5A62C)),
            const SizedBox(width: 3),
            Text(
              staff.averageRating == 0
                  ? '-'
                  : staff.averageRating.toStringAsFixed(1),
              style: _smallStrongText(color: _Palette.navy),
            ),
          ],
        ),
      ],
    );
  }
}

class _QualityCard extends StatelessWidget {
  final List<AdminComplaintRow> complaints;
  final double averageRating;
  final ValueChanged<AdminComplaintRow> onOpenComplaint;

  const _QualityCard({
    required this.complaints,
    required this.averageRating,
    required this.onOpenComplaint,
  });

  @override
  Widget build(BuildContext context) {
    final open = complaints
        .where(
          (complaint) =>
              complaint.status == 'open' || complaint.status == 'in_review',
        )
        .take(3)
        .toList();
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            title: 'Keluhan & Kualitas',
            subtitle: 'Sinyal kualitas layanan terbaru',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Rating Rata-rata',
                  value: averageRating == 0
                      ? '-'
                      : averageRating.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MetricBox(
                  label: 'Keluhan Aktif',
                  value: '${open.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (open.isEmpty)
            const _InlineEmpty(
              icon: Icons.verified_outlined,
              text: 'Tidak ada keluhan aktif.',
            )
          else
            for (var index = 0; index < open.length; index++) ...[
              InkWell(
                onTap: () => onOpenComplaint(open[index]),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.report_gmailerrorred_outlined,
                        size: 18,
                        color: Color(0xFFB34F43),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${open[index].orderNumber} - ${open[index].category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _bodyText(color: _Palette.navy),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _Palette.muted,
                      ),
                    ],
                  ),
                ),
              ),
              if (index < open.length - 1)
                const Divider(height: 16, color: _Palette.border),
            ],
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  final String title;
  final String category;
  final String price;
  final String meta;
  final bool isActive;
  final VoidCallback onDetail;

  const _CatalogCard({
    required this.imagePath,
    required this.fallbackIcon,
    required this.title,
    required this.category,
    required this.price,
    required this.meta,
    required this.isActive,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatalogThumbnail(imagePath: imagePath, fallbackIcon: fallbackIcon),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _cardTitleText(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(category, style: _bodyText(color: _Palette.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SoftBadge(
                label: isActive ? 'Aktif' : 'Nonaktif',
                tone: isActive ? _Tone.green : _Tone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(price, style: _cardTitleText(fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: _Palette.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDetail,
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Detail'),
              style: _secondaryActionStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogThumbnail extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;

  const _CatalogThumbnail({
    required this.imagePath,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cleanPath = imagePath?.trim();
    final assetPath = cleanPath == null || cleanPath.isEmpty
        ? null
        : cleanPath.startsWith('assets/')
        ? cleanPath
        : 'assets/images/$cleanPath';
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        height: 132,
        color: const Color(0xFFF0F6F5),
        child: assetPath == null
            ? Icon(fallbackIcon, color: AppColors.primary, size: 38)
            : Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(fallbackIcon, color: AppColors.primary, size: 38),
              ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final AdminComplaintRow complaint;
  final VoidCallback onDetail;

  const _ComplaintCard({required this.complaint, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.orderNumber,
                      style: _cardTitleText(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${complaint.customerName}  |  ${complaint.serviceName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyText(color: _Palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ComplaintStatusBadge(status: complaint.status),
            ],
          ),
          const SizedBox(height: 13),
          _SoftBadge(label: complaint.category, tone: _Tone.neutral),
          const SizedBox(height: 11),
          Text(
            complaint.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: _bodyText(color: _Palette.navy, height: 1.45),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: _Palette.muted,
              ),
              const SizedBox(width: 6),
              Text(
                complaint.createdLabel,
                style: _bodyText(color: _Palette.muted),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onDetail,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Detail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  const _SettingsInfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _Palette.softMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 19),
              ),
              const SizedBox(width: 11),
              Text(title, style: _cardTitleText(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < rows.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    rows[index].$1,
                    style: _bodyText(color: _Palette.muted),
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    rows[index].$2,
                    textAlign: TextAlign.right,
                    style: _smallStrongText(color: _Palette.navy),
                  ),
                ),
              ],
            ),
            if (index < rows.length - 1)
              const Divider(height: 24, color: _Palette.border),
          ],
        ],
      ),
    );
  }
}

class _SystemStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _Tone tone;

  const _SystemStatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(tone);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: colors.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: _bodyText(color: _Palette.navy)),
          ),
          Text(value, style: _smallStrongText(color: colors.foreground)),
        ],
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CardHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _cardTitleText(fontSize: 17)),
        const SizedBox(height: 4),
        Text(subtitle, style: _bodyText(color: _Palette.muted)),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool strong;

  const _MetaRow({
    required this.icon,
    required this.label,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: strong
                  ? _smallStrongText(color: _Palette.navy)
                  : _bodyText(color: _Palette.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAF9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        children: [
          Text(value, style: _cardTitleText(fontSize: 16)),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: _Palette.muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: _Palette.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const _InitialAvatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF64C9BE), Color(0xFF2F8F8A)],
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String status;

  const _StatusBadge({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      'completed' => _Tone.green,
      'in_progress' => _Tone.amber,
      'assigned' || 'scheduled' || 'paid' => _Tone.blue,
      'cancelled' || 'complained' => _Tone.red,
      _ => _Tone.neutral,
    };
    return _SoftBadge(label: label, tone: tone);
  }
}

class _PaymentBadge extends StatelessWidget {
  final String label;
  final String status;

  const _PaymentBadge({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      'paid' => _Tone.green,
      'pending' || 'pending_payment' => _Tone.amber,
      'failed' || 'expired' || 'refunded' => _Tone.red,
      _ => _Tone.neutral,
    };
    return _SoftBadge(label: label, tone: tone);
  }
}

class _ComplaintStatusBadge extends StatelessWidget {
  final String status;

  const _ComplaintStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      'open' => _Tone.red,
      'in_review' => _Tone.amber,
      'resolved' => _Tone.green,
      'rejected' => _Tone.neutral,
      _ => _Tone.neutral,
    };
    return _SoftBadge(label: adminComplaintStatusLabel(status), tone: tone);
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;
  final _Tone tone;

  const _SoftBadge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          color: colors.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? AppColors.primary : _Palette.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? Colors.white : _Palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F4),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < labels.length; index++)
            InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selectedIndex == index
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedIndex == index
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[index],
                  style: _smallStrongText(
                    color: selectedIndex == index
                        ? AppColors.primary
                        : _Palette.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveDataPill extends StatelessWidget {
  const _LiveDataPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6EE),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFC7E7D3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF47A976),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Real data',
            style: _smallStrongText(color: const Color(0xFF2B7C52)),
          ),
        ],
      ),
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PremiumEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _Palette.softMint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppColors.primary, size: 27),
              ),
              const SizedBox(height: 14),
              Text(title, style: _cardTitleText(fontSize: 17)),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: _bodyText(color: _Palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineEmpty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 27),
          const SizedBox(height: 8),
          Text(text, style: _bodyText(color: _Palette.muted)),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const _SurfaceCard(
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Memuat data admin Bersihuy...',
                style: TextStyle(color: _Palette.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorPanel({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFB34F43),
                size: 40,
              ),
              const SizedBox(height: 13),
              Text(
                'Dashboard tidak dapat dimuat',
                style: _cardTitleText(fontSize: 18),
              ),
              const SizedBox(height: 7),
              Text(
                'Periksa akses Supabase atau muat ulang data.',
                style: _bodyText(color: _Palette.muted),
              ),
              const SizedBox(height: 17),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Muat ulang'),
                style: _primaryActionStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataWarningBanner extends StatelessWidget {
  final List<String> warnings;

  const _DataWarningBanner({required this.warnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEED39D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFB57612),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Sebagian data tidak dapat diakses (${warnings.length} sumber). '
              '${warnings.first}',
              style: _bodyText(color: const Color(0xFF8C641D)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailDialog extends StatelessWidget {
  final AdminOrderRow order;

  const _OrderDetailDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    return _AdminDialogShell(
      title: 'Detail Pesanan',
      subtitle: order.orderNumber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(
                label: order.statusLabel,
                status: order.effectiveStatus,
              ),
              _PaymentBadge(
                label: order.paymentStatusLabel,
                status: order.paymentStatus ?? 'missing',
              ),
              _SoftBadge(
                label: order.assignmentLabel,
                tone: order.hasAssignedStaff ? _Tone.teal : _Tone.amber,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DialogInfoRow(label: 'Customer', value: order.customerName),
          _DialogInfoRow(label: 'Layanan', value: order.serviceName),
          _DialogInfoRow(label: 'Item / Add-on', value: order.detailItemsLabel),
          _DialogInfoRow(label: 'Jadwal', value: order.scheduleLabel),
          _DialogInfoRow(label: 'Alamat', value: order.address),
          _DialogInfoRow(label: 'Catatan', value: order.customerNote ?? '-'),
          _DialogInfoRow(label: 'Total', value: order.totalLabel),
          _DialogInfoRow(label: 'Petugas', value: order.assignmentLabel),
          _DialogInfoRow(
            label: 'Task Status',
            value: order.taskStatus == null
                ? '-'
                : adminOrderStatusLabel(order.taskStatus!),
          ),
          const SizedBox(height: 8),
          Text('Bukti Pekerjaan', style: _cardTitleText(fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AdminProofTile(
                  label: 'Sebelum',
                  imageUrl: order.beforePhotoUrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AdminProofTile(
                  label: 'Sesudah',
                  imageUrl: order.afterPhotoUrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffDetailDialog extends StatelessWidget {
  final AdminStaffProfile staff;

  const _StaffDetailDialog({required this.staff});

  @override
  Widget build(BuildContext context) {
    return _AdminDialogShell(
      title: 'Detail Petugas',
      subtitle: staff.fullName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialAvatar(initials: staff.initials, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.fullName, style: _cardTitleText(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      staff.email ?? '-',
                      style: _bodyText(color: _Palette.muted),
                    ),
                    const SizedBox(height: 7),
                    _SoftBadge(
                      label: staff.availabilityLabel,
                      tone: staff.isActive ? _Tone.green : _Tone.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DialogInfoRow(label: 'Telepon', value: staff.phone ?? '-'),
          _DialogInfoRow(label: 'Area', value: staff.areaLabel),
          _DialogInfoRow(label: 'Jadwal Kerja', value: staff.workScheduleLabel),
          _DialogInfoRow(label: 'Lokasi Base', value: staff.baseLocationLabel),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Ditugaskan',
                  value: '${staff.assignedTasks}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Proses',
                  value: '${staff.inProgressTasks}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Selesai',
                  value: '${staff.completedTasks}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Rating',
                  value: staff.averageRating == 0
                      ? '-'
                      : staff.averageRating.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Keluhan',
                  value: '${staff.complaintCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminProofTile extends StatelessWidget {
  final String label;
  final String? imageUrl;

  const _AdminProofTile({required this.label, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.trim().isNotEmpty == true;
    return Container(
      height: 128,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_outlined, color: _Palette.muted),
              ),
            )
          else
            Center(
              child: Text(
                'Bukti belum diunggah.',
                textAlign: TextAlign.center,
                style: _bodyText(color: _Palette.muted),
              ),
            ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _Palette.navy.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(label, style: _smallStrongText(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogDetailDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final IconData fallbackIcon;
  final List<(String, String)> rows;
  final bool isActive;

  const _CatalogDetailDialog._({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.fallbackIcon,
    required this.rows,
    required this.isActive,
  });

  factory _CatalogDetailDialog.service(AdminServiceItem service) {
    return _CatalogDetailDialog._(
      title: service.name,
      subtitle: 'Detail layanan',
      imagePath: service.imageAssetPath,
      fallbackIcon: Icons.cleaning_services_rounded,
      isActive: service.isActive,
      rows: [
        ('Kategori', service.category),
        ('Harga dasar', formatAdminRupiah(service.price)),
        ('Durasi', '${service.durationMinutes} menit'),
        (
          'Rating',
          service.rating == 0 ? '-' : service.rating.toStringAsFixed(1),
        ),
        ('Deskripsi', service.description.isEmpty ? '-' : service.description),
      ],
    );
  }

  factory _CatalogDetailDialog.product(AdminProductItem product) {
    return _CatalogDetailDialog._(
      title: product.name,
      subtitle: 'Detail produk / add-on',
      imagePath: product.imageAssetPath,
      fallbackIcon: Icons.inventory_2_rounded,
      isActive: product.isActive,
      rows: [
        ('Jenis', product.isAddon ? 'Add-on' : 'Produk'),
        ('Harga', formatAdminRupiah(product.price)),
        ('Deskripsi', product.description.isEmpty ? '-' : product.description),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AdminDialogShell(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatalogThumbnail(imagePath: imagePath, fallbackIcon: fallbackIcon),
          const SizedBox(height: 15),
          _SoftBadge(
            label: isActive ? 'Aktif' : 'Nonaktif',
            tone: isActive ? _Tone.green : _Tone.neutral,
          ),
          const SizedBox(height: 16),
          for (final row in rows) _DialogInfoRow(label: row.$1, value: row.$2),
        ],
      ),
    );
  }
}

class _ComplaintDetailDialog extends StatefulWidget {
  final AdminComplaintRow complaint;
  final AdminDashboardRepository repository;

  const _ComplaintDetailDialog({
    required this.complaint,
    required this.repository,
  });

  @override
  State<_ComplaintDetailDialog> createState() => _ComplaintDetailDialogState();
}

class _ComplaintDetailDialogState extends State<_ComplaintDetailDialog> {
  late String _status;
  late final TextEditingController _noteController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _status = widget.complaint.status;
    _noteController = TextEditingController(
      text: widget.complaint.resolutionNote ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.repository.updateComplaint(
        complaint: widget.complaint,
        status: _status,
        resolutionNote: _noteController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      _showError('Update gagal: ${error.message}');
    } catch (error) {
      _showError('Update gagal: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogHeader(
                title: 'Detail Keluhan',
                subtitle: complaint.orderNumber,
                closeEnabled: !_submitting,
              ),
              const SizedBox(height: 17),
              _ComplaintStatusBadge(status: complaint.status),
              const SizedBox(height: 16),
              _DialogInfoRow(label: 'Customer', value: complaint.customerName),
              _DialogInfoRow(label: 'Layanan', value: complaint.serviceName),
              _DialogInfoRow(label: 'Kategori', value: complaint.category),
              _DialogInfoRow(label: 'Tanggal', value: complaint.createdLabel),
              _DialogInfoRow(
                label: 'Ditangani oleh',
                value: complaint.handledByName ?? '-',
              ),
              const SizedBox(height: 2),
              Text(
                'Deskripsi lengkap',
                style: _smallStrongText(color: _Palette.navy),
              ),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Palette.border),
                ),
                child: Text(
                  complaint.description,
                  style: _bodyText(color: _Palette.navy, height: 1.5),
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'Update status',
                style: _smallStrongText(color: _Palette.navy),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: _dialogInputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(
                    value: 'in_review',
                    child: Text('In Review'),
                  ),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _status = value);
                      },
              ),
              const SizedBox(height: 13),
              Text(
                'Catatan resolusi',
                style: _smallStrongText(color: _Palette.navy),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                enabled: !_submitting,
                minLines: 3,
                maxLines: 5,
                decoration: _dialogInputDecoration(
                  hintText: 'Tambahkan tindak lanjut atau hasil penyelesaian',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 9),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 17),
                    label: const Text('Simpan Perubahan'),
                    style: _primaryActionStyle(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignStaffDialog extends StatefulWidget {
  final AdminOrderRow order;
  final AdminDashboardRepository repository;

  const _AssignStaffDialog({required this.order, required this.repository});

  @override
  State<_AssignStaffDialog> createState() => _AssignStaffDialogState();
}

class _AssignStaffDialogState extends State<_AssignStaffDialog> {
  late Future<List<AdminStaffProfile>> _staffFuture;
  AdminStaffProfile? _selectedStaff;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _staffFuture = widget.repository.getStaffProfiles();
  }

  Future<void> _submit() async {
    final staff = _selectedStaff;
    if (staff == null) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.repository.assignStaffToOrder(
        order: widget.order,
        staff: staff,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      _showError(
        'Assign gagal: ${error.message}. Cek debug console untuk detail RLS.',
      );
    } catch (error) {
      _showError('Assign gagal: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogHeader(
                title: widget.order.hasAssignedStaff
                    ? 'Ubah Petugas'
                    : 'Assign Petugas',
                subtitle: widget.order.orderNumber,
                closeEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5FAF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _Palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.customerName,
                      style: _smallStrongText(color: _Palette.navy),
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.cleaning_services_outlined,
                      label: widget.order.serviceName,
                    ),
                    _MetaRow(
                      icon: Icons.event_rounded,
                      label: widget.order.scheduleLabel,
                    ),
                    _MetaRow(
                      icon: Icons.location_on_outlined,
                      label: widget.order.address,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih petugas',
                style: _smallStrongText(color: _Palette.navy),
              ),
              const SizedBox(height: 9),
              Flexible(
                child: FutureBuilder<List<AdminStaffProfile>>(
                  future: _staffFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _InlineEmpty(
                        icon: Icons.error_outline_rounded,
                        text: 'Staff tidak dapat dimuat: ${snapshot.error}',
                      );
                    }
                    final staffList = snapshot.data ?? [];
                    if (staffList.isEmpty) {
                      return const _InlineEmpty(
                        icon: Icons.groups_outlined,
                        text: 'Belum ada profil staff.',
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: staffList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final staff = staffList[index];
                        return _StaffOption(
                          staff: staff,
                          selected: _selectedStaff?.id == staff.id,
                          onTap: _isSubmitting
                              ? null
                              : () => setState(() => _selectedStaff = staff),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 9),
                  FilledButton.icon(
                    onPressed: _selectedStaff == null || _isSubmitting
                        ? null
                        : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.assignment_ind_outlined, size: 17),
                    label: const Text('Assign Petugas'),
                    style: _primaryActionStyle(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffOption extends StatelessWidget {
  final AdminStaffProfile staff;
  final bool selected;
  final VoidCallback? onTap;

  const _StaffOption({
    required this.staff,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? AppColors.primary : _Palette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              _InitialAvatar(initials: staff.initials, size: 40),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.fullName,
                      style: _smallStrongText(color: _Palette.navy),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaPill(
                          icon: Icons.map_outlined,
                          label: staff.areaLabel,
                        ),
                        _MetaPill(
                          icon: Icons.schedule_outlined,
                          label: staff.shiftLabel,
                        ),
                        _SoftBadge(
                          label: staff.availabilityLabel,
                          tone: staff.isActive ? _Tone.green : _Tone.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : _Palette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDialogShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AdminDialogShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogHeader(title: title, subtitle: subtitle),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool closeEnabled;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    this.closeEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _cardTitleText(fontSize: 20)),
              const SizedBox(height: 4),
              Text(subtitle, style: _bodyText(color: _Palette.muted)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tutup',
          onPressed: closeEnabled ? () => Navigator.pop(context) : null,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: _bodyText(color: _Palette.muted)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: _smallStrongText(color: _Palette.navy)),
          ),
        ],
      ),
    );
  }
}

InputDecoration _dialogInputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: _Palette.muted, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF8FBFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: _Palette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
  );
}

TextStyle _cardTitleText({double fontSize = 15}) {
  return AppTextStyles.headlineSmall.copyWith(
    color: _Palette.navy,
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
  );
}

TextStyle _smallStrongText({required Color color}) {
  return AppTextStyles.labelMedium.copyWith(
    color: color,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );
}

TextStyle _bodyText({required Color color, double height = 1.3}) {
  return AppTextStyles.bodyMedium.copyWith(
    color: color,
    fontSize: 12,
    height: height,
  );
}

ButtonStyle _primaryActionStyle() {
  return FilledButton.styleFrom(
    minimumSize: const Size(0, 40),
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    textStyle: AppTextStyles.labelMedium.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
  );
}

ButtonStyle _secondaryActionStyle() {
  return OutlinedButton.styleFrom(
    minimumSize: const Size(0, 40),
    foregroundColor: _Palette.navy,
    backgroundColor: Colors.white,
    side: const BorderSide(color: _Palette.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    textStyle: AppTextStyles.labelMedium.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
  );
}

String _compactMoney(int value) {
  if (value >= 1000000) {
    return 'Rp${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}jt';
  }
  if (value >= 1000) {
    return 'Rp${(value / 1000).toStringAsFixed(0)}rb';
  }
  return 'Rp$value';
}

String _initials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .toList();
  if (words.isEmpty) return 'A';
  return words.map((word) => word[0].toUpperCase()).join();
}
