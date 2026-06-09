import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/bersihuy_data_service.dart';
import '../../../shared/widgets/customer_bottom_nav.dart';

class CustomerServicesScreen extends StatefulWidget {
  const CustomerServicesScreen({super.key});

  @override
  State<CustomerServicesScreen> createState() => _CustomerServicesScreenState();
}

class _CustomerServicesScreenState extends State<CustomerServicesScreen> {
  // Dynamically built from Supabase data; categories come from the service list.
  List<String> _categories = ['Semua'];
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  // Live data from Supabase.
  List<BersihuyService> _services = [];
  List<BersihuyProduct> _products = [];

  // UI loading / error states.
  bool _isLoadingServices = true;
  bool _isLoadingProducts = true;
  String? _servicesError;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchServices(),
      _fetchProducts(),
    ]);
  }

  Future<void> _fetchServices() async {
    if (!mounted) return;
    setState(() => _isLoadingServices = true);

    try {
      final data = await BersihuyDataService.getServices();
      if (!mounted) return;

      // Build category list from fetched services.
      final cats = {'Semua'};
      for (final s in data) {
        if (s.category != null && s.category!.isNotEmpty) {
          cats.add(s.category!);
        }
      }
      final sortedCats = ['Semua', ...cats.toList()..sort()];

      setState(() {
        _services = data;
        _categories = sortedCats;
        _isLoadingServices = false;
        _servicesError = null;
      });
    } catch (e, st) {
      debugPrint('SERVICES FETCH ERROR: $e');
      debugPrint('SERVICES STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _isLoadingServices = false;
        _servicesError = 'Gagal memuat layanan: $e';
      });
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);

    try {
      final data = await BersihuyDataService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = data;
        _isLoadingProducts = false;
        _productsError = null;
      });
    } catch (e, st) {
      debugPrint('PRODUCTS FETCH ERROR: $e');
      debugPrint('PRODUCTS STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _productsError = 'Gagal memuat produk: $e';
      });
    }
  }

  // ── Filtered views ───────────────────────────────────────────────────────────

  List<BersihuyService> get _visibleServices {
    final selectedCategory =
        _categories.isNotEmpty ? _categories[_selectedCategoryIndex] : 'Semua';
    final query = _searchQuery.trim().toLowerCase();

    return _services.where((service) {
      final matchesCategory =
          selectedCategory == 'Semua' || service.category == selectedCategory;
      final matchesSearch = query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          (service.description?.toLowerCase().contains(query) ?? false) ||
          (service.category?.toLowerCase().contains(query) ?? false);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<BersihuyProduct> get _visibleProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _products;

    return _products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _showProductSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk ditambahkan ke pesanan (dummy).')),
    );
  }

  void _retryServices() => _fetchServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _PremiumCustomerBackground(
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
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 106),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pilih Layanan',
                            style: AppTextStyles.headlineLarge.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF142232),
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Temukan layanan kebersihan sesuai kebutuhanmu',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF65737D),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildCategoryChips(),
                          const SizedBox(height: 24),
                          _buildServicesSection(),
                          const SizedBox(height: 28),
                          _buildProductsSection(),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: const CustomerBottomNav(currentIndex: 1),
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
      titleSpacing: 20,
      centerTitle: false,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
      title: Image.asset(
        'assets/images/logo_full.png',
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text(
          'Bersihuy',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.customerNotifications);
          },
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: Color(0xFF172331),
            size: 22,
          ),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEAF7F5),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      cursorColor: const Color(0xFF2F8F8A),
      style: AppTextStyles.bodyMedium.copyWith(
        color: const Color(0xFF172331),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFFEFFFF),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 8),
          child: Icon(Icons.search_rounded, color: Color(0xFF6F8987), size: 21),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        hintText: 'Cari layanan kebersihan',
        hintStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          color: Color(0xFF82918F),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: const Color(0xFFDDE8E6).withValues(alpha: 0.9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: const Color(0xFFDDE8E6).withValues(alpha: 0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF2F8F8A)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = index == _selectedCategoryIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                }
              },
              labelStyle: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF65737D),
              ),
              selectedColor: const Color(0xFF2F8F8A),
              backgroundColor: const Color(0xFFFEFFFF),
              showCheckmark: false,
              elevation: isSelected ? 1 : 0,
              shadowColor: const Color(0xFF247D78).withValues(alpha: 0.08),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF2F8F8A)
                    : const Color(0xFFDDE8E6).withValues(alpha: 0.84),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildServicesSection() {
    if (_isLoadingServices) {
      return _buildLoadingState();
    }

    if (_servicesError != null) {
      return _buildErrorState(
        _servicesError!,
        onRetry: _retryServices,
      );
    }

    final services = _visibleServices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Utama',
          style: AppTextStyles.headlineSmall.copyWith(
            color: const Color(0xFF142232),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          _buildEmptyState('Belum ada layanan yang cocok.')
        else
          Column(
            children: [
              for (final service in services) ...[
                _buildServiceCard(service),
                if (service != services.last) const SizedBox(height: 16),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildServiceCard(BersihuyService service) {
    return Container(
      decoration: _cardDecoration(radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 152,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    service.imageAssetPath ?? 'assets/images/services/placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFEAF7F5),
                        child: const Icon(
                          Icons.cleaning_services_outlined,
                          color: Color(0xFF2F8F8A),
                          size: 42,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _categoryChip(service.category ?? '-'),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _ratingChip(service.formattedRating),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF172331),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  service.description ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF65737D),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Color(0xFF6F8987),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      service.formattedDuration,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF65737D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: const Color(0xFFDDE8E6).withValues(alpha: 0.72),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        service.formattedPrice,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF287A76),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        debugPrint(
                          'CustomerServicesScreen service tap: '
                          'id=${service.id}, name=${service.name}',
                        );
                        Navigator.pushNamed(
                          context,
                          AppRoutes.serviceDetail,
                          arguments: {
                            'serviceId': service.id,
                            'id': service.id,
                            'title': service.name,
                            'category': service.category ?? '',
                            'description': service.description ?? '',
                            'price': service.formattedPrice,
                            'duration': service.formattedDuration,
                            'rating': service.formattedRating,
                            'imagePath': service.imageAssetPath ?? '',
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F8F8A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Pilih',
                        style: AppTextStyles.buttonLabel.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  Widget _buildProductsSection() {
    if (_isLoadingProducts) {
      return _buildLoadingState();
    }

    if (_productsError != null) {
      return _buildErrorState(_productsError!);
    }

    final products = _visibleProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produk & Add-on Bersihuy',
          style: AppTextStyles.headlineSmall.copyWith(
            color: const Color(0xFF142232),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tambahkan aroma ruangan agar rumah, kos, atau kantor terasa lebih segar.',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            color: const Color(0xFF65737D),
          ),
        ),
        const SizedBox(height: 14),
        if (products.isEmpty)
          _buildEmptyState('Belum ada produk yang cocok.')
        else
          Column(
            children: [
              for (final product in products) ...[
                _buildProductCard(product),
                if (product != products.last) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildProductCard(BersihuyProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE8E6).withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 134,
            child: Image.asset(
              product.imageAssetPath ?? 'assets/images/products/placeholder.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFEAF7F5),
                  child: const Icon(
                    Icons.spa_outlined,
                    color: Color(0xFF2F8F8A),
                    size: 32,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF172331),
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12.5,
                      color: const Color(0xFF65737D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.formattedPrice,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF287A76),
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _showProductSnackBar,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF287A76),
                          side: BorderSide(
                            color: const Color(
                              0xFF2F8F8A,
                            ).withValues(alpha: 0.34),
                          ),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Tambah',
                          style: AppTextStyles.buttonLabel.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF287A76),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(radius: 22),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F8F8A)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, {VoidCallback? onRetry}) {
    return InkWell(
      onTap: onRetry,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(radius: 22),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB45A5A),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFB45A5A),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ketuk untuk coba lagi',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 22),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          color: const Color(0xFF65737D),
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF287A76),
        ),
      ),
    );
  }

  Widget _ratingChip(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFFFFB400)),
          const SizedBox(width: 4),
          Text(
            rating,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF172331),
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
        color: const Color(0xFFDDE8E6).withValues(alpha: 0.72),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF247D78).withValues(alpha: 0.06),
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
