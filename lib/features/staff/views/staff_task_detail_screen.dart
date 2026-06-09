import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';
import '../repositories/staff_task_repository.dart';
import '../../chat/screens/order_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffTaskDetailScreen extends StatefulWidget {
  final String taskId;

  const StaffTaskDetailScreen({super.key, required this.taskId});

  @override
  State<StaffTaskDetailScreen> createState() => _StaffTaskDetailScreenState();
}

class _StaffTaskDetailScreenState extends State<StaffTaskDetailScreen> {
  static const _repository = StaffTaskRepository();

  StaffTaskWithDetails? _taskDetails;
  bool _isLoading = true;
  String? _error;
  bool _isUpdating = false;
  bool _isUploadingBefore = false;
  bool _isUploadingAfter = false;
  final _imagePicker = ImagePicker();

  // Persistent checklist — backed by tasks.checklist_data JSONB column.
  // Keys map 1-to-1 with the JSON keys stored in Supabase.
  static const _checklistKeys = [
    'area_utama_dibersihkan',
    'lantai_dipel',
    'perabot_dirapikan',
    'sampah_dibuang',
    'foto_before_after_siap',
  ];
  static const _checklistLabels = [
    'Area utama dibersihkan',
    'Lantai dipel',
    'Perabot dirapikan',
    'Sampah dibuang',
    'Foto before-after siap',
  ];
  final List<bool> _checklist = [false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    if (!mounted) return;
    debugPrint('STAFF TASK DETAIL LOAD START taskId=${widget.taskId}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _repository.getTaskById(widget.taskId);
      if (!mounted) return;
      if (details == null) {
        setState(() => _error = 'Tugas tidak ditemukan.');
      } else {
        // Initialize checklist from persisted data
        final saved = details.task.checklistData;
        for (var i = 0; i < _checklistKeys.length; i++) {
          _checklist[i] = saved[_checklistKeys[i]] == true;
        }
        debugPrint('STAFF TASK DETAIL checklist loaded: $saved');
        setState(() => _taskDetails = details);
      }
    } catch (e) {
      debugPrint('STAFF TASK DETAIL LOAD ERROR: $e');
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat detail tugas.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Toggles a checklist item and persists to Supabase.
  Future<void> _onChecklistToggle(int index) async {
    // Update local state immediately for responsive UI
    setState(() {
      _checklist[index] = !_checklist[index];
    });

    // Build JSON payload from current checklist state
    final payload = <String, dynamic>{};
    for (var i = 0; i < _checklistKeys.length; i++) {
      payload[_checklistKeys[i]] = _checklist[i];
    }

    try {
      await _repository.updateTaskChecklist(widget.taskId, payload);
    } catch (_) {
      // Rollback on failure
      if (mounted) {
        setState(() {
          _checklist[index] = !_checklist[index];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan checklist.'),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  Future<void> _onUpdateStatus(String newStatus) async {
    if (_isUpdating) return;

    if (newStatus == 'completed') {
      final task = _taskDetails?.task;
      final hasBeforePhoto = task?.beforePhotoUrl?.trim().isNotEmpty == true;
      final hasAfterPhoto = task?.afterPhotoUrl?.trim().isNotEmpty == true;
      if (!hasBeforePhoto || !hasAfterPhoto) {
        showStaffInfoSnackBar(
          context,
          'Upload bukti sebelum dan sesudah terlebih dahulu.',
        );
        return;
      }
      if (!_checklist.every((item) => item)) {
        showStaffInfoSnackBar(
          context,
          'Lengkapi semua checklist pekerjaan terlebih dahulu.',
        );
        return;
      }
    }

    setState(() => _isUpdating = true);

    try {
      await _repository.updateTaskStatus(widget.taskId, newStatus);
      if (!mounted) return;
      showStaffInfoSnackBar(
        context,
        newStatus == 'in_progress'
            ? 'Tugas dimulai!'
            : 'Tugas berhasil diselesaikan!',
      );
      _loadTask(); // Refresh
    } catch (e) {
      debugPrint('STAFF TASK DETAIL UPDATE ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
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

  Future<void> _pickAndUploadProof(TaskProofType type) async {
    final isBefore = type == TaskProofType.before;
    if (_isUploadingBefore || _isUploadingAfter) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (picked == null || !mounted) return;

      final contentType = _imageContentType(picked);
      if (contentType == null) {
        throw const ProofUploadException(
          'Format gambar harus JPG, PNG, atau WebP.',
        );
      }

      setState(() {
        if (isBefore) {
          _isUploadingBefore = true;
        } else {
          _isUploadingAfter = true;
        }
      });

      await _repository.uploadTaskProof(
        taskId: widget.taskId,
        type: type,
        bytes: await picked.readAsBytes(),
        contentType: contentType,
      );
      await _loadTask();
      if (!mounted) return;
      showStaffInfoSnackBar(
        context,
        'Foto ${isBefore ? 'sebelum' : 'sesudah'} berhasil diunggah.',
      );
    } on ProofUploadException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (error) {
      debugPrint('STAFF PROOF PICK/UPLOAD ERROR: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memilih atau mengunggah gambar.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isBefore) {
            _isUploadingBefore = false;
          } else {
            _isUploadingAfter = false;
          }
        });
      }
    }
  }

  String? _imageContentType(XFile file) {
    final mimeType = file.mimeType?.toLowerCase();
    if (mimeType == 'image/jpeg' ||
        mimeType == 'image/png' ||
        mimeType == 'image/webp') {
      return mimeType;
    }

    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
        ),
        title: Text(
          'Detail Tugas',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.outlineVariant, height: 1.0),
        ),
      ),
      body: PremiumStaffBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFB45A5A),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFFB45A5A),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadTask,
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
        ),
      );
    }

    final details = _taskDetails!;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTaskSummaryCard(details),
            const SizedBox(height: 20),
            _buildCustomerCard(details),
            const SizedBox(height: 20),
            _buildStatusWorkflowCard(details),
            const SizedBox(height: 20),
            _buildChecklistCard(),
            const SizedBox(height: 20),
            _buildProofOfWorkSection(details),
            const SizedBox(height: 24),
            _buildActionButtons(context, details),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSummaryCard(StaffTaskWithDetails details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              staffSoftIcon(
                icon: Icons.cleaning_services_rounded,
                color: AppColors.primary,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.serviceName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details.customerName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StaffStatusBadge(
                label: details.isOverdueAt(DateTime.now())
                    ? 'Jadwal Terlewat'
                    : details.task.statusLabel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.outline,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.formattedSchedule,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'No. Pesanan: ${details.orderNumber}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  details.serviceAddress,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (details.customerNote != null &&
              details.customerNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"${details.customerNote!.trim()}"',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(StaffTaskWithDetails details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.customerName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details.orderNumber,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChatCustomer(details),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: Text(
                    'Chat Customer',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openNavigation(details.serviceAddress),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    'Navigasi',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openChatCustomer(StaffTaskWithDetails details) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderChatScreen(
          orderId: details.task.orderId,
          currentUserId: currentUserId,
          customerId: details.customerId,
          staffId: details.task.staffId,
          orderNumber: details.orderNumber,
          receiverName: details.customerName,
          serviceAddress: details.serviceAddress,
          title: 'Chat Customer',
        ),
      ),
    );
  }

  Widget _buildStatusWorkflowCard(StaffTaskWithDetails details) {
    final workflowSteps = ['Ditugaskan', 'Dalam Proses', 'Selesai'];

    final currentLabel = details.task.statusLabel;
    int activeIndex = workflowSteps.indexOf(currentLabel);
    if (activeIndex < 0) activeIndex = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Pekerjaan',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workflowSteps.length,
            itemBuilder: (context, index) {
              final step = workflowSteps[index];
              final isCompleted = index < activeIndex;
              final isActive = index == activeIndex;

              return IntrinsicHeight(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.primary
                                : Colors.white,
                            border: Border.all(
                              color: isCompleted || isActive
                                  ? AppColors.primary
                                  : AppColors.outlineVariant,
                              width: 2,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : isActive
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        if (index < workflowSteps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: index < activeIndex
                                  ? AppColors.primary
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          step,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.normal,
                            color: isActive
                                ? AppColors.primary
                                : isCompleted
                                ? AppColors.onSurface
                                : AppColors.outline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              staffSoftIcon(
                icon: Icons.checklist_rounded,
                color: AppColors.primary,
                size: 40,
              ),
              const SizedBox(width: 12),
              Text(
                'Checklist Pekerjaan',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_checklist.length, (index) {
            final isLast = index == _checklist.length - 1;
            return Column(
              children: [
                InkWell(
                  onTap: () => _onChecklistToggle(index),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _checklist[index]
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _checklist[index]
                                ? AppColors.primary
                                : AppColors.outline,
                            width: 1.5,
                          ),
                        ),
                        child: _checklist[index]
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _checklistLabels[index],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _checklist[index]
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                            decoration: _checklist[index]
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProofOfWorkSection(StaffTaskWithDetails details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: staffPremiumCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bukti Pekerjaan',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload foto sebelum dan sesudah pekerjaan.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProofCard(
                  label: 'Sebelum',
                  imageUrl: details.task.beforePhotoUrl,
                  isUploading: _isUploadingBefore,
                  onTap: () => _pickAndUploadProof(TaskProofType.before),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProofCard(
                  label: 'Sesudah',
                  imageUrl: details.task.afterPhotoUrl,
                  isUploading: _isUploadingAfter,
                  onTap: () => _pickAndUploadProof(TaskProofType.after),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard({
    required String label,
    required String? imageUrl,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.outlineVariant,
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
                    size: 32,
                  ),
                ),
              )
            else
              Center(
                child: isUploading
                    ? const CircularProgressIndicator(strokeWidth: 2.5)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.outline.withValues(alpha: 0.7),
                            size: 32,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ketuk untuk upload',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: hasImage
                      ? AppColors.onSurface.withValues(alpha: 0.74)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: hasImage ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    StaffTaskWithDetails details,
  ) {
    final status = details.task.status;

    // Completed task — no action buttons
    if (status == 'completed' || status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: staffPremiumCardDecoration(radius: 22),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2F7D54), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tugas ini sudah selesai.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF2F7D54),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assigned → Mulai Tugas
    if (status == 'assigned') {
      return ElevatedButton(
        onPressed: _isUpdating ? null : () => _onUpdateStatus('in_progress'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          minimumSize: const Size.fromHeight(48),
        ),
        child: _isUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Mulai Tugas',
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      );
    }

    final hasBeforePhoto =
        details.task.beforePhotoUrl?.trim().isNotEmpty == true;
    final hasAfterPhoto = details.task.afterPhotoUrl?.trim().isNotEmpty == true;
    final hasCompleteProof = hasBeforePhoto && hasAfterPhoto;
    final hasCompleteChecklist = _checklist.every((item) => item);
    final canComplete = hasCompleteProof && hasCompleteChecklist;

    // In progress -> Upload + Selesaikan
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isUploadingBefore || _isUploadingAfter
              ? null
              : () => _pickAndUploadProof(
                  hasBeforePhoto ? TaskProofType.after : TaskProofType.before,
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            foregroundColor: AppColors.primary,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(
            'Upload Bukti Pekerjaan',
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!canComplete) ...[
          Text(
            'Lengkapi checklist dan upload bukti untuk menyelesaikan tugas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ElevatedButton(
          onPressed: _isUpdating ? null : () => _onUpdateStatus('completed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: canComplete
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.42),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            minimumSize: const Size.fromHeight(48),
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Selesaikan Tugas',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}
