import '../repositories/order_repository.dart';

/// High-level service that orchestrates the customer checkout flow.
/// Wraps [OrderRepository] to provide a clean, UI-friendly interface.
class CustomerOrderService {
  const CustomerOrderService();

  final _repository = const OrderRepository();

  /// Creates a new customer order after dummy payment confirmation.
  ///
  /// [serviceId]   - UUID of the selected service from Supabase (nullable for fallback).
  /// [serviceName]  - Display name of the service.
  /// [servicePrice] - Base price of the service (int, in Rupiah).
  /// [adminFee]     - Admin fee amount (int, in Rupiah).
  /// [selectedScent] - Optional chosen scent name.
  /// [selectedAddOns] - List of add-on product items.
  /// [scheduleDate] - Selected booking date (nullable — defaults to today).
  /// [scheduleTime] - Selected booking time string e.g. "14:00" (nullable).
  /// [serviceAddress] - Customer's service address.
  /// [customerNote]  - Optional customer note.
  ///
  /// Returns the created [BersihuyOrder] on success.
  /// Throws on any failure (auth, network, database).
  Future<BersihuyOrder> createCustomerOrder({
    String? serviceId,
    required String serviceName,
    required int servicePrice,
    required int adminFee,
    String? selectedScent,
    List<AddOnItem>? selectedAddOns,
    DateTime? scheduleDate,
    String? scheduleTime,
    required String serviceAddress,
    String? customerNote,
  }) async {
    // Validate inputs
    if (servicePrice <= 0) {
      throw ArgumentError('servicePrice must be greater than 0');
    }
    if (serviceAddress.trim().isEmpty) {
      throw ArgumentError('serviceAddress cannot be empty');
    }

    final addOns = selectedAddOns ?? [];
    final addOnsTotal = addOns.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    final params = CreateOrderParams(
      serviceId: serviceId,
      serviceName: serviceName,
      selectedScent: selectedScent,
      scheduleDate: scheduleDate ?? DateTime.now(),
      scheduleTime: scheduleTime ?? '14:00',
      serviceAddress: serviceAddress.trim(),
      customerNote: customerNote?.trim(),
      servicePrice: servicePrice,
      adminFee: adminFee,
      addOnsTotal: addOnsTotal,
      discountAmount: 0,
      addOnItems: addOns,
    );

    return _repository.createOrder(params);
  }

  /// Creates one pending order/payment row before opening Midtrans Snap.
  Future<BersihuyOrder> createPendingCustomerOrder({
    String? serviceId,
    required String serviceName,
    required int servicePrice,
    required int adminFee,
    String? selectedScent,
    List<AddOnItem>? selectedAddOns,
    DateTime? scheduleDate,
    String? scheduleTime,
    required String serviceAddress,
    String? customerNote,
  }) async {
    if (servicePrice <= 0) {
      throw ArgumentError('servicePrice must be greater than 0');
    }
    if (serviceAddress.trim().isEmpty) {
      throw ArgumentError('serviceAddress cannot be empty');
    }

    final addOns = selectedAddOns ?? [];
    final addOnsTotal = addOns.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return _repository.createOrder(
      CreateOrderParams(
        serviceId: serviceId,
        serviceName: serviceName,
        selectedScent: selectedScent,
        scheduleDate: scheduleDate ?? DateTime.now(),
        scheduleTime: scheduleTime ?? '14:00',
        serviceAddress: serviceAddress.trim(),
        customerNote: customerNote?.trim(),
        servicePrice: servicePrice,
        adminFee: adminFee,
        addOnsTotal: addOnsTotal,
        discountAmount: 0,
        addOnItems: addOns,
        initialOrderStatus: 'pending_payment',
        initialPaymentStatus: 'pending',
        paymentProvider: 'midtrans',
        paymentMethod: 'Snap Sandbox',
      ),
    );
  }

  Future<BersihuyOrder> completeDemoPayment(String orderId) {
    return _repository.completeDemoPayment(orderId);
  }

  /// Fetches all orders for the currently authenticated customer.
  Future<List<BersihuyOrder>> getMyOrders() {
    return _repository.getCustomerOrders();
  }

  /// Fetches the payment record for a given order ID.
  Future<BersihuyPayment?> getPaymentForOrder(String orderId) {
    return _repository.getPaymentForOrder(orderId);
  }

  /// Loads an existing order and reuses or creates its single payment row.
  Future<OrderDetail> preparePendingPaymentOrder(String orderId) {
    return _repository.preparePendingPaymentOrder(orderId);
  }
}
