import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/bersihuy_data_service.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _addressController = TextEditingController(text: 'Jl. Sudirman No. 45');
  final _notesController = TextEditingController();
  String _staffPreference = 'Bebas';
  String? _selectedScent;
  final Set<int> _selectedAddOnIndexes = {};
  bool _didReadRoute = false;
  bool _isLoadingService = true;
  String? _serviceError;
  _SelectedService? _service;
  List<_AddOnItem> _paidAddOns = [];
  bool _isLoadingAddOns = true;
  String? _addOnsError;

  static const int _adminFee = 5000;
  static const _scents = [
    'Fresh Linen',
    'Lavender Bloom',
    'Citrus Peach',
    'Clean Tea',
  ];

  @override
  void initState() {
    super.initState();
    _loadAddOns();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadRoute) return;
    _didReadRoute = true;
    _loadServiceFromRoute();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadServiceFromRoute() {
    final args = ModalRoute.of(context)?.settings.arguments;
    final routeService = _SelectedService.fromRouteArgs(args);
    final serviceId = _SelectedService.serviceIdFromRouteArgs(args);

    debugPrint(
      'SERVICE DETAIL OPEN: serviceId=$serviceId, '
      'serviceName=${routeService?.title ?? '-'}',
    );

    setState(() {
      _service = routeService;
      _isLoadingService = routeService == null && serviceId != null;
      _serviceError = routeService == null && serviceId == null
          ? 'Layanan tidak ditemukan.'
          : null;
    });

    if (serviceId != null) {
      _fetchServiceById(serviceId, fallback: routeService);
    }
  }

  Future<void> _fetchServiceById(
    String serviceId, {
    _SelectedService? fallback,
  }) async {
    try {
      final service = await BersihuyDataService.getServiceById(serviceId);
      if (!mounted) return;

      if (service == null) {
        setState(() {
          _service = fallback;
          _serviceError = fallback == null ? 'Layanan tidak ditemukan.' : null;
          _isLoadingService = false;
        });
        return;
      }

      setState(() {
        _service = _SelectedService.fromService(service);
        _serviceError = null;
        _isLoadingService = false;
      });
    } catch (e, st) {
      debugPrint('SERVICE DETAIL FETCH ERROR: $e');
      debugPrint('SERVICE DETAIL FETCH STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _service = fallback;
        _serviceError = fallback == null ? 'Gagal memuat layanan.' : null;
        _isLoadingService = false;
      });
    }
  }

  Future<void> _loadAddOns() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAddOns = true;
      _addOnsError = null;
    });

    try {
      final products = await BersihuyDataService.getProducts();
      if (!mounted) return;
      setState(() {
        _paidAddOns = products
            .where((product) => product.isAddon || product.price > 0)
            .map(_AddOnItem.fromProduct)
            .toList();
        _selectedAddOnIndexes.removeWhere((index) => index >= _paidAddOns.length);
        _isLoadingAddOns = false;
      });
    } catch (e, st) {
      debugPrint('SERVICE DETAIL ADDONS FETCH ERROR: $e');
      debugPrint('SERVICE DETAIL ADDONS FETCH STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _addOnsError = 'Gagal memuat produk add-on.';
        _isLoadingAddOns = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    if (service == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _PremiumFlowBackground(
          child: SafeArea(
            child: Center(
              child: _isLoadingService
                  ? const CircularProgressIndicator(strokeWidth: 2.5)
                  : _buildUnavailableState(
                      _serviceError ?? 'Layanan tidak ditemukan.',
                    ),
            ),
          ),
        ),
      );
    }

    final formattedDate = _selectedDate == null
        ? 'Pilih tanggal'
        : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
    final formattedTime = _selectedTime == null
        ? 'Pilih jam'
        : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    final showScentSelection = service.supportsScentSelection;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _PremiumFlowBackground(
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
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 118),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildServiceHero(service),
                          const SizedBox(height: 24),
                          _buildBookingForm(formattedDate, formattedTime),
                          const SizedBox(height: 24),
                          if (showScentSelection) ...[
                            _buildScentSelectionSection(),
                            const SizedBox(height: 24),
                          ],
                          _buildAddOnsSection(),
                          const SizedBox(height: 24),
                          _buildPaymentSummaryCard(service),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomActionArea(service),
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
      titleSpacing: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Detail Layanan',
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

  Widget _buildUnavailableState(String message) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(22),
        decoration: _cardDecoration(radius: 22),
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
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHero(_SelectedService service) {
    return Container(
      decoration: _cardDecoration(radius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 210,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    service.imagePath.isNotEmpty
                        ? service.imagePath
                        : 'assets/images/services/placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFEAF7F5),
                        child: const Icon(
                          Icons.cleaning_services_outlined,
                          color: AppColors.primary,
                          size: 52,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: _softBadge(service.category),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _ratingBadge(service.rating),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metaPill(Icons.schedule_rounded, service.duration),
                    const SizedBox(width: 8),
                    _metaPill(Icons.star_rounded, service.rating),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  service.price,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  color: AppColors.outlineVariant.withValues(alpha: 0.7),
                  height: 1,
                ),
                const SizedBox(height: 14),
                Text(
                  service.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.48,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm(String formattedDate, String formattedTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Pemesanan',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPickerField(
                label: 'Pilih tanggal',
                value: formattedDate,
                icon: Icons.calendar_today_outlined,
                isPlaceholder: _selectedDate == null,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 14),
              _buildPickerField(
                label: 'Pilih jam',
                value: formattedTime,
                icon: Icons.schedule_outlined,
                isPlaceholder: _selectedTime == null,
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Masukkan alamat lengkap'),
              const SizedBox(height: 7),
              _textField(
                controller: _addressController,
                hintText: 'Contoh: Jl. Sudirman No. 1',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _fieldLabel('Preferensi petugas'),
              const SizedBox(height: 7),
              DropdownButtonFormField<String>(
                initialValue: _staffPreference,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.outline,
                ),
                decoration: _inputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Bebas', child: Text('Bebas')),
                  DropdownMenuItem(
                    value: 'Laki-laki',
                    child: Text('Laki-laki'),
                  ),
                  DropdownMenuItem(
                    value: 'Perempuan',
                    child: Text('Perempuan'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _staffPreference = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              _fieldLabel('Catatan tambahan'),
              const SizedBox(height: 7),
              _textField(
                controller: _notesController,
                hintText: 'Ada instruksi khusus?',
                icon: Icons.edit_note_outlined,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 7),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: _inputBoxDecoration(),
            child: Row(
              children: [
                Icon(icon, color: AppColors.outline, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isPlaceholder
                          ? AppColors.outline
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScentSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Aroma Ruangan',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gratis untuk layanan kebersihan tertentu.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(radius: 22),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _scents.map((scent) {
              final isSelected = _selectedScent == scent;
              return ChoiceChip(
                label: Text('$scent - Rp0'),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    _selectedScent = selected ? scent : null;
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFFAFCFC),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAddOnsSection() {
    Widget content;
    if (_isLoadingAddOns) {
      content = _buildInlineState(
        icon: Icons.hourglass_empty_rounded,
        message: 'Memuat produk add-on...',
      );
    } else if (_addOnsError != null) {
      content = _buildInlineState(
        icon: Icons.error_outline_rounded,
        message: _addOnsError!,
        onTap: _loadAddOns,
      );
    } else if (_paidAddOns.isEmpty) {
      content = _buildInlineState(
        icon: Icons.inventory_2_outlined,
        message: 'Belum ada produk add-on tersedia.',
      );
    } else {
      content = SizedBox(
        height: 202,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _paidAddOns.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return _buildAddOnCard(index, _paidAddOns[index]);
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tambah Produk & Add-on',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lengkapi pesanan dengan produk Bersihuy.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildInlineState({
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
            Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
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

  Widget _buildAddOnCard(int index, _AddOnItem addOn) {
    final isSelected = _selectedAddOnIndexes.contains(index);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAddOnIndexes.remove(index);
          } else {
            _selectedAddOnIndexes.add(index);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFFEFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.72),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF247D78).withValues(alpha: 0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
              child: SizedBox(
                height: 92,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      addOn.imagePath.isNotEmpty
                          ? addOn.imagePath
                          : 'assets/images/products/placeholder.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFEAF7F5),
                          child: const Icon(
                            Icons.spa_outlined,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addOn.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(addOn.price),
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSelected ? 'Dipilih' : 'Tambah',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.primary : AppColors.outline,
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

  Widget _buildPaymentSummaryCard(_SelectedService service) {
    final addOns = _selectedAddOns;
    final total = _calculateTotal(service);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rincian Pembayaran',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(radius: 22),
          child: Column(
            children: [
              _summaryRow(
                'Layanan (${service.title})',
                _formatRupiah(service.priceAmount),
              ),
              const SizedBox(height: 12),
              _summaryRow('Biaya admin', _formatRupiah(_adminFee)),
              if (_selectedScent != null) ...[
                const SizedBox(height: 12),
                _summaryRow('Aroma $_selectedScent', _formatRupiah(0)),
              ],
              for (final addOn in addOns) ...[
                const SizedBox(height: 12),
                _summaryRow(addOn.title, _formatRupiah(addOn.price)),
              ],
              const SizedBox(height: 14),
              Divider(
                color: AppColors.outlineVariant.withValues(alpha: 0.7),
                height: 1,
              ),
              const SizedBox(height: 14),
              _summaryRow('Total', _formatRupiah(total), isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionArea(_SelectedService service) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
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
      child: ElevatedButton(
        onPressed: () {
          _debugCheckoutTotal(service);
          Navigator.pushNamed(
            context,
            AppRoutes.payment,
            arguments: _buildPaymentSummary(service),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Lanjut ke Pembayaran',
          style: AppTextStyles.buttonLabel.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required int maxLines,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface),
      decoration: _inputDecoration(
        hintText: hintText,
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: maxLines > 1 ? 20 : 0,
          ),
          child: Icon(icon, color: AppColors.outline, size: 20),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.outline),
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      filled: true,
      fillColor: const Color(0xFFFAFCFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFAFCFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isTotal ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: isTotal ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  List<_AddOnItem> get _selectedAddOns {
    final sortedIndexes = _selectedAddOnIndexes.toList()..sort();
    return sortedIndexes
        .where((index) => index >= 0 && index < _paidAddOns.length)
        .map((index) => _paidAddOns[index])
        .toList();
  }

  int _calculateTotal(_SelectedService service) {
    final addOnsTotal = _selectedAddOns.fold<int>(
      0,
      (total, addOn) => total + addOn.price,
    );
    return service.priceAmount + _adminFee + addOnsTotal;
  }

  Map<String, Object?> _buildPaymentSummary(_SelectedService service) {
    final selectedAddOns = _selectedAddOns;
    return {
      'serviceId': service.id,
      'serviceName': service.title,
      'serviceCategory': service.category,
      'servicePrice': service.priceAmount,
      'serviceDuration': service.duration,
      'adminFee': _adminFee,
      'selectedScentName': _selectedScent,
      'selectedScentPrice': 0,
      'selectedAddOns': selectedAddOns
          .map((addOn) => {
                'productId': addOn.productId,
                'title': addOn.title,
                'price': addOn.price,
              })
          .toList(),
      'total': _calculateTotal(service),
      'scheduleDate': _selectedDate,
      'scheduleTime': _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'schedule': _selectedDate == null || _selectedTime == null
          ? 'Hari ini, 14.00'
          : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}, ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
      'location': _addressController.text.trim().isEmpty
          ? 'Jln. Sudirman No. 45, Semarang'
          : _addressController.text.trim(),
      'customerNote': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };
  }

  void _debugCheckoutTotal(_SelectedService service) {
    final addOnTotal = _selectedAddOns.fold<int>(
      0,
      (total, addOn) => total + addOn.price,
    );
    final subtotal = service.priceAmount + addOnTotal;
    final total = subtotal + _adminFee;
    debugPrint(
      'CHECKOUT TOTAL: serviceId=${service.id}, service=${service.title}, '
      'servicePrice=${service.priceAmount}, addOns=$addOnTotal, '
      'subtotal=$subtotal, admin=$_adminFee, discount=0, total=$total',
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final positionFromEnd = digits.length - index;
      buffer.write(digits[index]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp$buffer';
  }

  Widget _softBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _ratingBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFFFFB400), size: 14),
          const SizedBox(width: 4),
          Text(
            rating,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
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

class _SelectedService {
  final String? id;
  final String title;
  final String category;
  final String price;
  final String duration;
  final String rating;
  final String imagePath;
  final String description;

  const _SelectedService({
    this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.duration,
    required this.rating,
    required this.imagePath,
    required this.description,
  });

  factory _SelectedService.fromService(BersihuyService service) {
    return _SelectedService(
      id: service.id,
      title: service.name,
      category: service.category ?? '',
      price: service.formattedPrice,
      duration: service.formattedDuration,
      rating: service.formattedRating,
      imagePath: service.imageAssetPath ?? '',
      description: service.description ?? '',
    );
  }

  static _SelectedService? fromRouteArgs(Object? args) {
    if (args is! Map) return null;

    String? read(String key) {
      final value = args[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    final title = read('title') ?? read('name');
    if (title == null) return null;

    String readRequired(String key, String fallbackValue) {
      return read(key) ?? fallbackValue;
    }

    String priceText() {
      final value = args['price'];
      if (value is String && value.isNotEmpty) return value;
      if (value is int) return _formatRupiah(value);
      final basePrice = args['basePrice'];
      if (basePrice is int) return _formatRupiah(basePrice);
      return 'Rp0';
    }

    return _SelectedService(
      id: serviceIdFromRouteArgs(args),
      title: title,
      category: readRequired('category', ''),
      price: priceText(),
      duration: readRequired('duration', 'N/A'),
      rating: readRequired('rating', '-'),
      imagePath: readRequired('imagePath', ''),
      description: readRequired('description', ''),
    );
  }

  static String? serviceIdFromRouteArgs(Object? args) {
    if (args is! Map) return null;
    final serviceId = args['serviceId'];
    if (serviceId is String && serviceId.trim().isNotEmpty) {
      return serviceId.trim();
    }
    final id = args['id'];
    if (id is String && id.trim().isNotEmpty) {
      return id.trim();
    }
    return null;
  }

  int get priceAmount => _parseRupiah(price);

  bool get supportsScentSelection {
    return category == 'Kos' || category == 'Rumah' || category == 'Kantor';
  }

  static int _parseRupiah(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  static String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final positionFromEnd = digits.length - index;
      buffer.write(digits[index]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp$buffer';
  }
}

class _AddOnItem {
  final String productId;
  final String title;
  final int price;
  final String imagePath;

  const _AddOnItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.imagePath,
  });

  factory _AddOnItem.fromProduct(BersihuyProduct product) {
    return _AddOnItem(
      productId: product.id,
      title: product.name,
      price: product.price,
      imagePath: product.imageAssetPath ?? '',
    );
  }
}
