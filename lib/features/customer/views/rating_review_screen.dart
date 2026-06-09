import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../repositories/order_repository.dart';

class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({super.key});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _didReadRoute = false;
  bool _isLoadingOrder = true;
  bool _isSubmitting = false;
  bool _alreadyReviewed = false;
  String? _orderId;
  String? _resolvedStaffId;
  String? _displayedStaffName;
  String? _error;
  OrderDetail? _orderDetail;
  CustomerReview? _existingReview;

  final List<String> _tags = [
    'Tepat waktu',
    'Petugas ramah',
    'Hasil bersih',
    'Sesuai pesanan',
    'Mudah digunakan',
  ];

  final Set<String> _selectedTags = {'Petugas ramah', 'Sesuai pesanan'};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadRoute) return;
    _didReadRoute = true;
    _loadOrder();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Sangat Kecewa';
      case 2:
        return 'Kecewa';
      case 3:
        return 'Cukup Puas';
      case 4:
        return 'Puas';
      case 5:
        return 'Sangat Puas';
      default:
        return '';
    }
  }

  Future<void> _loadOrder() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final orderId = args is Map ? args['orderId'] as String? : null;

    if (orderId == null || orderId.trim().isEmpty) {
      setState(() {
        _error = 'Order ID kosong saat membuka ulasan.';
        _isLoadingOrder = false;
      });
      return;
    }

    debugPrint('ReviewScreen received orderId=${orderId.trim()}');

    setState(() {
      _orderId = orderId.trim();
      _isLoadingOrder = true;
      _error = null;
    });

    try {
      final repository = const OrderRepository();
      final detail = await repository.getOrderWithDetails(orderId.trim());
      final existingReview = await repository.getReviewForOrder(orderId.trim());
      final resolvedStaffId = detail?.assignedStaffId?.trim();
      final displayedStaffName = detail?.hasAssignedStaff == true
          ? detail!.assignedStaffName!.trim()
          : 'Data petugas belum tersedia';
      debugPrint(
        'ReviewScreen fetched order result: '
        'id=${detail?.order.id}, number=${detail?.order.orderNumber}, '
        'status=${detail?.order.status}',
      );
      debugPrint(
        'ReviewScreen fetched task result: '
        'id=${detail?.taskId}, status=${detail?.taskStatus}',
      );
      debugPrint(
        'ReviewScreen proof URLs: '
        'before_photo_url=${detail?.beforePhotoUrl}, '
        'after_photo_url=${detail?.afterPhotoUrl}',
      );
      debugPrint('ReviewScreen fetched task.staff_id=$resolvedStaffId');
      debugPrint(
        'ReviewScreen fetched staff profile result=${detail?.assignedStaffName}',
      );
      debugPrint('ReviewScreen final displayed staff name=$displayedStaffName');
      if (detail?.order.status == 'completed' &&
          (detail?.taskId == null ||
              resolvedStaffId == null ||
              resolvedStaffId.isEmpty)) {
        debugPrint(
          'WARNING: completed order has no task/staff_id: ${orderId.trim()}',
        );
      }
      if (!mounted) return;
      setState(() {
        _orderDetail = detail;
        _resolvedStaffId = resolvedStaffId;
        _displayedStaffName = displayedStaffName;
        _existingReview = existingReview;
        _alreadyReviewed = existingReview != null;
        _error = detail == null
            ? 'Data pesanan tidak ditemukan.'
            : detail.order.status != 'completed'
            ? 'Ulasan hanya dapat diberikan setelah layanan selesai.'
            : null;
        _isLoadingOrder = false;
      });
    } catch (e) {
      debugPrint('RatingReviewScreen: failed to load order — $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data pesanan.';
        _isLoadingOrder = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final orderId = _orderId;
    final detail = _orderDetail;
    if (orderId == null || orderId.isEmpty || detail == null) return;
    if (detail.order.status != 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ulasan dapat diberikan setelah layanan selesai.'),
        ),
      );
      return;
    }
    if (_alreadyReviewed) {
      final review =
          _existingReview ??
          await const OrderRepository().getReviewForOrder(orderId);
      if (!mounted) return;
      if (review != null) {
        setState(() {
          _existingReview = review;
          _alreadyReviewed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ulasan untuk pesanan ini sudah dikirim.'),
          ),
        );
        _showReviewDetail(review);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan tidak ditemukan.')),
        );
      }
      return;
    }
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating harus bernilai 1 sampai 5.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = const OrderRepository();
      final existingReview = await repository.getReviewForOrder(orderId);
      if (!mounted) return;
      if (existingReview != null) {
        setState(() {
          _isSubmitting = false;
          _alreadyReviewed = true;
          _existingReview = existingReview;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ulasan untuk pesanan ini sudah dikirim.'),
          ),
        );
        _showReviewDetail(existingReview);
        return;
      }

      final tagText = _selectedTags.isEmpty ? '' : _selectedTags.join(', ');
      final typedComment = _reviewController.text.trim();
      final comment = [
        if (typedComment.isNotEmpty) typedComment,
        if (tagText.isNotEmpty) 'Tag: $tagText',
      ].join('\n');
      final staffId = _resolvedStaffId;
      if (staffId == null || staffId.trim().isEmpty) {
        debugPrint('WARNING: completed order has no task/staff_id: $orderId');
      }
      final createdReview = await repository.submitReview(
        orderId: orderId,
        staffId: staffId,
        rating: _rating,
        comment: comment,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _alreadyReviewed = true;
        _existingReview = createdReview;
      });
    } on DuplicateReviewException catch (e) {
      debugPrint('RatingReviewScreen: duplicate review - $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _alreadyReviewed = true;
        _existingReview = e.review;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ulasan untuk pesanan ini sudah dikirim.'),
        ),
      );
      _showReviewDetail(e.review);
      return;
    } catch (e) {
      debugPrint('RatingReviewScreen: submit failed — $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim ulasan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ulasan berhasil dikirim')));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Ulasan Terkirim',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: const Text(
            'Terima kasih! Ulasan Anda sangat berharga bagi kami untuk terus meningkatkan kualitas layanan Bersihuy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Pop Dialog
                  Navigator.pop(context);
                  // Pop RatingReviewScreen back to tracking or previous screen
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
                child: const Text('Kembali'),
              ),
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
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Beri Ulasan',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            child: _isLoadingOrder
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : _error != null
                ? _buildErrorState()
                : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          right: 20.0,
                          top: 16.0,
                          bottom: 160.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildOrderSummaryCard(),
                            const SizedBox(height: 16),
                            _buildRatingSection(),
                            const SizedBox(height: 20),
                            _buildReviewInputSection(),
                            const SizedBox(height: 20),
                            _buildProofSection(),
                          ],
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
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Terjadi kesalahan.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final detail = _orderDetail;
    final staffName = _displayedStaffName ?? 'Data petugas belum tersedia';
    final initials = _initials(staffName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  detail?.serviceName ?? 'Layanan Bersihuy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _statusLabel(detail?.order.status ?? 'completed'),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.outline),
              const SizedBox(width: 4),
              Text(
                detail != null ? _formatSchedule(detail) : '-',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, color: AppColors.outlineVariant),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail?.order.serviceAddress ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Petugas',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            staffName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Bagaimana layanan kami?',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Beri penilaian untuk membantu kami menjaga kualitas layanan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= _rating;
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = starIndex;
                  });
                },
                icon: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  size: 40,
                  color: isFilled
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _ratingLabel,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'completed' => 'Selesai',
      'in_progress' => 'Dalam Proses',
      'scheduled' => 'Dijadwalkan',
      'paid' => 'Dibayar',
      'pending_payment' => 'Menunggu Pembayaran',
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

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == 'Data petugas belum tersedia') return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildReviewInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ulasan',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          maxLines: 4,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Ceritakan pengalaman Anda menggunakan layanan Bersihuy',
            hintStyle: const TextStyle(
              color: AppColors.outlineVariant,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Chips/Tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProofSection() {
    final detail = _orderDetail;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bukti Pekerjaan',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                'Dari petugas',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProofThumbnail(
                  title: 'Sebelum',
                  imageUrl: detail?.beforePhotoUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProofThumbnail(
                  title: 'Sesudah',
                  imageUrl: detail?.afterPhotoUrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProofThumbnail({
    required String title,
    required String? imageUrl,
  }) {
    final hasImage = imageUrl?.trim().isNotEmpty == true;
    return Container(
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl!,
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
                  size: 32,
                  color: AppColors.outline,
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 32,
                    color: AppColors.outline.withValues(alpha: 0.72),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Belum diunggah',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDetail(CustomerReview review) {
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
                    const Text(
                      'Ulasan Kamu',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                _reviewDetailRow('Pesanan', review.orderNumber ?? '-'),
                _reviewDetailRow(
                  'Layanan',
                  review.serviceName ?? 'Layanan Bersihuy',
                ),
                _reviewDetailRow(
                  'Petugas',
                  review.staffName ?? 'Data petugas belum tersedia',
                ),
                _reviewDetailRow('Tanggal', _formatDateTime(review.createdAt)),
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

  String _formatDateTime(DateTime? value) {
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

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : _alreadyReviewed
                ? () async {
                    final review =
                        _existingReview ??
                        await const OrderRepository().getReviewForOrder(
                          _orderId ?? '',
                        );
                    if (!mounted) return;
                    if (review == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ulasan tidak ditemukan.'),
                        ),
                      );
                      return;
                    }
                    setState(() => _existingReview = review);
                    _showReviewDetail(review);
                  }
                : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shadowColor: Colors.black26,
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
                    _alreadyReviewed ? 'Lihat Ulasan' : 'Kirim Ulasan',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.outline,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text(
              'Lewati dulu',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
