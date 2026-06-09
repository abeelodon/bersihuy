import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../repositories/order_repository.dart';

class BantuanKeluhanScreen extends StatefulWidget {
  const BantuanKeluhanScreen({super.key});

  @override
  State<BantuanKeluhanScreen> createState() => _BantuanKeluhanScreenState();
}

class _BantuanKeluhanScreenState extends State<BantuanKeluhanScreen> {
  static const _repository = OrderRepository();
  List<CustomerComplaint> _complaints = [];
  bool _isLoadingComplaints = true;
  String? _complaintsError;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Cara memesan layanan',
      'answer':
          'Buka menu "Layanan" dari bilah navigasi bawah, pilih kategori layanan yang Anda butuhkan (seperti Bersih Kamar Kos atau Deep Cleaning), tentukan tipe tempat, jadwal pengerjaan, dan selesaikan pembayaran aman via Midtrans.',
    },
    {
      'question': 'Cara pembayaran',
      'answer':
          'Pembayaran dilakukan secara instan melalui sistem terintegrasi Midtrans. Kami menerima pembayaran via QRIS, GoPay, Transfer Bank (Virtual Account Mandiri, BCA, BRI, BNI), serta kartu kredit.',
    },
    {
      'question': 'Ubah jadwal pesanan',
      'answer':
          'Anda dapat mengajukan perubahan jadwal pembersihan melalui admin WhatsApp paling lambat 24 jam sebelum pembersihan awal dimulai tanpa biaya tambahan.',
    },
    {
      'question': 'Masalah dengan petugas',
      'answer':
          'Keamanan dan kenyamanan Anda adalah prioritas kami. Jika petugas kami kurang sopan atau melakukan kelalaian pengerjaan, segera gunakan tombol "Ajukan Keluhan Baru" di bawah ini untuk melaporkannya langsung ke tim manajemen kami.',
    },
    {
      'question': 'Refund dan pembatalan',
      'answer':
          'Pembatalan pesanan yang diajukan lebih dari 24 jam sebelum jadwal akan mendapatkan refund penuh 100%. Pembatalan kurang dari 12 jam dikenakan biaya administrasi 50%. Proses refund memakan waktu 3-5 hari kerja.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoadingComplaints = true;
      _complaintsError = null;
    });

    try {
      final complaints = await _repository.getCustomerComplaints();
      if (!mounted) return;
      setState(() {
        _complaints = complaints;
        _isLoadingComplaints = false;
      });
    } catch (e, st) {
      debugPrint('BantuanKeluhanScreen complaints fetch error: $e');
      debugPrint('BantuanKeluhanScreen complaints stacktrace: $st');
      if (!mounted) return;
      setState(() {
        _complaintsError = 'Gagal memuat riwayat keluhan.';
        _isLoadingComplaints = false;
      });
    }
  }

  void _showFaqBottomSheet(String question, String answer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Bantuan',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  answer,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
          'Bantuan & Keluhan',
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
            child: Stack(
              children: [
                // Scrollable main content
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: 16.0,
                    bottom: 120.0, // Space for fixed bottom button
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Help Contact Card
                      _buildHelpContactCard(),
                      const SizedBox(height: 20),

                      // Quick Help Topics
                      _buildFaqSection(),
                      const SizedBox(height: 20),

                      // Complaint History
                      _buildComplaintHistorySection(),
                    ],
                  ),
                ),

                // Fixed Bottom Button
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFixedBottomAction(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                  Icons.support_agent,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Butuh bantuan?',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tim Bersihuy siap membantu kendala layanan kamu.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menghubungi Admin via WhatsApp...'),
                ),
              );
            },
            icon: const Icon(Icons.forum_outlined, size: 18),
            label: const Text('Hubungi Admin via WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: const Text(
              'Topik Bantuan Cepat',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              return ListTile(
                onTap: () =>
                    _showFaqBottomSheet(faq['question']!, faq['answer']!),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  faq['question']!,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.outlineVariant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Keluhan',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingComplaints)
          _buildComplaintLoadingCard()
        else if (_complaintsError != null)
          _buildComplaintErrorCard()
        else if (_complaints.isEmpty)
          _buildComplaintEmptyCard()
        else
          for (final complaint in _complaints) ...[
            _buildComplaintCard(complaint),
            if (complaint != _complaints.last) const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildComplaintLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _complaintCardDecoration(),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _buildComplaintErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _complaintCardDecoration(),
      child: Column(
        children: [
          Text(
            _complaintsError ?? 'Gagal memuat riwayat keluhan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadComplaints,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _complaintCardDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.support_agent_outlined,
            color: AppColors.outline,
            size: 30,
          ),
          SizedBox(height: 10),
          Text(
            'Belum ada keluhan',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Riwayat keluhan akan muncul setelah kamu mengirim keluhan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(CustomerComplaint complaint) {
    final statusColor = _complaintStatusColor(complaint.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _complaintCardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cleaning_services,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.serviceName,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(complaint.createdAt),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  complaint.statusLabel,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori Keluhan:',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  complaint.category,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: AppColors.outlineVariant),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showComplaintDetail(complaint),
                child: const Text(
                  'Lihat Detail',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _complaintCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }

  void _showComplaintDetail(CustomerComplaint complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Keluhan',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _complaintDetailRow('Pesanan', complaint.orderNumber ?? '-'),
                _complaintDetailRow('Layanan', complaint.serviceName),
                _complaintDetailRow('Kategori', complaint.category),
                _complaintDetailRow('Status', complaint.statusLabel),
                _complaintDetailRow(
                  'Tanggal',
                  _formatDate(complaint.createdAt),
                ),
                const SizedBox(height: 10),
                _complaintTextBlock('Deskripsi', complaint.description),
                if (complaint.resolutionNote != null &&
                    complaint.resolutionNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _complaintTextBlock(
                    'Catatan Resolusi',
                    complaint.resolutionNote!.trim(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _complaintDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _complaintTextBlock(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _complaintStatusColor(String status) {
    return switch (status) {
      'resolved' => Colors.green,
      'rejected' => AppColors.error,
      'in_review' => AppColors.primary,
      _ => Colors.amber,
    };
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

  Widget _buildFixedBottomAction() {
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
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.complaint);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Ajukan Keluhan Baru',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
