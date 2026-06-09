import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';
import '../repositories/staff_task_repository.dart';

class StaffHistoryScreen extends StatefulWidget {
  const StaffHistoryScreen({super.key});

  @override
  State<StaffHistoryScreen> createState() => _StaffHistoryScreenState();
}

class _StaffHistoryScreenState extends State<StaffHistoryScreen> {
  String _selectedFilter = 'Semua';

  static const _repository = StaffTaskRepository();
  List<_HistoryEntry> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    debugPrint('STAFF HISTORY LOAD START');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final completedTasks = await _repository.getCompletedTasks();

      // Enrich each completed task with review/complaint info
      final entries = <_HistoryEntry>[];
      for (final task in completedTasks) {
        double? rating;
        bool hasComplaint = false;

        try {
          rating = await _repository.getReviewRatingForOrder(task.task.orderId);
        } catch (_) {}

        try {
          hasComplaint = await _repository.hasComplaintForOrder(task.task.orderId);
        } catch (_) {}

        final hasProof = task.task.beforePhotoUrl != null ||
            task.task.afterPhotoUrl != null;

        String status;
        if (hasComplaint) {
          status = 'Komplain';
        } else if (rating != null) {
          status = 'Diulas';
        } else {
          status = 'Selesai';
        }

        entries.add(_HistoryEntry(
          task: task,
          rating: rating,
          hasProof: hasProof,
          hasComplaint: hasComplaint,
          displayStatus: status,
        ));
      }

      debugPrint('STAFF HISTORY LOAD SUCCESS count=${entries.length}');

