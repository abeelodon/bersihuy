import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

class CustomerProfileData {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String mainAddress;
  final String city;
  final String addressNote;

  const CustomerProfileData({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.mainAddress,
    required this.city,
    required this.addressNote,
  });

  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    final emailName = email.split('@').first.trim();
    return emailName.isNotEmpty ? emailName : 'Pengguna Bersihuy';
  }

  String get firstName => displayName.split(RegExp(r'\s+')).first;

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'PB';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  bool get isComplete =>
      fullName.isNotEmpty && phone.isNotEmpty && mainAddress.isNotEmpty;

  factory CustomerProfileData.fromMap(
    Map<String, dynamic> map, {
    required String fallbackEmail,
  }) {
    String read(String key) => map[key]?.toString().trim() ?? '';

    return CustomerProfileData(
      id: read('id'),
      email: read('email').isNotEmpty ? read('email') : fallbackEmail,
      fullName: read('full_name'),
      phone: read('phone'),
      mainAddress: read('main_address'),
      city: read('city'),
      addressNote: read('address_note'),
    );
  }
}

class CustomerProfileOverview {
  final CustomerProfileData profile;
  final int totalOrders;
  final int completedOrders;

  const CustomerProfileOverview({
    required this.profile,
    required this.totalOrders,
    required this.completedOrders,
  });
}

class CustomerProfileService {
  const CustomerProfileService();

  Future<CustomerProfileData> getCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw StateError('Sesi pengguna tidak ditemukan.');
    }

    Map<String, dynamic> data;
    try {
      data = await SupabaseService.client
          .from('profiles')
          .select(
            'id, email, full_name, phone, main_address, city, address_note',
          )
          .eq('id', user.id)
          .single();
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      final addressColumnsMissing =
          message.contains('main_address') ||
          message.contains('address_note') ||
          message.contains('city');
      if (!addressColumnsMissing) rethrow;

      debugPrint(
        'CUSTOMER PROFILE: address columns unavailable, using basic profile',
      );
      data = await SupabaseService.client
          .from('profiles')
          .select('id, email, full_name, phone')
          .eq('id', user.id)
          .single();
    }

    return CustomerProfileData.fromMap(
      data,
      fallbackEmail: user.email?.trim() ?? '',
    );
  }

  Future<CustomerProfileOverview> getOverview() async {
    final profile = await getCurrentProfile();
    var totalOrders = 0;
    var completedOrders = 0;

    try {
      final orders = await SupabaseService.client
          .from('orders')
          .select('status')
          .eq('customer_id', profile.id);
      totalOrders = orders.length;
      completedOrders = orders
          .where((order) => order['status']?.toString() == 'completed')
          .length;
    } catch (error) {
      debugPrint('CUSTOMER PROFILE ORDER STATS ERROR: $error');
    }

    return CustomerProfileOverview(
      profile: profile,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
    );
  }

  Future<void> updateCurrentProfile({
    required String fullName,
    required String phone,
    required String mainAddress,
    required String city,
    required String addressNote,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw StateError('Sesi pengguna tidak ditemukan.');
    }

    await SupabaseService.client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'phone': _nullable(phone),
          'main_address': _nullable(mainAddress),
          'city': _nullable(city),
          'address_note': _nullable(addressNote),
        })
        .eq('id', user.id)
        .select('id')
        .single();
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
