import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../repositories/order_repository.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  String _selectedCategory = 'Hasil kurang bersih';
  final _detailController = TextEditingController();
  String? _simulatedPhotoPath;
  int _contactPreference = 0;
  bool _didReadRoute = false;
  bool _isLoadingOrder = true;
  bool _isSubmitting = false;
  String? _orderId;
  OrderDetail? _orderDetail;
  String? _error;

  final List<String> _categories = [
    'Petugas terlambat',
    'Hasil kurang bersih',
    'Jadwal bermasalah',
    'Pembayaran',
    'Lainnya',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadRoute) return;
    _didReadRoute = true;
    _loadOrder();
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final orderId = args is Map ? args['orderId'] as String? : null;

    if (orderId == null || orderId.trim().isEmpty) {
      setState(() {
        _orderId = null;
        _error = 'Order ID kosong saat membuka keluhan.';
        _isLoadingOrder = false;
      });
      return;
    }

    setState(() {
      _orderId = orderId.trim();
      _isLoadingOrder = true;
      _error = null;
    });

    try {
      final detail = await const OrderRepository().getOrderWithDetails(orderId.trim());
      if (!mounted) return;
      setState(() {
        _orderDetail = detail;
        _error = detail == null ? 'Data pesanan tidak ditemukan.' : null;
        _isLoadingOrder = false;
      });
    } catch (e) {
      debugPrint('ComplaintScreen: failed to load order — $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data pesanan.';
        _isLoadingOrder = false;
      });
    }
  }

  Future<void> _submitComplaint() async {
    final orderId = _orderId;
    final description = _detailController.text.trim();
    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID kosong saat mengirim keluhan.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detail keluhan wajib diisi.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await const OrderRepository().submitComplaint(
        orderId: orderId,
        category: _selectedCategory,
        description: description,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    } catch (e) {
      debugPrint('ComplaintScreen: submit failed — $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim keluhan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Keluhan Dikirim',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          content: Text(
            _contactPreference == 0
                ? 'Keluhan kamu telah kami terima. Tim Bersihuy akan menghubungi kamu secepatnya melalui WhatsApp untuk penyelesaian masalah.'
                : 'Keluhan kamu telah kami terima. Tim Bersihuy akan segera mengirimkan pesan tanggapan di kotak masuk aplikasi kamu.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
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
              child: _isLoadingOrder
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : _error != null
                      ? _buildErrorState()
                      : Stack(
                          children: [
                            ScrollConfiguration(
                              behavior: ScrollConfiguration.of(
                                context,
                              ).copyWith(scrollbars: false),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(22, 18, 22, 162),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildOrderSummaryCard(),
                                    const SizedBox(height: 18),
                                    _buildCategorySection(),
                                    const SizedBox(height: 18),
                                    _buildDetailSection(),
                                    const SizedBox(height: 18),
                                    _buildEvidenceSection(),
                                    const SizedBox(height: 18),
                                    _buildFollowUpSection(),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _buildBottomActions(),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(radius: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 38),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Terjadi kesalahan.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadOrder,
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
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Ajukan Keluhan',
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

  Widget _buildOrderSummaryCard() {
    final detail = _orderDetail;
    final staffName = detail?.hasAssignedStaff == true
        ? detail!.assignedStaffName!
        : 'Menunggu penugasan';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail?.serviceName ?? 'Layanan Bersihuy',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _statusBadge(_statusLabel(detail?.order.status ?? '-')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.outline,
              ),
              const SizedBox(width: 5),
              Text(
                detail != null ? _formatSchedule(detail) : '-',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          Row(
            children: [
              Expanded(child: _summaryMeta('Lokasi', detail?.order.serviceAddress ?? '-')),
              const SizedBox(width: 16),
              Expanded(child: _summaryMeta('Petugas', staffName)),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'created' => 'Dibuat',
      'pending_payment' => 'Menunggu Pembayaran',
      'paid' => 'Dibayar',
      'scheduled' => 'Dijadwalkan',
      'in_progress' => 'Dalam Proses',
      'completed' => 'Selesai',
      'cancelled' => 'Dibatalkan',
      _ => status,
    };
  }

  String _formatSchedule(OrderDetail detail) {
    final date = detail.order.scheduleDate;
    final time = detail.order.scheduleTime;
    if (date == null && (time == null || time.isEmpty)) {
      return 'Belum dijadwalkan';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final dateText = date != null
        ? '${date.day} ${months[date.month - 1]} ${date.year}'
        : null;
    if (dateText != null && time != null && time.isNotEmpty) {
      return '$dateText, $time';
    }
    return dateText ?? time ?? 'Belum dijadwalkan';
  }

  Widget _buildCategorySection() {
    return _sectionShell(
      title: 'Jenis Keluhan',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categories.map((category) {
          final isSelected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              }
            },
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            labelStyle: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailSection() {
    return _sectionShell(
      title: 'Detail Keluhan',
      child: TextField(
        controller: _detailController,
        maxLines: 4,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: 'Jelaskan kendala yang kamu alami',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.outline,
          ),
          filled: true,
          fillColor: const Color(0xFFFAFCFC),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return _sectionShell(
      title: 'Bukti Pendukung',
      subtitle: 'Tambahkan foto jika diperlukan',
      child: _simulatedPhotoPath == null ? _uploadBox() : _uploadedFileCard(),
    );
  }

  Widget _uploadBox() {
    return InkWell(
      onTap: () {
        setState(() {
          _simulatedPhotoPath = 'bukti_kebersihan_kos.jpg';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto bukti terpilih (Simulasi)')),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 104,
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Upload Foto',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadedFileCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.image_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _simulatedPhotoPath!,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1.2 MB',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _simulatedPhotoPath = null;
              });
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpSection() {
    return _sectionShell(
      title: 'Tindak Lanjut',
      child: Row(
        children: [
          Expanded(
            child: _buildFollowUpCard(
              index: 0,
              icon: Icons.chat_rounded,
              title: 'WhatsApp',
              subtitle: 'Hubungi lewat WhatsApp',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFollowUpCard(
              index: 1,
              icon: Icons.notifications_active_rounded,
              title: 'Aplikasi',
              subtitle: 'Hubungi lewat aplikasi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _contactPreference == index;

    return InkWell(
      onTap: () {
        setState(() {
          _contactPreference = index;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 112,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFFAFCFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.8),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.outline,
                ),
                Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: isSelected ? 5 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tim Bersihuy akan meninjau keluhan kamu dan memberikan tindak lanjut secepatnya.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitComplaint,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Kirim Keluhan',
                    style: AppTextStyles.buttonLabel.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionShell({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _summaryMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
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
