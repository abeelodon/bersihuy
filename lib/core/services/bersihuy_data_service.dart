import '../../core/services/supabase_service.dart';

/// Data model representing a service from Supabase.
class BersihuyService {
  final String id;
  final String name;
  final String? slug;
  final String? category;
  final String? description;
  final int basePrice;
  final int? durationMinutes;
  final double? rating;
  final String? imageAssetPath;

  const BersihuyService({
    required this.id,
    required this.name,
    this.slug,
    this.category,
    this.description,
    required this.basePrice,
    this.durationMinutes,
    this.rating,
    this.imageAssetPath,
  });

  factory BersihuyService.fromMap(Map<String, Object?> map) {
    return BersihuyService(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String?,
      category: map['category'] as String?,
      description: map['description'] as String?,
      basePrice: (map['base_price'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt(),
      rating: (map['rating'] as num?)?.toDouble(),
      imageAssetPath: map['image_asset_path'] as String?,
    );
  }

  String get formattedPrice => _formatRupiah(basePrice);

  String get formattedDuration {
    if (durationMinutes == null) return 'N/A';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours-$hours.jam';
    } else if (hours > 0) {
      return '$hours-${hours + 1} jam';
    } else {
      return '$minutes menit';
    }
  }

  String get formattedRating => rating?.toStringAsFixed(1) ?? '-';

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer('Rp');
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }
}

/// Data model representing a product/add-on from Supabase.
class BersihuyProduct {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final int price;
  final bool isAddon;
  final String? imageAssetPath;

  const BersihuyProduct({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    required this.price,
    this.isAddon = false,
    this.imageAssetPath,
  });

  factory BersihuyProduct.fromMap(Map<String, Object?> map) {
    return BersihuyProduct(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String?,
      description: map['description'] as String?,
      price: (map['price'] as num?)?.toInt() ?? 0,
      isAddon: map['is_addon'] as bool? ?? false,
      imageAssetPath: map['image_asset_path'] as String?,
    );
  }

  String get formattedPrice => _formatRupiah(price);

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer('Rp');
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }
}

/// Service for fetching cleaning services and products from Supabase.
class BersihuyDataService {
  BersihuyDataService._();

  /// Fetches active services where is_active = true.
  /// Throws on failure.
  static Future<List<BersihuyService>> getServices() async {
    final data = await SupabaseService.client
        .from('services')
        .select('id, name, slug, category, description, base_price, duration_minutes, rating, image_asset_path')
        .eq('is_active', true)
        .order('name', ascending: true);

    return (data as List).map((row) => BersihuyService.fromMap(row)).toList();
  }

  /// Fetches a short active-services list for customer home.
  static Future<List<BersihuyService>> getPopularServices({int limit = 4}) async {
    final data = await SupabaseService.client
        .from('services')
        .select('id, name, slug, category, description, base_price, duration_minutes, rating, image_asset_path')
        .eq('is_active', true)
        .limit(limit);

    return (data as List).map((row) => BersihuyService.fromMap(row)).toList();
  }

  /// Fetches one active service by UUID.
  static Future<BersihuyService?> getServiceById(String serviceId) async {
    if (serviceId.trim().isEmpty) return null;

    final data = await SupabaseService.client
        .from('services')
        .select('id, name, slug, category, description, base_price, duration_minutes, rating, image_asset_path')
        .eq('id', serviceId.trim())
        .eq('is_active', true)
        .maybeSingle();

    if (data == null) return null;
    return BersihuyService.fromMap(data);
  }

  /// Fetches active products where is_active = true.
  /// Throws on failure.
  static Future<List<BersihuyProduct>> getProducts() async {
    final data = await SupabaseService.client
        .from('products')
        .select('id, name, slug, description, price, image_asset_path, is_addon')
        .eq('is_active', true)
        .order('name', ascending: true);

    return (data as List).map((row) => BersihuyProduct.fromMap(row)).toList();
  }
}
