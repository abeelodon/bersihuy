import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

/// Raw data class for a customer order.
/// Maps 1-to-1 with the `orders` table.
class BersihuyOrder {
  final String? id;
  final String orderNumber;
  final String customerId;
  final String status;
  final DateTime? scheduleDate;
  final String? scheduleTime;
  final String serviceAddress;
  final String? customerNote;
  final int subtotalAmount;
  final int adminFee;
  final int discountAmount;
  final int totalAmount;
  final String? selectedScent;
  final DateTime? createdAt;
  final String? assignedStaffName;
  final String? taskStatus;

  /// Lazy-loaded order items — populated by getActiveOrders/getOrderWithDetails.
  List<BersihuyOrderItem> orderItems;

  BersihuyOrder({
    this.id,
    required this.orderNumber,
    required this.customerId,
    required this.status,
    this.scheduleDate,
    this.scheduleTime,
    required this.serviceAddress,
    this.customerNote,
    required this.subtotalAmount,
    required this.adminFee,
    required this.discountAmount,
    required this.totalAmount,
    this.selectedScent,
    this.createdAt,
    this.assignedStaffName,
    this.taskStatus,
    List<BersihuyOrderItem>? orderItems,
  }) : orderItems = orderItems ?? [];

  factory BersihuyOrder.fromMap(Map<String, Object?> map) {
    return BersihuyOrder(
      id: map['id']?.toString(),
      orderNumber: map['order_number'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      status: map['status'] as String? ?? '',
      scheduleDate: _parseDate(map['schedule_date']),
      scheduleTime: map['schedule_time'] as String?,
      serviceAddress: map['service_address'] as String? ?? '',
      customerNote: map['customer_note'] as String?,
      subtotalAmount: (map['subtotal_amount'] as num?)?.toInt() ?? 0,
      adminFee: (map['admin_fee'] as num?)?.toInt() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toInt() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toInt() ?? 0,
      selectedScent: map['selected_scent'] as String?,
      createdAt: _parseDateTime(map['created_at']),
      assignedStaffName: map['assigned_staff_name'] as String?,
      taskStatus: map['task_status'] as String?,
      orderItems: _parseOrderItems(map['order_items']),
    );
  }

  BersihuyOrder copyWith({
    String? assignedStaffName,
    String? taskStatus,
    List<BersihuyOrderItem>? orderItems,
  }) {
    return BersihuyOrder(
      id: id,
      orderNumber: orderNumber,
      customerId: customerId,
      status: status,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      serviceAddress: serviceAddress,
      customerNote: customerNote,
      subtotalAmount: subtotalAmount,
      adminFee: adminFee,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      selectedScent: selectedScent,
      createdAt: createdAt,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      taskStatus: taskStatus ?? this.taskStatus,
      orderItems: orderItems ?? this.orderItems,
    );
  }

  static List<BersihuyOrderItem> _parseOrderItems(Object? value) {
    if (value is! List) return [];
    return value
        .map((row) => BersihuyOrderItem.fromMap(row as Map<String, Object?>))
        .toList();
  }

  /// The primary service name from order_items.
  String get serviceName {
    final serviceItem = orderItems
        .where((i) => i.itemType == 'service')
        .firstOrNull;
    return serviceItem?.itemName ?? 'Layanan Bersihuy';
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String get formattedScheduleDate {
    if (scheduleDate == null) return '-';
    final d = scheduleDate!;
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get formattedTotal => _formatRupiah(totalAmount);

  static String _formatRupiah(int value) {
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

/// Raw data class for an order item.
class BersihuyOrderItem {
  final String? id;
  final String orderId;
  final String itemType;
  final String? serviceId;
  final String? productId;
  final String itemName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;

  const BersihuyOrderItem({
    this.id,
    required this.orderId,
    required this.itemType,
    this.serviceId,
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory BersihuyOrderItem.fromMap(Map<String, Object?> map) {
    return BersihuyOrderItem(
      id: map['id']?.toString(),
      orderId: map['order_id'] as String? ?? '',
      itemType: map['item_type'] as String? ?? '',
      serviceId: map['service_id']?.toString(),
      productId: map['product_id']?.toString(),
      itemName: map['item_name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unit_price'] as num?)?.toInt() ?? 0,
      totalPrice: (map['total_price'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Raw data class for a payment record.
class BersihuyPayment {
  final String? id;
  final String orderId;
  final String status;
  final String provider;
  final String? paymentMethod;
  final int amount;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const BersihuyPayment({
    this.id,
    required this.orderId,
    required this.status,
    required this.provider,
    this.paymentMethod,
    required this.amount,
    this.paidAt,
    this.createdAt,
  });

  factory BersihuyPayment.fromMap(Map<String, Object?> map) {
    return BersihuyPayment(
      id: map['id']?.toString(),
      orderId: map['order_id'] as String? ?? '',
      status: map['status'] as String? ?? '',
      provider: map['provider'] as String? ?? '',
      paymentMethod: map['payment_method'] as String?,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      paidAt: _parseDateTime(map['paid_at']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String get formattedAmount => _formatRupiah(amount);

  static String _formatRupiah(int value) {
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

/// Aggregated order detail including items, payment, and assigned staff.
class OrderDetail {
  final BersihuyOrder order;
  final List<BersihuyOrderItem> orderItems;
  final BersihuyPayment? payment;
  final String? assignedStaffName;
  final String? assignedStaffId;
  final String? taskStatus;
  final String? taskId;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;

  const OrderDetail({
    required this.order,
    required this.orderItems,
    this.payment,
    this.assignedStaffName,
    this.assignedStaffId,
    this.taskStatus,
    this.taskId,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
  });

  /// The primary service name from order_items, or a fallback.
  String get serviceName {
    final serviceItem = orderItems
        .where((i) => i.itemType == 'service')
        .firstOrNull;
    return serviceItem?.itemName ?? 'Layanan Bersihuy';
  }

  bool get hasTask => taskId != null && taskId!.isNotEmpty;
  bool get hasAssignedStaffId =>
      assignedStaffId != null && assignedStaffId!.isNotEmpty;
  bool get hasAssignedStaff =>
      hasAssignedStaffId &&
      assignedStaffName != null &&
      assignedStaffName!.isNotEmpty;
}

class _OrderTaskInfo {
  final String id;
  final String? staffId;
  final String? status;
  final String? staffName;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;

  const _OrderTaskInfo({
    required this.id,
    this.staffId,
    this.status,
    this.staffName,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
  });
}

class CustomerReview {
  final String id;
  final String orderId;
  final String customerId;
  final String? staffId;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final String? staffName;
  final String? serviceName;
  final String? orderNumber;

  const CustomerReview({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.staffId,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.staffName,
    this.serviceName,
    this.orderNumber,
  });

  factory CustomerReview.fromMap(
    Map<String, Object?> map, {
    String? staffName,
    String? serviceName,
    String? orderNumber,
  }) {
    return CustomerReview(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      staffId: map['staff_id']?.toString(),
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String? ?? '',
      createdAt: _parseDateTime(map['created_at']),
      staffName: staffName,
      serviceName: serviceName,
      orderNumber: orderNumber,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class DuplicateReviewException implements Exception {
  final CustomerReview review;

  const DuplicateReviewException(this.review);

  @override
  String toString() => 'DuplicateReviewException: review already exists';
}

class CustomerComplaint {
  final String id;
  final String orderId;
  final String customerId;
  final String category;
  final String description;
  final String status;
  final String? evidenceUrl;
  final String? resolutionNote;
  final DateTime? createdAt;
  final String? orderNumber;
  final String serviceName;

  const CustomerComplaint({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.category,
    required this.description,
    required this.status,
    this.evidenceUrl,
    this.resolutionNote,
    this.createdAt,
    this.orderNumber,
    required this.serviceName,
  });

  factory CustomerComplaint.fromMap(
    Map<String, Object?> map, {
    String? orderNumber,
    required String serviceName,
  }) {
    return CustomerComplaint(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      category: map['category'] as String? ?? '-',
      description: map['description'] as String? ?? '-',
      status: map['status'] as String? ?? 'open',
      evidenceUrl: map['evidence_url'] as String?,
      resolutionNote: map['resolution_note'] as String?,
      createdAt: _parseDateTime(map['created_at']),
      orderNumber: orderNumber,
      serviceName: serviceName,
    );
  }

  String get statusLabel {
    return switch (status) {
      'open' => 'Diproses',
      'in_review' => 'Ditinjau',
      'resolved' => 'Selesai',
      'rejected' => 'Ditolak',
      _ => status,
    };
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Lightweight add-on product entry.
/// productId should be a valid UUID string from Supabase.
/// Items with a null/invalid productId are skipped during item insert.
class AddOnItem {
  final String? productId;
  final String name;
  final int price;
  final int quantity;

  const AddOnItem({
    this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  int get totalPrice => price * quantity;

  bool get isValid => _isValidUuid(productId);
}

/// True if the given string looks like a valid UUID.
bool _isValidUuid(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value.trim());
}

/// Parameters for creating a new order.
/// All validation happens inside [OrderRepository.createOrder].
class CreateOrderParams {
  /// UUID of the service from Supabase, or null if using a local fallback service.
  final String? serviceId;

  final String serviceName;
  final String? selectedScent;
  final DateTime? scheduleDate;
  final String? scheduleTime;
  final String serviceAddress;
  final String? customerNote;
  final int servicePrice;
  final int adminFee;
  final int addOnsTotal;
  final int discountAmount;
  final String initialOrderStatus;
  final String initialPaymentStatus;
  final String paymentProvider;
  final String paymentMethod;

  /// Add-on product items. Items with invalid/empty productId are skipped.
  final List<AddOnItem> addOnItems;

  const CreateOrderParams({
    this.serviceId,
    required this.serviceName,
    this.selectedScent,
    this.scheduleDate,
    this.scheduleTime,
    required this.serviceAddress,
    this.customerNote,
    required this.servicePrice,
    required this.adminFee,
    this.addOnsTotal = 0,
    this.discountAmount = 0,
    this.addOnItems = const [],
    this.initialOrderStatus = 'scheduled',
    this.initialPaymentStatus = 'paid',
    this.paymentProvider = 'dummy',
    this.paymentMethod = 'QRIS Dummy',
  });

  int get subtotal => servicePrice + addOnsTotal;
  int get total => subtotal + adminFee - discountAmount;

  /// Only add-on items with a valid UUID productId.
  List<AddOnItem> get validAddOnItems =>
      addOnItems.where((item) => item.isValid).toList();
}

/// Repository for order-related database operations.
class OrderRepository {
  const OrderRepository();

  SupabaseClient get _client => SupabaseService.client;

  /// Creates a new order, its order items, and its initial payment row.
  ///
  /// All inserts are wrapped in a try/catch/rollback block. If any step fails
  /// after the `orders` row is inserted, the partial order is deleted first
  /// before re-throwing the exception.
  ///
  /// New order numbers use the short daily sequence format BSH-YYMMDD-NNN.
  ///
  /// Returns the created [BersihuyOrder].
  Future<BersihuyOrder> createOrder(CreateOrderParams params) async {
    // ── 0. Pre-flight debug log ─────────────────────────────────────────────
    debugPrint('========== CREATE ORDER START ==========');
    debugPrint('serviceId: ${params.serviceId}');
    debugPrint('serviceName: ${params.serviceName}');
    debugPrint('servicePrice: ${params.servicePrice}');
    debugPrint('adminFee: ${params.adminFee}');
    debugPrint('addOnsTotal: ${params.addOnsTotal}');
    debugPrint('subtotalAmount: ${params.subtotal}');
    debugPrint('discountAmount: ${params.discountAmount}');
    debugPrint('total: ${params.total}');
    debugPrint(
      'valid addOns: ${params.validAddOnItems.map((p) => '${p.productId}:${p.name}').join(', ')}',
    );
    debugPrint(
      'total calculation: service=${params.servicePrice}, '
      'addOns=${params.addOnsTotal}, subtotal=${params.subtotal}, '
      'admin=${params.adminFee}, discount=${params.discountAmount}, '
      'total=${params.total}',
    );

    // ── 1. Validate authenticated user ─────────────────────────────────────
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }
    final customerId = user.id;
    debugPrint('customerId (validated): $customerId');

    // ── 2. Validate required fields ─────────────────────────────────────────
    if (params.servicePrice <= 0) {
      throw ArgumentError('Harga layanan harus lebih dari Rp0.');
    }
    if (params.total <= 0) {
      throw ArgumentError('Total tagihan harus lebih dari Rp0.');
    }
    if (params.serviceAddress.trim().isEmpty) {
      throw ArgumentError('Alamat layanan tidak boleh kosong.');
    }

    // ── 3. Validate serviceId format if provided ───────────────────────────
    if (params.serviceId != null && !_isValidUuid(params.serviceId)) {
      throw ArgumentError(
        'Service ID "${params.serviceId}" tidak valid. '
        'Pastikan layanan dipilih dari daftar layanan Supabase.',
      );
    }

    final orderNumber = await _generateOrderNumber();
    debugPrint('generated orderNumber: $orderNumber');

    // ── Track created order for rollback on failure ─────────────────────────
    String? createdOrderId;

    try {
      // ── A. Insert orders ───────────────────────────────────────────────────
      final orderPayload = <String, Object?>{
        'order_number': orderNumber,
        'customer_id': customerId,
        'status': params.initialOrderStatus,
        'schedule_date': params.scheduleDate
            ?.toIso8601String()
            .split('T')
            .first,
        'schedule_time': params.scheduleTime ?? '14:00',
        'service_address': params.serviceAddress,
        'customer_note': params.customerNote,
        'subtotal_amount': params.subtotal,
        'admin_fee': params.adminFee,
        'discount_amount': params.discountAmount,
        'total_amount': params.total,
        'selected_scent': params.selectedScent,
      };
      debugPrint('INSERT orders payload: $orderPayload');

      final orderRow = await _client
          .from('orders')
          .insert(orderPayload)
          .select('*')
          .single();

      final order = BersihuyOrder.fromMap(orderRow);
      createdOrderId = order.id;
      if (createdOrderId == null || createdOrderId.trim().isEmpty) {
        throw StateError('Order berhasil dibuat tanpa ID.');
      }
      debugPrint('INSERT orders success — orderId: $createdOrderId');

      // ── B. Insert main service order_items ─────────────────────────────────
      final serviceItemPayload = <String, Object?>{
        'order_id': createdOrderId,
        'item_type': 'service',
        'service_id': _isValidUuid(params.serviceId)
            ? params.serviceId!.trim()
            : null,
        'product_id': null,
        'item_name': params.serviceName,
        'quantity': 1,
        'unit_price': params.servicePrice,
        'total_price': params.servicePrice,
      };
      debugPrint('INSERT order_items (service) payload: $serviceItemPayload');
      await _client.from('order_items').insert(serviceItemPayload);
      debugPrint('INSERT order_items (service) success');

      // ── C. Insert add-on / product order_items ─────────────────────────────
      for (final item in params.validAddOnItems) {
        final addOnPayload = <String, Object?>{
          'order_id': createdOrderId,
          'item_type': 'addon',
          'service_id': null,
          'product_id': item.productId!.trim(),
          'item_name': item.name,
          'quantity': item.quantity,
          'unit_price': item.price,
          'total_price': item.totalPrice,
        };
        debugPrint('INSERT order_items (addon) payload: $addOnPayload');
        await _client.from('order_items').insert(addOnPayload);
        debugPrint('INSERT order_items (addon) "${item.name}" success');
      }

      // ── D. Insert payments ─────────────────────────────────────────────────
      final paymentPayload = <String, Object?>{
        'order_id': createdOrderId,
        'status': params.initialPaymentStatus,
        'provider': params.paymentProvider,
        'payment_method': params.paymentMethod,
        'amount': params.total,
        if (params.initialPaymentStatus == 'paid')
          'paid_at': DateTime.now().toIso8601String(),
      };
      debugPrint('INSERT payments payload: $paymentPayload');
      await _client.from('payments').insert(paymentPayload);
      debugPrint('INSERT payments success');

      debugPrint(
        '========== CREATE ORDER SUCCESS: ${order.orderNumber} ==========',
      );
      return order;

      // ── E. Rollback on any failure ──────────────────────────────────────────
    } catch (e, st) {
      debugPrint('CREATE ORDER FAILED: $e');
      debugPrint('CREATE ORDER STACKTRACE: $st');

      if (createdOrderId != null) {
        await _rollbackCreatedOrder(createdOrderId);
      } else {
        debugPrint('No order row to rollback (insert failed before orders)');
      }

      debugPrint('========== CREATE ORDER END (failed) ==========');
      rethrow;
    }
  }

  /// Fetches all orders for the currently authenticated customer.
  /// Ordered by created_at descending.
  ///
  /// Uses simple `select('*')` — no nested joins. Task/staff enrichment is
  /// handled separately by screens that need it (OrderTrackingScreen,
  /// RatingReviewScreen) so RLS on those tables cannot break the orders list.
  Future<List<BersihuyOrder>> getCustomerOrders() async {
    final userId = SupabaseService.currentUser?.id;
    debugPrint('ORDERS FETCH START userId=$userId');
    if (userId == null) return [];

    final data = await _client
        .from('orders')
        .select('*')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);

    debugPrint('ORDERS FETCH RAW DATA: ${(data as List).length} rows');
    debugPrint('ORDERS FETCH SUCCESS count=${(data as List).length}');

    return (data as List).map((row) => BersihuyOrder.fromMap(row)).toList();
  }

  /// Fetches the payment record for a given order ID.
  Future<BersihuyPayment?> getPaymentForOrder(String orderId) async {
    if (orderId.trim().isEmpty) return null;

    final data = await _client
        .from('payments')
        .select('*')
        .eq('order_id', orderId.trim())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return BersihuyPayment.fromMap(data);
  }

  /// Loads an existing customer order for payment and guarantees one pending
  /// payment row exists. It never creates a second order.
  Future<OrderDetail> preparePendingPaymentOrder(String orderId) async {
    final normalizedOrderId = orderId.trim();
    final userId = SupabaseService.currentUser?.id;

    if (normalizedOrderId.isEmpty) {
      throw StateError('Order ID belum tersedia.');
    }
    if (userId == null) {
      throw StateError('Sesi pengguna tidak tersedia.');
    }

    debugPrint(
      'PREPARE PENDING PAYMENT orderId=$normalizedOrderId userId=$userId',
    );

    final orderData = await _client
        .from('orders')
        .select('*')
        .eq('id', normalizedOrderId)
        .maybeSingle();
    if (orderData == null) {
      throw StateError('Data pesanan gagal dimuat: order tidak ditemukan.');
    }

    final order = BersihuyOrder.fromMap(orderData);
    if (order.customerId != userId) {
      throw StateError('Akses pesanan tidak valid.');
    }
    if (order.status == 'completed' || order.status == 'cancelled') {
      throw StateError(
        'Pesanan berstatus ${order.status} tidak dapat dibayar.',
      );
    }

    final itemsData = await _client
        .from('order_items')
        .select('*')
        .eq('order_id', normalizedOrderId);
    final orderItems = (itemsData as List)
        .map((row) => BersihuyOrderItem.fromMap(row))
        .toList();

    var payment = await getPaymentForOrder(normalizedOrderId);
    if (payment?.status == 'paid' ||
        {'paid', 'scheduled', 'in_progress'}.contains(order.status)) {
      return OrderDetail(
        order: order.copyWith(orderItems: orderItems),
        orderItems: orderItems,
        payment: payment,
      );
    }

    if (payment == null) {
      final paymentData = await _client
          .from('payments')
          .insert({
            'order_id': normalizedOrderId,
            'provider': 'midtrans',
            'payment_method': 'Snap Sandbox',
            'amount': order.totalAmount,
            'status': 'pending',
          })
          .select('*')
          .single();
      payment = BersihuyPayment.fromMap(paymentData);
      debugPrint('PREPARE PENDING PAYMENT created paymentId=${payment.id}');
    } else {
      debugPrint(
        'PREPARE PENDING PAYMENT reuse paymentId=${payment.id} '
        'status=${payment.status}',
      );
    }

    return OrderDetail(
      order: order.copyWith(orderItems: orderItems),
      orderItems: orderItems,
      payment: payment,
    );
  }

  /// Resolves a display order number to its internal UUID.
  Future<String?> getOrderIdByNumber(String orderNumber) async {
    final normalizedOrderNumber = orderNumber.trim();
    if (normalizedOrderNumber.isEmpty) return null;

    final data = await _client
        .from('orders')
        .select('id')
        .eq('order_number', normalizedOrderNumber)
        .maybeSingle();

    final orderId = data?['id']?.toString().trim();
    return orderId == null || orderId.isEmpty ? null : orderId;
  }

  /// Completes the existing pending payment using the development fallback.
  Future<BersihuyOrder> completeDemoPayment(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      throw ArgumentError('Order ID tidak boleh kosong.');
    }

    final orderData = await _client
        .from('orders')
        .select('*')
        .eq('id', normalizedOrderId)
        .maybeSingle();
    if (orderData == null) {
      throw StateError('Data pesanan tidak ditemukan.');
    }

    final order = BersihuyOrder.fromMap(orderData);
    final payment = await getPaymentForOrder(normalizedOrderId);
    final userId = SupabaseService.currentUser?.id;
    if (userId == null || order.customerId != userId) {
      throw StateError('Akses pesanan tidak valid.');
    }
    if (order.status == 'completed' || order.status == 'cancelled') {
      throw StateError(
        'Pesanan berstatus ${order.status} tidak dapat dibayar.',
      );
    }
    if (payment?.status == 'paid' ||
        {'paid', 'scheduled', 'in_progress'}.contains(order.status)) {
      return order;
    }

    final paymentPayload = <String, Object?>{
      'order_id': normalizedOrderId,
      'status': 'paid',
      'provider': 'dummy',
      'payment_method': 'QRIS Dummy',
      'amount': order.totalAmount,
      'paid_at': DateTime.now().toIso8601String(),
    };

    if (payment?.id != null && payment!.id!.trim().isNotEmpty) {
      await _client
          .from('payments')
          .update(paymentPayload)
          .eq('id', payment.id!);
    } else {
      await _client.from('payments').insert(paymentPayload);
    }

    final updatedOrderData = await _client
        .from('orders')
        .update({'status': 'scheduled'})
        .eq('id', normalizedOrderId)
        .select('*')
        .single();

    return BersihuyOrder.fromMap(updatedOrderData);
  }

  /// Fetches active orders for the current user.
  /// Active = created, pending_payment, paid, scheduled, in_progress.
  ///
  /// Uses simple `select('*')` + Dart-side status filter to avoid RLS issues
  /// that can arise when using .or() filter or joining order_items.
  /// Order items (for service name) are loaded lazily by the home screen.
  ///
  /// Throws on failure — callers must handle with proper error states.
  Future<List<BersihuyOrder>> getActiveOrders() async {
    final userId = SupabaseService.currentUser?.id;
    debugPrint('HOME ACTIVE ORDERS FETCH START userId=$userId');
    if (userId == null) return [];

    final activeStatuses = {
      'created',
      'pending_payment',
      'paid',
      'scheduled',
      'in_progress',
    };

    // Fetch all customer orders with simple select — filter status in Dart
    final data = await _client
        .from('orders')
        .select('*')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);

    final rawOrders = data as List;
    debugPrint(
      'HOME ACTIVE ORDERS FETCH RAW: ${rawOrders.length} total orders',
    );

    final activeOrders = rawOrders
        .where((row) => activeStatuses.contains(row['status'] as String?))
        .toList();

    debugPrint('HOME ACTIVE ORDERS FETCH SUCCESS count=${activeOrders.length}');

    return activeOrders.map((row) => BersihuyOrder.fromMap(row)).toList();
  }

  /// Safely loads order_items for a single order.
  /// Returns a list of BersihuyOrderItem, or empty list on failure.
  /// Does NOT throw — logs error and returns [].
  Future<List<BersihuyOrderItem>> loadOrderItemsForHome(String orderId) async {
    if (orderId.trim().isEmpty) return [];
    try {
      final data = await _client
          .from('order_items')
          .select('*')
          .eq('order_id', orderId.trim());
      return (data as List)
          .map((row) => BersihuyOrderItem.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('HOME ACTIVE ORDER ITEMS ERROR orderId=$orderId — $e');
      return [];
    }
  }

  Future<_OrderTaskInfo?> _getTaskInfo(String orderId) async {
    if (orderId.trim().isEmpty) return null;

    final taskData = await _client
        .from('tasks')
        .select('id, status, staff_id, before_photo_url, after_photo_url')
        .eq('order_id', orderId.trim())
        .maybeSingle();

    if (taskData == null) return null;

    final staffId = taskData['staff_id']?.toString();
    String? staffName;

    if (staffId != null && staffId.trim().isNotEmpty) {
      staffName = await _getStaffNameById(staffId.trim());
    }

    return _OrderTaskInfo(
      id: taskData['id']?.toString() ?? orderId.trim(),
      staffId: staffId?.trim(),
      status: taskData['status'] as String?,
      staffName: staffName,
      beforePhotoUrl: taskData['before_photo_url'] as String?,
      afterPhotoUrl: taskData['after_photo_url'] as String?,
    );
  }

  Future<String?> _getStaffNameById(String staffId) async {
    if (staffId.trim().isEmpty) return null;

    try {
      final profileData = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', staffId.trim())
          .maybeSingle();
      final staffName = profileData?['full_name'] as String?;
      return staffName?.trim().isEmpty == true ? null : staffName?.trim();
    } catch (e) {
      debugPrint('getStaffNameById: failed to fetch profile $staffId - $e');
      return null;
    }
  }

  /// Fetches a single order by ID, including its order_items, payment,
  /// assigned task, and staff name (if any).
  Future<OrderDetail?> getOrderWithDetails(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) return null;

    // Keep these as separate queries so a missing relationship in PostgREST's
    // schema cache cannot make the order itself appear unavailable.
    final orderData = await _client
        .from('orders')
        .select('*')
        .eq('id', normalizedOrderId)
        .maybeSingle();

    if (orderData == null) return null;

    final order = BersihuyOrder.fromMap(orderData);
    List<BersihuyOrderItem> orderItems = [];
    try {
      final itemsData = await _client
          .from('order_items')
          .select('*')
          .eq('order_id', normalizedOrderId);
      orderItems = (itemsData as List)
          .map((row) => BersihuyOrderItem.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('getOrderWithDetails: failed to fetch order items - $e');
    }

    // Fetch payment (if any)
    BersihuyPayment? payment;
    try {
      payment = await getPaymentForOrder(normalizedOrderId);
    } catch (e) {
      debugPrint('getOrderWithDetails: failed to fetch payment — $e');
    }

    // Fetch assigned task + staff profile (if any)
    _OrderTaskInfo? taskInfo;
    try {
      taskInfo = await _getTaskInfo(normalizedOrderId);
      debugPrint(
        'CUSTOMER ORDER DETAIL task proof: '
        'orderId=$normalizedOrderId, taskId=${taskInfo?.id}, '
        'before_photo_url=${taskInfo?.beforePhotoUrl}, '
        'after_photo_url=${taskInfo?.afterPhotoUrl}',
      );
    } catch (e) {
      debugPrint('getOrderWithDetails: failed to fetch task/staff — $e');
    }

    final orderWithTask = order.copyWith(
      assignedStaffName: taskInfo?.staffName,
      taskStatus: taskInfo?.status,
      orderItems: orderItems,
    );

    return OrderDetail(
      order: orderWithTask,
      orderItems: orderItems,
      payment: payment,
      assignedStaffName: taskInfo?.staffName,
      assignedStaffId: taskInfo?.staffId,
      taskStatus: taskInfo?.status,
      taskId: taskInfo?.id,
      beforePhotoUrl: taskInfo?.beforePhotoUrl,
      afterPhotoUrl: taskInfo?.afterPhotoUrl,
    );
  }

  Future<bool> hasReviewForOrder(String orderId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null || orderId.trim().isEmpty) return false;

    final data = await _client
        .from('reviews')
        .select('id')
        .eq('order_id', orderId.trim())
        .eq('customer_id', userId)
        .maybeSingle();

    return data != null;
  }

  Future<CustomerReview?> getReviewForOrder(String orderId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null || orderId.trim().isEmpty) return null;

    final data = await _client
        .from('reviews')
        .select('*')
        .eq('order_id', orderId.trim())
        .eq('customer_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return _hydrateReview(Map<String, Object?>.from(data));
  }

  Future<CustomerReview> _hydrateReview(Map<String, Object?> reviewData) async {
    String? resolvedStaffId = reviewData['staff_id']?.toString();
    final orderId = reviewData['order_id']?.toString();
    String? staffName;
    String? serviceName;
    String? orderNumber;

    debugPrint('HYDRATE REVIEW: review.staff_id=$resolvedStaffId');

    // Fallback: if review.staff_id is null, try tasks.staff_id by order_id
    if ((resolvedStaffId == null || resolvedStaffId.trim().isEmpty) &&
        orderId != null &&
        orderId.trim().isNotEmpty) {
      debugPrint(
        'HYDRATE REVIEW: review.staff_id is null — checking tasks table',
      );
      try {
        final taskData = await _client
            .from('tasks')
            .select('staff_id')
            .eq('order_id', orderId.trim())
            .maybeSingle();
        resolvedStaffId = taskData?['staff_id']?.toString();
        debugPrint(
          'HYDRATE REVIEW: fetched task, task.staff_id=$resolvedStaffId',
        );
      } catch (e) {
        debugPrint('HYDRATE REVIEW: failed to fetch task — $e');
      }
    }

    if (resolvedStaffId != null && resolvedStaffId.trim().isNotEmpty) {
      try {
        staffName = await _getStaffNameById(resolvedStaffId.trim());
        debugPrint('HYDRATE REVIEW: fetched staff profile name=$staffName');
      } catch (e) {
        debugPrint('HYDRATE REVIEW: failed to fetch staff profile — $e');
        // staffName stays null — do not throw
      }
    } else {
      debugPrint('HYDRATE REVIEW: no staff found — staffName stays null');
    }

    if (orderId != null && orderId.trim().isNotEmpty) {
      try {
        final orderDisplay = await _getOrderDisplayData(orderId.trim());
        serviceName = orderDisplay.serviceName;
        orderNumber = orderDisplay.orderNumber;
      } catch (e) {
        debugPrint('HYDRATE REVIEW: failed to fetch order display data — $e');
        // fall through with default values
      }
    }

    debugPrint(
      'HYDRATE REVIEW: final resolvedStaffId=$resolvedStaffId, '
      'staffName=$staffName, serviceName=$serviceName',
    );

    return CustomerReview.fromMap(
      reviewData,
      staffName: staffName,
      serviceName: serviceName,
      orderNumber: orderNumber,
    );
  }

  Future<({String? orderNumber, String serviceName})> _getOrderDisplayData(
    String orderId,
  ) async {
    String? orderNumber;
    String serviceName = 'Layanan Bersihuy';

    try {
      final orderData = await _client
          .from('orders')
          .select('order_number')
          .eq('id', orderId)
          .maybeSingle();
      orderNumber = orderData?['order_number'] as String?;
    } catch (e) {
      debugPrint('getOrderDisplayData: failed to fetch order $orderId - $e');
    }

    try {
      final itemsData = await _client
          .from('order_items')
          .select('item_type, item_name')
          .eq('order_id', orderId);
      final items = (itemsData as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList();
      final serviceItem = items
          .where((item) => item['item_type'] == 'service')
          .firstOrNull;
      final itemName = serviceItem?['item_name'] as String?;
      if (itemName != null && itemName.trim().isNotEmpty) {
        serviceName = itemName.trim();
      }
    } catch (e) {
      debugPrint('getOrderDisplayData: failed to fetch items $orderId - $e');
    }

    return (orderNumber: orderNumber, serviceName: serviceName);
  }

  Future<void> submitComplaint({
    required String orderId,
    required String category,
    required String description,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }
    if (orderId.trim().isEmpty) {
      throw ArgumentError('Order ID tidak boleh kosong.');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('Detail keluhan tidak boleh kosong.');
    }

    await _client.from('complaints').insert({
      'order_id': orderId.trim(),
      'customer_id': userId,
      'category': category.trim(),
      'description': description.trim(),
      'evidence_url': null,
      'status': 'open',
    });
  }

  Future<CustomerReview> submitReview({
    required String orderId,
    required int rating,
    required String comment,
    String? staffId,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }
    if (orderId.trim().isEmpty) {
      throw ArgumentError('Order ID tidak boleh kosong.');
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating harus bernilai 1 sampai 5.');
    }

    debugPrint('SUBMIT REVIEW: orderId=$orderId');
    debugPrint('SUBMIT REVIEW: initial staffId=$staffId');

    // Resolve staffId: use provided staffId, or fetch from tasks table
    String? resolvedStaffId = staffId?.trim();
    if ((resolvedStaffId == null || resolvedStaffId.isEmpty) &&
        orderId.trim().isNotEmpty) {
      debugPrint(
        'SUBMIT REVIEW: staffId not provided — fetching task by order_id',
      );
      try {
        final taskData = await _client
            .from('tasks')
            .select('staff_id')
            .eq('order_id', orderId.trim())
            .maybeSingle();
        resolvedStaffId = taskData?['staff_id']?.toString();
        debugPrint(
          'SUBMIT REVIEW: task fetched, task.staff_id=$resolvedStaffId',
        );
      } catch (e) {
        debugPrint('SUBMIT REVIEW: failed to fetch task — $e');
      }
    }

    if (resolvedStaffId == null || resolvedStaffId.isEmpty) {
      debugPrint(
        'WARNING: SUBMIT REVIEW — no task.staff_id found for orderId=$orderId',
      );
    } else {
      debugPrint(
        'SUBMIT REVIEW: using staffId=$resolvedStaffId in review insert',
      );
    }

    final existingReview = await getReviewForOrder(orderId.trim());
    if (existingReview != null) {
      throw DuplicateReviewException(existingReview);
    }

    final inserted = await _client
        .from('reviews')
        .insert({
          'order_id': orderId.trim(),
          'customer_id': userId,
          'staff_id': resolvedStaffId != null && resolvedStaffId.isNotEmpty
              ? resolvedStaffId
              : null,
          'rating': rating,
          'comment': comment.trim(),
        })
        .select('*')
        .single();

    return _hydrateReview(Map<String, Object?>.from(inserted));
  }

  Future<List<CustomerComplaint>> getCustomerComplaints() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('complaints')
        .select('*')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);

    final rows = (data as List)
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();

    return Future.wait(rows.map(_hydrateComplaint));
  }

  Future<CustomerComplaint?> getComplaintById(String complaintId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null || complaintId.trim().isEmpty) return null;

    final data = await _client
        .from('complaints')
        .select('*')
        .eq('id', complaintId.trim())
        .eq('customer_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return _hydrateComplaint(Map<String, Object?>.from(data));
  }

  Future<CustomerComplaint> _hydrateComplaint(
    Map<String, Object?> complaintData,
  ) async {
    final orderId = complaintData['order_id']?.toString();
    String? orderNumber;
    String serviceName = 'Layanan Bersihuy';

    if (orderId != null && orderId.trim().isNotEmpty) {
      final orderDisplay = await _getOrderDisplayData(orderId.trim());
      orderNumber = orderDisplay.orderNumber;
      serviceName = orderDisplay.serviceName;
    }

    return CustomerComplaint.fromMap(
      complaintData,
      orderNumber: orderNumber,
      serviceName: serviceName,
    );
  }

  Future<void> _rollbackCreatedOrder(String orderId) async {
    debugPrint('Attempting rollback for order $orderId');

    Future<void> deleteRelatedRows(String table) async {
      try {
        await _client.from(table).delete().eq('order_id', orderId);
        debugPrint('Rollback cleanup success: $table for order $orderId');
      } catch (cleanupError) {
        debugPrint(
          'Rollback cleanup failed: $table for order $orderId - $cleanupError',
        );
      }
    }

    await deleteRelatedRows('payments');
    await deleteRelatedRows('order_items');

    try {
      await _client.from('orders').delete().eq('id', orderId);
      debugPrint('Rollback cleanup success: orders for order $orderId');
    } catch (cleanupError) {
      debugPrint(
        'Rollback cleanup failed: orders for order $orderId - $cleanupError',
      );
    }
  }

  /// Generates BSH-YYMMDD-NNN using the number of orders created today.
  Future<String> _generateOrderNumber() async {
    final now = DateTime.now();
    final datePart =
        '${(now.year % 100).toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final prefix = 'BSH-$datePart';
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    try {
      final data = await _client
          .from('orders')
          .select('id')
          .gte('created_at', startOfDay.toUtc().toIso8601String())
          .lt('created_at', startOfTomorrow.toUtc().toIso8601String());
      final nextNumber = (data as List).length + 1;
      return '$prefix-${nextNumber.toString().padLeft(3, '0')}';
    } catch (error, stackTrace) {
      debugPrint('ORDER NUMBER SEQUENCE ERROR: $error');
      debugPrint('ORDER NUMBER SEQUENCE STACKTRACE: $stackTrace');
      final timePart =
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}';
      return '$prefix-$timePart';
    }
  }
}
