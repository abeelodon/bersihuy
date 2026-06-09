import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';
import '../repositories/staff_task_repository.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  static const _repository = StaffTaskRepository();

  List<StaffTaskWithDetails> _todayTasks = [];
  bool _isLoading = true;
  String? _error;
  String _staffName = 'Petugas';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    debugPrint('STAFF HOME LOAD START');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch staff name and today's tasks concurrently
      final results = await Future.wait([
        _repository.getStaffName(),
        _repository.getHomeTasks(),
      ]);

      final staffName = results[0] as String?;
      final tasks = results[1] as List<StaffTaskWithDetails>;

      debugPrint(
        'STAFF HOME LOAD SUCCESS name=$staffName tasks=${tasks.length}',
      );

      if (!mounted) return;
      setState(() {
        if (staffName != null && staffName.trim().isNotEmpty) {
          _staffName = staffName.trim();
        }
        _todayTasks = [...tasks]
          ..sort(StaffTaskWithDetails.compareByOperationalPriority);
      });
    } catch (e, st) {
      debugPrint('STAFF HOME LOAD ERROR: $e');
      debugPrint('STAFF HOME LOAD STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('STAFF HOME LOAD FINALLY loading=false');
      }
    }
  }

  // ── Derived data ──────────────────────────────────────────────────────────

  StaffTaskWithDetails? get _activeTask {
    return _unfinishedTasks
        .where((t) => t.task.status == 'in_progress')
        .firstOrNull;
  }

  List<StaffTaskWithDetails> get _scheduledTasks {
    return _unfinishedTasks
        .where((t) => t.task.status != 'in_progress')
        .toList();
  }

  List<StaffTaskWithDetails> get _unfinishedTasks {
    return _todayTasks.where((task) => task.isActive).toList();
  }

  int get _completedCount {
    return _todayTasks.where((t) => t.task.status == 'completed').length;
  }

  StaffTaskWithDetails? get _priorityTask {
    return _unfinishedTasks.firstOrNull;
  }

  StaffTaskWithDetails? get _nextTask {
    return _unfinishedTasks.length > 1 ? _unfinishedTasks[1] : null;
  }

  bool get _allCompleted =>
      _todayTasks.isNotEmpty && _todayTasks.every((task) => task.isCompleted);

  bool get _noTasks => _todayTasks.isEmpty;

  String get _greetingSubtitle {
    if (_activeTask != null) {
      return 'Ada 1 tugas sedang berjalan. Tetap semangat!';
    }
    if (_noTasks) {
      return 'Belum ada tugas ditugaskan. Istirahat dulu ya!';
    }
    if (_allCompleted) {
      return 'Semua tugas selesai. Kerja bagus!';
    }
    final assignedCount = _scheduledTasks.length;
    if (assignedCount > 0) {
      return 'Kamu punya $assignedCount tugas menunggu. Yuk mulai!';
    }
    return 'Kamu punya ${_todayTasks.length} tugas. Yuk semangat!';
  }

  Future<void> _openNavigation(String address) async {
    if (address.trim().isEmpty || address.trim() == '-') {
      showStaffInfoSnackBar(context, 'Alamat layanan belum tersedia.');
      return;
    }

    final opened = await launchGoogleMapsSearch(address);
    if (!mounted) return;
    if (!opened) {
      showStaffInfoSnackBar(context, 'Google Maps tidak dapat dibuka.');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 124),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 124,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildReferralBanner(context),
                                const SizedBox(height: 22),
                                _buildGreetingSection(),
                                const SizedBox(height: 20),
                                _buildSummaryCard(),
                                const SizedBox(height: 20),
                                if (_isLoading)
                                  _buildLoadingCard()
                                else if (_error != null)
                                  _buildErrorCard(context)
                                else ...[
                                  if (_allCompleted) ...[
                                    _buildSuccessCard(context),
                                    const SizedBox(height: 20),
                                  ] else if (_noTasks) ...[
                                    _buildEmptyTaskCard(context),
                                    const SizedBox(height: 20),
                                  ] else if (_priorityTask != null) ...[
                                    _buildPriorityTaskSection(
                                      context,
                                      task: _priorityTask!,
                                      hasActiveTask:
                                          _priorityTask!.task.status ==
                                          'in_progress',
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  if (_nextTask != null) ...[
                                    _buildNextScheduleSection(
                                      context,
                                      task: _nextTask!,
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ],
                                _buildPromoCodeCard(context),
                                const SizedBox(height: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: StaffBottomNav(currentIndex: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.46),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.staffReferral),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'assets/images/promos/staff_referral_banner.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $_staffName 👋',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _greetingSubtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final activeCount = _activeTask == null ? 0 : 1;

    final metrics = [
      _SummaryMetric(
        icon: Icons.assignment_rounded,
        value: '${_todayTasks.length}',
        label: 'Total tugas',
        color: AppColors.primary,
        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        borderColor: AppColors.primary.withValues(alpha: 0.16),
      ),
      _SummaryMetric(
        icon: Icons.timelapse_rounded,
        value: '$activeCount',
        label: 'Sedang dikerjakan',
        color: const Color(0xFFD97706),
        backgroundColor: const Color(0xFFFFF7E8),
        borderColor: const Color(0xFFF3B967).withValues(alpha: 0.34),
      ),
      _SummaryMetric(
        icon: Icons.check_circle_rounded,
        value: '$_completedCount',
        label: 'Selesai',
        color: const Color(0xFF2F7D54),
        backgroundColor: const Color(0xFFEAF8EF),
        borderColor: const Color(0xFF8FD7AA).withValues(alpha: 0.36),
      ),
      _SummaryMetric(
        icon: Icons.star_rounded,
        value: '4.9',
        label: 'Rating',
        color: const Color(0xFFF59E0B),
        backgroundColor: const Color(0xFFFFF8DF),
        borderColor: const Color(0xFFF2C15E).withValues(alpha: 0.36),
      ),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFEFD),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.1),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 3.5,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                'RINGKASAN TUGAS',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.58,
            children: metrics.map(_buildMetricTile).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(_SummaryMetric metric) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metric.backgroundColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: metric.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, size: 18, color: metric.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 11.5,
                    height: 1.2,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading / Error Cards ──────────────────────────────────────────────

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: staffPremiumCardDecoration(radius: 24),
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

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: staffPremiumCardDecoration(radius: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          staffSoftIcon(icon: Icons.error_outline_rounded, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gagal memuat tugas',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _error ?? 'Terjadi kesalahan.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadData,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Coba Lagi',
                    style: AppTextStyles.linkSmall.copyWith(
                      fontWeight: FontWeight.w900,
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

  // ─── Task Sections ──────────────────────────────────────────────────────

  Widget _buildPriorityTaskSection(
    BuildContext context, {
    required StaffTaskWithDetails task,
    required bool hasActiveTask,
  }) {
    return _buildTaskSection(
      title: task.isOverdueAt(DateTime.now())
          ? 'Tugas Terlewat'
          : 'Tugas Prioritas',
      child: _buildTaskCard(
        context,
        task: task,
        icon: Icons.task_alt_rounded,
        buttonLabel: hasActiveTask ? 'Lanjutkan Tugas' : 'Lihat Detail',
        isPrimaryAction: true,
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.staffTaskDetail,
          arguments: {'taskId': task.task.id},
        ).then((_) => _loadData()),
      ),
    );
  }

  Widget _buildNextScheduleSection(
    BuildContext context, {
    required StaffTaskWithDetails task,
  }) {
    return _buildTaskSection(
      title: task.isOverdueAt(DateTime.now())
          ? 'Tugas Terlewat Lainnya'
          : 'Jadwal Berikutnya',
      child: _buildTaskCard(
        context,
        task: task,
        icon: Icons.route_rounded,
        buttonLabel: 'Navigasi',
        onTap: () => _openNavigation(task.serviceAddress),
      ),
    );
  }

  Widget _buildTaskSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildSectionTitle(title), const SizedBox(height: 12), child],
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required StaffTaskWithDetails task,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onTap,
    bool isPrimaryAction = false,
  }) {
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.all(isPrimaryAction ? 18 : 15),
      decoration: staffPremiumCardDecoration(
        radius: isPrimaryAction ? 24 : 22,
        borderColor: isPrimaryAction
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.outlineVariant.withValues(alpha: 0.36),
        shadowOpacity: isPrimaryAction ? 0.075 : 0.045,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  staffSoftIcon(icon: icon, size: isPrimaryAction ? 42 : 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildInlineMeta(
                          Icons.person_rounded,
                          task.customerName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(
                    task.isOverdueAt(DateTime.now())
                        ? 'Jadwal Terlewat'
                        : task.task.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(isPrimaryAction ? 13 : 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.34),
                  ),
                ),
                child: Column(
                  children: [
                    _buildTaskMetaRow(
                      Icons.schedule_rounded,
                      task.formattedSchedule,
                    ),
                    const SizedBox(height: 8),
                    _buildTaskMetaRow(
                      Icons.location_on_rounded,
                      task.serviceAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: isPrimaryAction
                    ? ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          buttonLabel,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 12.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(0, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.72),
                          ),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          buttonLabel,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 12.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    return _buildStateCard(
      icon: Icons.check_circle_rounded,
      title: 'Semua tugas selesai',
      body: 'Terima kasih sudah menjaga kualitas layanan hari ini.',
      buttonLabel: 'Lihat Riwayat',
      onTap: () => Navigator.pushNamed(context, AppRoutes.staffHistory),
    );
  }

  Widget _buildEmptyTaskCard(BuildContext context) {
    return _buildStateCard(
      icon: Icons.event_busy_rounded,
      title: 'Tidak ada tugas aktif',
      body: 'Tugas akan muncul setelah admin menjadwalkan layanan untuk kamu.',
      buttonLabel: 'Hubungi Admin',
      onTap: () {
        showStaffInfoSnackBar(context, 'Hubungi admin segera hadir.');
      },
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String body,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: staffPremiumCardDecoration(radius: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          staffSoftIcon(icon: icon, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    buttonLabel,
                    style: AppTextStyles.linkSmall.copyWith(
                      fontWeight: FontWeight.w900,
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

  Widget _buildPromoCodeCard(BuildContext context) {
    const currentPoints = 2;
    const rewardTarget = 4;
    const remaining = rewardTarget - currentPoints;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: staffPremiumCardDecoration(radius: 20, shadowOpacity: 0.04),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          staffSoftIcon(icon: Icons.confirmation_number_rounded, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kode Promo Saya',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    'BERSIHUY20',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Berlaku untuk customer baru',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining > 0
                      ? '$remaining langkah lagi menuju reward pertama'
                      : 'Reward pertama sudah tercapai 🎉',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {
              showStaffInfoSnackBar(context, 'Kode promo dibagikan.');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.32),
              ),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Bagikan',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Helpers ────────────────────────────────────────────────────

  Widget _buildInlineMeta(IconData icon, String value) {
    return Row(
      children: [
        _buildMiniIcon(icon),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskMetaRow(IconData icon, String value) {
    final isLocation = icon == Icons.location_on_rounded;

    return Row(
      children: [
        _buildMiniIcon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: isLocation ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 12.5,
              height: 1.25,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniIcon(IconData icon) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: AppColors.primary),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (textColor, backgroundColor) = switch (status) {
      'Dalam Proses' => (const Color(0xFF9A5B0F), const Color(0xFFFFF1D6)),
      'Ditugaskan' => (const Color(0xFF2B6577), const Color(0xFFE8F2FB)),
      'Selesai' => (const Color(0xFF2F7D54), const Color(0xFFE4F7EC)),
      'Jadwal Terlewat' => (const Color(0xFFB42318), const Color(0xFFFFE9E7)),
      _ => (
        AppColors.onSurfaceVariant,
        AppColors.outlineVariant.withValues(alpha: 0.28),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
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

  Widget _buildSectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0,
      ),
    );
  }
}

class _SummaryMetric {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.primary,
    this.backgroundColor = const Color(0xFFF6FBFA),
    this.borderColor = const Color(0xFFDDE8E6),
  });
}