      if (!mounted) return;
      setState(() {
        _logs = entries;
      });
    } catch (e, st) {
      debugPrint('STAFF HISTORY LOAD ERROR: $e');
      debugPrint('STAFF HISTORY STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat riwayat tugas.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('STAFF HISTORY LOAD FINALLY loading=false');
      }
    }
  }

  List<_HistoryEntry> get _filteredLogs {
    if (_selectedFilter == 'Semua') return _logs;
    return _logs.where((l) => l.displayStatus == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    final now = DateTime.now();
    final selesaiThisMonth = _logs.where((l) {
      final completedAt = l.task.task.completedAt;
      if (completedAt == null) return false;
      return completedAt.year == now.year && completedAt.month == now.month;
    }).length;
    final diulasCount = _logs.where((l) => l.rating != null).length;
    final komplainCount = _logs.where((l) => l.hasComplaint).length;

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
            child: IconButton(
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
                backgroundColor:
                    AppColors.outlineVariant.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(8),
              ),
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
              final minHeight = constraints.maxHeight > 600
                  ? constraints.maxHeight - 40
                  : 560.0;

              return Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Stack(
                    children: [
                      ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 128),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeaderSection(),
                              const SizedBox(height: 18),
                              _buildStatCards(
                                selesai: selesaiThisMonth,
                                diulas: diulasCount,
                                komplain: komplainCount,
                              ),
                              const SizedBox(height: 20),
                              _buildFilterChips(),
                              const SizedBox(height: 18),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: minHeight - 220,
                                ),
                                child: _buildContent(filteredLogs),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: StaffBottomNav(currentIndex: 2),
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

  Widget _buildContent(List<_HistoryEntry> filteredLogs) {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (filteredLogs.isEmpty) return _buildEmptyState();

    return Column(
      children: filteredLogs.asMap().entries.map((entry) {
        final log = entry.value;
        return Column(
          children: [
            _buildHistoryCard(context, log),
            if (entry.key != filteredLogs.length - 1)
              const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Tugas',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lihat pekerjaan yang sudah kamu selesaikan',
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
    required int selesai,
    required int diulas,
    required int komplain,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$selesai',
            label: 'Selesai\nBulan Ini',
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF2F7D54),
            iconBg: const Color(0xFFEAF8EF),
            valueColor: const Color(0xFF2F7D54),
            bg: const Color(0xFFEAF8EF),
            borderColor: const Color(0xFF8FD7AA).withValues(alpha: 0.36),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _StatCard(
            value: '$diulas',
            label: 'Diulas',
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF7C4DFF),
            iconBg: const Color(0xFFEEE8FF),
            valueColor: const Color(0xFF7C4DFF),
            bg: const Color(0xFFEEE8FF),
            borderColor: const Color(0xFFC4B5F4).withValues(alpha: 0.36),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _StatCard(
            value: '$komplain',
            label: 'Komplain',
            icon: Icons.report_rounded,
            iconColor: const Color(0xFFBA1A1A),
            iconBg: const Color(0xFFFFE8E8),
            valueColor: const Color(0xFFBA1A1A),
            bg: const Color(0xFFFFE8E8),
            borderColor: const Color(0xFFE89090).withValues(alpha: 0.36),
          ),
        ),
      ],
    );
  }

  // ─── Filter Chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    const tabs = ['Semua', 'Selesai', 'Diulas', 'Komplain'];

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
                final isSelected = _selectedFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = tab),
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
                                  color: AppColors.primary.withValues(alpha: 0.06),
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
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
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
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB45A5A), size: 32),
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
            onPressed: _loadHistory,
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
              Icons.history_rounded,
              size: 26,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat tugas',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Riwayat akan muncul setelah tugas selesai.',
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

  // ─── History Card ──────────────────────────────────────────────────────────

  Widget _buildHistoryCard(BuildContext context, _HistoryEntry entry) {
    final status = entry.displayStatus;

    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(17),
      decoration: staffPremiumCardDecoration(
        radius: 22,
        borderColor: _borderColorForStatus(status),
        shadowOpacity: 0.055,
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
                  color: _iconBgForStatus(status),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForService(entry.task.serviceName),
                  size: 21,
                  color: _iconColorForStatus(status),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.task.serviceName,
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
                            entry.task.customerName,
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
              _StatusBadge(label: status),
            ],
          ),

          const SizedBox(height: 14),

          // Info container: date/time row, location row
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
                    const _MiniIcon(icon: Icons.calendar_today_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.task.formattedSchedule,
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
                        entry.task.serviceAddress,
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

          const SizedBox(height: 13),

          // Rating + proof row
          Row(
            children: [
              if (entry.rating != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8DF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFF2C15E).withValues(alpha: 0.36),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        entry.rating!.toStringAsFixed(1),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              if (entry.rating != null) const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: entry.hasProof
                      ? AppColors.primary.withValues(alpha: 0.07)
                      : AppColors.outlineVariant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: entry.hasProof
                        ? AppColors.primary.withValues(alpha: 0.14)
                        : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.hasProof
                          ? Icons.photo_library_rounded
                          : Icons.photo_library_outlined,
                      color: entry.hasProof
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      entry.hasProof ? 'Bukti lengkap' : 'Bukti belum ada',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: entry.hasProof
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // CTA button
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.staffTaskDetail,
                arguments: {'taskId': entry.task.task.id},
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
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  IconData _iconForService(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('kos') || lower.contains('kamar')) {
      return Icons.bed_rounded;
    }
    if (lower.contains('kantor') || lower.contains('office')) {
      return Icons.business_rounded;
    }
    if (lower.contains('rumah') || lower.contains('home')) {
      return Icons.home_rounded;
    }
    return Icons.cleaning_services_rounded;
  }

  Color _iconColorForStatus(String status) {
    return switch (status) {
      'Selesai' => const Color(0xFF2F7D54),
      'Diulas' => const Color(0xFF7C4DFF),
      'Komplain' => const Color(0xFFBA1A1A),
      _ => AppColors.primary,
    };
  }

  Color _iconBgForStatus(String status) {
    return switch (status) {
      'Selesai' => const Color(0xFFEAF8EF),
      'Diulas' => const Color(0xFFEEE8FF),
      'Komplain' => const Color(0xFFFFE8E8),
      _ => AppColors.primarySoft,
    };
  }

  Color _borderColorForStatus(String status) {
    return switch (status) {
      'Selesai' => const Color(0xFF8FD7AA).withValues(alpha: 0.3),
      'Diulas' => const Color(0xFFC4B5F4).withValues(alpha: 0.3),
      'Komplain' => const Color(0xFFE89090).withValues(alpha: 0.3),
      _ => AppColors.outlineVariant.withValues(alpha: 0.36),
    };
  }
}

// ─── Data class ────────────────────────────────────────────────────────────

class _HistoryEntry {
  final StaffTaskWithDetails task;
  final double? rating;
  final bool hasProof;
  final bool hasComplaint;
  final String displayStatus;

  const _HistoryEntry({
    required this.task,
    this.rating,
    required this.hasProof,
    required this.hasComplaint,
    required this.displayStatus,
  });
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
              height: 1.3,
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
      'Selesai' => (const Color(0xFF2F7D54), const Color(0xFFE4F7EC)),
      'Diulas' => (const Color(0xFF5E35B1), const Color(0xFFEDE7F6)),
      'Komplain' => (const Color(0xFFBA1A1A), const Color(0xFFFFE8E8)),
      _ => (AppColors.onSurfaceVariant,
            AppColors.outlineVariant.withValues(alpha: 0.28)),
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