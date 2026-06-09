import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';
import '../repositories/staff_task_repository.dart';

class StaffTasksScreen extends StatefulWidget {
  const StaffTasksScreen({super.key});

  @override
  State<StaffTasksScreen> createState() => _StaffTasksScreenState();
}

class _StaffTasksScreenState extends State<StaffTasksScreen> {
  String _selectedTab = 'Semua';

  static const _repository = StaffTaskRepository();
  List<StaffTaskWithDetails> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    debugPrint('STAFF TASKS SCREEN LOAD START');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _repository.getStaffTasks();
      if (!mounted) return;
      setState(() {
        _tasks = [...tasks]
          ..sort(StaffTaskWithDetails.compareByOperationalPriority);
      });
    } catch (e, st) {
      debugPrint('STAFF TASKS SCREEN LOAD ERROR: $e');
      debugPrint('STAFF TASKS SCREEN STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat tugas.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('STAFF TASKS SCREEN LOAD FINALLY loading=false');
      }
    }
  }

  Future<void> _onUpdateStatus(
    StaffTaskWithDetails item,
    String newStatus,
  ) async {
    final taskId = item.task.id;
    debugPrint('STAFF TASKS SCREEN UPDATE STATUS taskId=$taskId → $newStatus');
    try {
      await _repository.updateTaskStatus(taskId, newStatus);
      if (!mounted) return;
      showStaffInfoSnackBar(
        context,
        newStatus == 'in_progress'
            ? 'Tugas dimulai!'
            : 'Tugas berhasil diselesaikan!',
      );
      _loadTasks();
    } catch (e) {
      debugPrint('STAFF TASKS SCREEN UPDATE ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<StaffTaskWithDetails> get _filteredTasks {
    if (_selectedTab == 'Semua') return _tasks;
    if (_selectedTab == 'Jadwal Terlewat') {
      final now = DateTime.now();
      return _tasks.where((task) => task.isOverdueAt(now)).toList();
    }
    return _tasks.where((t) => t.task.statusLabel == _selectedTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;

    final totalCount = _tasks.length;
    final prosesCount = _tasks
        .where((t) => t.task.status == 'in_progress')
        .length;
    final selesaiCount = _tasks
        .where((t) => t.task.status == 'completed')
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 20,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/logo_full.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text(
            'Bersihuy',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    showStaffInfoSnackBar(
                      context,
                      'Notifikasi petugas segera hadir.',
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.outlineVariant.withValues(
                      alpha: 0.2,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
        ),
      ),
      body: PremiumStaffBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minContentHeight = constraints.maxHeight > 600
                  ? constraints.maxHeight - 40
                  : 560.0;

              return Center(
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
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 128),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeaderSection(),
                              const SizedBox(height: 18),
                              _buildStatCards(
                                total: totalCount,
                                proses: prosesCount,
                                selesai: selesaiCount,
                              ),
                              const SizedBox(height: 20),
                              _buildFilterChips(),
                              const SizedBox(height: 18),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: minContentHeight - 200,
                                ),
                                child: _buildContent(filteredTasks),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: StaffBottomNav(currentIndex: 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<StaffTaskWithDetails> filteredTasks) {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (filteredTasks.isEmpty) return _buildEmptyState();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) =>
          _buildTaskCard(context, filteredTasks[index]),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tugas Saya',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kelola pekerjaan layanan yang ditugaskan kepadamu',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Stat Cards ───────────────────────────────────────────────────────────

  Widget _buildStatCards({
    required int total,
    required int proses,
    required int selesai,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$total',
            label: 'Total Tugas',
            icon: Icons.assignment_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primary.withValues(alpha: 0.1),
            valueColor: AppColors.primary,
            bg: const Color(0xFFF4FAF9),
            borderColor: AppColors.primary.withValues(alpha: 0.14),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _StatCard(
            value: '$proses',
            label: 'Dalam Proses',
            icon: Icons.timelapse_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFFF7E8),
            valueColor: const Color(0xFFD97706),
            bg: const Color(0xFFFFF7E8),
            borderColor: const Color(0xFFF3B967).withValues(alpha: 0.34),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _StatCard(
            value: '$selesai',
            label: 'Selesai',
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF2F7D54),
            iconBg: const Color(0xFFEAF8EF),
            valueColor: const Color(0xFF2F7D54),
            bg: const Color(0xFFEAF8EF),
            borderColor: const Color(0xFF8FD7AA).withValues(alpha: 0.36),
          ),
        ),
      ],
    );
  }

  // ─── Filter Chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    const tabs = [
      'Semua',
      'Jadwal Terlewat',
      'Ditugaskan',
      'Dalam Proses',
      'Selesai',
    ];

    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(right: 22),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...tabs.map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.32)
                              : AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tab,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── States ───────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: staffPremiumCardDecoration(radius: 22, shadowOpacity: 0.05),
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
      decoration: staffPremiumCardDecoration(radius: 22, shadowOpacity: 0.05),
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
            onPressed: _loadTasks,
            child: Text(
              'Coba Lagi',
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
      padding: const EdgeInsets.all(28),
      decoration: staffPremiumCardDecoration(radius: 22, shadowOpacity: 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.32),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 26,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tugas',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada tugas untuk kategori filter ini.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Task Card ─────────────────────────────────────────────────────────────

  Widget _buildTaskCard(BuildContext context, StaffTaskWithDetails item) {
    final status = item.task.status;
    final statusLabel = item.isOverdueAt(DateTime.now())
        ? 'Jadwal Terlewat'
        : item.task.statusLabel;
    final isSelesai = status == 'completed';
    final isAssigned = status == 'assigned';

    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(17),
      decoration: staffPremiumCardDecoration(
        radius: 22,
        borderColor: isSelesai
            ? AppColors.outlineVariant.withValues(alpha: 0.28)
            : AppColors.primary.withValues(alpha: 0.14),
        shadowOpacity: isSelesai ? 0.045 : 0.06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: icon + title/customer + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconBgForStatus(statusLabel),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForService(item.serviceName),
                  size: 21,
                  color: _iconColorForStatus(statusLabel),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outlined,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 12.5,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(label: statusLabel),
            ],
          ),

          const SizedBox(height: 14),

          // Info container
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const _MiniIcon(icon: Icons.schedule_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.formattedSchedule,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 12.5,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MiniIcon(icon: Icons.location_on_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.serviceAddress,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 12.5,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // CTA button
          Align(
            alignment: Alignment.centerRight,
            child: isAssigned
                ? ElevatedButton(
                    onPressed: () => _onUpdateStatus(item, 'in_progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Mulai Tugas',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 12.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : isSelesai
                ? OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.staffTaskDetail,
                      arguments: {'taskId': item.task.id},
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.44),
                      ),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Lihat Detail',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 12.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.staffTaskDetail,
                      arguments: {'taskId': item.task.id},
                    ).then((_) => _loadTasks()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Lihat Tugas',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 12.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  IconData _iconForService(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('kos') || lower.contains('kamar')) {
      return Icons.bed_rounded;
    }
    if (lower.contains('kantor') || lower.contains('office')) {
      return Icons.business_rounded;
    }
    return Icons.cleaning_services_rounded;
  }

  Color _iconColorForStatus(String statusLabel) {
    return switch (statusLabel) {
      'Ditugaskan' => const Color(0xFF2B6577),
      'Dalam Proses' => const Color(0xFFD97706),
      'Selesai' => const Color(0xFF2F7D54),
      'Jadwal Terlewat' => const Color(0xFFB42318),
      _ => AppColors.primary,
    };
  }

  Color _iconBgForStatus(String statusLabel) {
    return switch (statusLabel) {
      'Ditugaskan' => const Color(0xFFE8F2FB),
      'Dalam Proses' => const Color(0xFFFFF7E8),
      'Selesai' => const Color(0xFFEAF8EF),
      'Jadwal Terlewat' => const Color(0xFFFFE9E7),
      _ => AppColors.primarySoft,
    };
  }
}

// ─── _StatCard ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color valueColor;
  final Color bg;
  final Color borderColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.valueColor,
    required this.bg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _StatusBadge ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final (textColor, backgroundColor) = _colorsFor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  (Color, Color) _colorsFor(String status) {
    return switch (status) {
      'Ditugaskan' => (const Color(0xFF2B6577), const Color(0xFFE8F2FB)),
      'Dalam Proses' => (const Color(0xFF9A5B0F), const Color(0xFFFFF1D6)),
      'Selesai' => (const Color(0xFF2F7D54), const Color(0xFFE4F7EC)),
      'Jadwal Terlewat' => (const Color(0xFFB42318), const Color(0xFFFFE9E7)),
      _ => (
        AppColors.onSurfaceVariant,
        AppColors.outlineVariant.withValues(alpha: 0.28),
      ),
    };
  }
}

// ─── _MiniIcon ─────────────────────────────────────────────────────────────

class _MiniIcon extends StatelessWidget {
  final IconData icon;

  const _MiniIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 13, color: AppColors.primary),
    );
  }
}
