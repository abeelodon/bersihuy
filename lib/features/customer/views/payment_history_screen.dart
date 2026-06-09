import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  int _activeFilterIndex = 0;
  static const _filters = ['Semua', 'Berhasil', 'Menunggu', 'Gagal'];
  static const _transactions = [
    _PaymentItem(
      title: 'Deep Cleaning',
      invoice: 'INV-BRS-000124',
      date: '26 Mei 2026',
      method: 'Midtrans',
      status: 'Berhasil',
      price: 255000,
    ),
    _PaymentItem(
      title: 'Bersih Kamar Kos',
      invoice: 'INV-BRS-000123',
      date: '24 Mei 2026',
      method: 'Midtrans',
      status: 'Berhasil',
      price: 55000,
    ),
    _PaymentItem(
      title: 'Pest Control Outdoor',
      invoice: 'INV-BRS-000122',
      date: '20 Mei 2026',
      method: 'Midtrans',
      status: 'Menunggu',
      price: 180000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _transactions.where((item) {
      if (_activeFilterIndex == 0) return true;
      return item.status == _filters[_activeFilterIndex];
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _PremiumCustomerBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildFilters(),
                      const SizedBox(height: 16),
                      if (items.isEmpty)
                        _emptyState()
                      else
                        for (final item in items) ...[
                          _buildPaymentCard(item),
                          if (item != items.last) const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
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
      titleSpacing: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Riwayat Pembayaran',
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

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pembayaran Bulan Ini',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp255.000',
            style: AppTextStyles.headlineLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryMetric('Transaksi Berhasil', '3')),
              _statusBadge('Status Aman', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _activeFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.84),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              labelStyle: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _activeFilterIndex = index);
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPaymentCard(_PaymentItem item) {
    final statusColor = _statusColor(item.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.invoice} • ${item.date}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Metode: ${item.method}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(item.status, statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatPrice(item.price),
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.invoice);
                },
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Lihat Invoice'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.outline,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 22),
      child: Text(
        'Tidak ada transaksi ${_filters[_activeFilterIndex].toLowerCase()}.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
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
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Gagal' => AppColors.error,
      'Menunggu' => const Color(0xFF9A6A00),
      _ => AppColors.primary,
    };
  }

  String _formatPrice(int price) {
    return 'Rp${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
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

class _PaymentItem {
  final String title;
  final String invoice;
  final String date;
  final String method;
  final String status;
  final int price;

  const _PaymentItem({
    required this.title,
    required this.invoice,
    required this.date,
    required this.method,
    required this.status,
    required this.price,
  });
}
