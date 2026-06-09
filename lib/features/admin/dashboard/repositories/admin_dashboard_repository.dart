import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

class AdminDashboardRepository {
  const AdminDashboardRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AdminDashboardData> loadDashboard() async {
    final adminFuture = _capture(
      'ADMIN PROFILE FETCH',
      getCurrentAdminProfile,
      const AdminProfile(name: 'Admin', email: '-', role: 'admin'),
    );
    final staffFuture = _capture(
      'ADMIN STAFF LIST FETCH',
      getStaffProfiles,
      const <AdminStaffProfile>[],
    );
    final servicesFuture = _capture(
      'ADMIN SERVICES FETCH',
      getServices,
      const <AdminServiceItem>[],
    );
    final productsFuture = _capture(
      'ADMIN PRODUCTS FETCH',
      getProducts,
      const <AdminProductItem>[],
    );
    final tasksFuture = _capture(
      'ADMIN TASKS FETCH',
      _getAllTasks,
      const <Map<String, Object?>>[],
    );
    final reviewsFuture = _capture(
      'ADMIN REVIEWS FETCH',
      _getAllReviews,
      const <Map<String, Object?>>[],
    );
    final itemsFuture = _capture(
      'ADMIN ORDER ITEMS FETCH',
      _getOrderItemInsights,
      const AdminItemInsights(services: [], products: []),
    );

    final orders = await getOrders();
    final adminResult = await adminFuture;
    final staffResult = await staffFuture;
    final servicesResult = await servicesFuture;
    final productsResult = await productsFuture;
    final tasksResult = await tasksFuture;
    final reviewsResult = await reviewsFuture;
    final itemsResult = await itemsFuture;

    final complaintsResult = await _capture(
      'ADMIN COMPLAINTS FETCH',
      () => getComplaints(
        orders: orders,
        staff: staffResult.value,
        admin: adminResult.value,
      ),
      const <AdminComplaintRow>[],
    );

    final staff = _withStaffMetrics(
      staff: staffResult.value,
      tasks: tasksResult.value,
      reviews: reviewsResult.value,
      complaints: complaintsResult.value,
      orders: orders,
    );
    final warnings = <String>[
      ...adminResult.warnings,
      ...staffResult.warnings,
      ...servicesResult.warnings,
      ...productsResult.warnings,
      ...tasksResult.warnings,
      ...reviewsResult.warnings,
      ...itemsResult.warnings,
      ...complaintsResult.warnings,
    ];

    return AdminDashboardData(
      admin: adminResult.value,
      orders: orders,
      staff: staff,
      services: servicesResult.value,
      products: productsResult.value,
      complaints: complaintsResult.value,
      topServices: itemsResult.value.services,
      topProducts: itemsResult.value.products,
      summary: AdminDashboardSummary.fromData(
        orders: orders,
        complaints: complaintsResult.value,
        reviews: reviewsResult.value,
      ),
      trends: AdminTrendPoint.fromOrders(orders),
      warnings: warnings,
    );
  }

  Future<AdminProfile> getCurrentAdminProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return const AdminProfile(name: 'Admin', email: '-', role: 'admin');
    }

    final data = await _client
        .from('profiles')
        .select('full_name, email, role')
        .eq('id', user.id)
        .maybeSingle();

    return AdminProfile(
      name: _profileDisplayName(data, fallback: 'Admin'),
      email: data?['email']?.toString().trim().isNotEmpty == true
          ? data!['email'].toString().trim()
          : user.email ?? '-',
      role: data?['role']?.toString().trim().isNotEmpty == true
          ? data!['role'].toString().trim()
          : 'admin',
    );
  }

  Future<List<AdminOrderRow>> getOrders() async {
    debugPrint('ADMIN ORDERS FETCH START');
    try {
      final data = await _client
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);

      final rows = (data as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList();

      final orders = <AdminOrderRow>[];
      for (final row in rows) {
        final order = AdminOrderRow.fromOrderMap(row);
        orders.add(await _enrichOrder(order));
      }

      debugPrint('ADMIN ORDERS FETCH SUCCESS count=${orders.length}');
      return orders;
    } on PostgrestException catch (error) {
      _debugPostgrestException('ADMIN ORDERS FETCH ERROR', error);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('ADMIN ORDERS FETCH ERROR $error');
      debugPrint('ADMIN ORDERS FETCH STACKTRACE $stackTrace');
      rethrow;
    }
  }

  Future<List<AdminStaffProfile>> getStaffProfiles() async {
    debugPrint('ADMIN STAFF LIST FETCH START');
    try {
      final data = await _client
          .from('profiles')
          .select('*')
          .eq('role', 'staff')
          .order('full_name', ascending: true);
      final rows = (data as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList();

      final staff = rows
          .map(AdminStaffProfile.fromMap)
          .where((profile) => profile.id.trim().isNotEmpty)
          .toList();
      debugPrint('ADMIN STAFF LIST FETCH SUCCESS count=${staff.length}');
      return staff;
    } on PostgrestException catch (error) {
      _debugPostgrestException('ADMIN STAFF LIST FETCH ERROR', error);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('ADMIN STAFF LIST FETCH ERROR $error');
      debugPrint('ADMIN STAFF LIST FETCH STACKTRACE $stackTrace');
      rethrow;
    }
  }

  Future<List<AdminServiceItem>> getServices() async {
    final data = await _client
        .from('services')
        .select('*')
        .order('name', ascending: true);
    return (data as List)
        .map(
          (row) =>
              AdminServiceItem.fromMap(Map<String, Object?>.from(row as Map)),
        )
        .toList();
  }

  Future<List<AdminProductItem>> getProducts() async {
    final data = await _client
        .from('products')
        .select('*')
        .order('name', ascending: true);
    return (data as List)
        .map(
          (row) =>
              AdminProductItem.fromMap(Map<String, Object?>.from(row as Map)),
        )
        .toList();
  }

  Future<List<AdminComplaintRow>> getComplaints({
    required List<AdminOrderRow> orders,
    required List<AdminStaffProfile> staff,
    required AdminProfile admin,
  }) async {
    final data = await _client
        .from('complaints')
        .select('*')
        .order('created_at', ascending: false);
    final orderById = {for (final order in orders) order.id: order};
    final staffById = {for (final person in staff) person.id: person};

    return (data as List).map((raw) {
      final map = Map<String, Object?>.from(raw as Map);
      final orderId = map['order_id']?.toString() ?? '';
      final order = orderById[orderId];
      final handledBy = map['handled_by']?.toString();
      final handler = handledBy == null
          ? null
          : staffById[handledBy]?.fullName ??
                (handledBy == SupabaseService.currentUser?.id
                    ? admin.name
                    : null);

      return AdminComplaintRow.fromMap(
        map,
        orderNumber: order?.orderNumber,
        customerName: order?.customerName,
        serviceName: order?.serviceName,
        assignedStaffId: order?.assignedStaffId,
        handledByName: handler,
      );
    }).toList();
  }

  Future<void> updateComplaint({
    required AdminComplaintRow complaint,
    required String status,
    required String resolutionNote,
  }) async {
    final adminId = SupabaseService.currentUser?.id;
    if (adminId == null || adminId.trim().isEmpty) {
      throw Exception('Admin belum login.');
    }

    try {
      await _client
          .from('complaints')
          .update({
            'status': status,
            'resolution_note': resolutionNote.trim().isEmpty
                ? null
                : resolutionNote.trim(),
            'handled_by': adminId,
          })
          .eq('id', complaint.id);
    } on PostgrestException catch (error) {
      _debugPostgrestException('ADMIN COMPLAINT UPDATE ERROR', error);
      rethrow;
    }
  }

  Future<void> assignStaffToOrder({
    required AdminOrderRow order,
    required AdminStaffProfile staff,
  }) async {
    final adminId = SupabaseService.currentUser?.id.trim();
    final orderId = order.id.trim();
    final staffId = staff.id.trim();

    debugPrint('ADMIN ASSIGN START orderId=$orderId staffId=$staffId');

    if (adminId == null || adminId.isEmpty) {
      throw Exception('Admin belum login.');
    }
    if (orderId.isEmpty) {
      throw ArgumentError('Order ID tidak boleh kosong.');
    }
    if (staffId.isEmpty) {
      throw ArgumentError('Staff ID tidak boleh kosong.');
    }

    try {
      final existingTask = await _getExistingTask(orderId);
      final taskResult = existingTask == null
          ? await _insertAssignedTask(orderId: orderId, staffId: staffId)
          : await _updateAssignedTask(task: existingTask, staffId: staffId);

      if (order.status == 'paid' || order.status == 'scheduled') {
        await _client
            .from('orders')
            .update({'status': 'scheduled'})
            .eq('id', orderId);
        debugPrint('ADMIN ASSIGN orders.status -> scheduled');
      }

      await _insertTaskHistory(
        taskId: taskResult.taskId,
        oldStatus: taskResult.oldStatus,
        adminId: adminId,
      );

      debugPrint('ADMIN ASSIGN SUCCESS orderId=$orderId staffId=$staffId');
    } on PostgrestException catch (error) {
      _debugPostgrestException('ADMIN ASSIGN POSTGREST ERROR', error);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('ADMIN ASSIGN ERROR $error');
      debugPrint('ADMIN ASSIGN STACKTRACE $stackTrace');
      rethrow;
    }
  }

  Future<AdminOrderRow> _enrichOrder(AdminOrderRow order) async {
    final results = await Future.wait<dynamic>([
      _fetchCustomerName(order.customerId),
      _fetchOrderItems(order.id),
      _fetchPaymentStatus(order.id),
      _fetchTaskInfo(order.id),
    ]);

    final orderItems = results[1] as _AdminOrderItems;
    final taskInfo = results[3] as _AdminTaskInfo?;
    return order.copyWith(
      customerName: results[0] as String,
      serviceName: orderItems.serviceName,
      itemNames: orderItems.itemNames,
      paymentStatus: results[2] as String?,
      taskId: taskInfo?.id,
      taskStatus: taskInfo?.status,
      assignedStaffId: taskInfo?.staffId,
      assignedStaffName: taskInfo?.staffName,
      beforePhotoUrl: taskInfo?.beforePhotoUrl,
      afterPhotoUrl: taskInfo?.afterPhotoUrl,
    );
  }

  Future<String> _fetchCustomerName(String customerId) async {
    if (customerId.trim().isEmpty) return 'Customer';

    try {
      final data = await _client
          .from('profiles')
          .select('full_name, email')
          .eq('id', customerId.trim())
          .maybeSingle();
      return _profileDisplayName(data, fallback: 'Customer');
    } catch (error) {
      debugPrint(
        'ADMIN ORDER CUSTOMER FETCH ERROR customerId=$customerId $error',
      );
      return 'Customer';
    }
  }

  Future<_AdminOrderItems> _fetchOrderItems(String orderId) async {
    if (orderId.trim().isEmpty) {
      return const _AdminOrderItems(
        serviceName: 'Layanan Bersihuy',
        itemNames: [],
      );
    }

    try {
      final data = await _client
          .from('order_items')
          .select('item_type, item_name')
          .eq('order_id', orderId.trim());
      final rows = (data as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList();
      if (rows.isEmpty) {
        return const _AdminOrderItems(
          serviceName: 'Layanan Bersihuy',
          itemNames: [],
        );
      }

      final serviceItem = rows
          .where((item) => item['item_type'] == 'service')
          .firstOrNull;
      final bestItem = serviceItem ?? rows.first;
      final serviceName = bestItem['item_name']?.toString().trim();
      final itemNames = rows
          .map((item) => item['item_name']?.toString().trim())
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toList();

      return _AdminOrderItems(
        serviceName: serviceName == null || serviceName.isEmpty
            ? 'Layanan Bersihuy'
            : serviceName,
        itemNames: itemNames,
      );
    } catch (error) {
      debugPrint('ADMIN ORDER ITEMS FETCH ERROR orderId=$orderId $error');
      return const _AdminOrderItems(
        serviceName: 'Layanan Bersihuy',
        itemNames: [],
      );
    }
  }

  Future<String?> _fetchPaymentStatus(String orderId) async {
    if (orderId.trim().isEmpty) return null;

    try {
      final data = await _client
          .from('payments')
          .select('status')
          .eq('order_id', orderId.trim())
          .order('created_at', ascending: false)
          .limit(1);
      final rows = data as List;
      if (rows.isEmpty) return null;
      final row = Map<String, Object?>.from(rows.first as Map);
      final status = row['status']?.toString().trim();
      return status == null || status.isEmpty ? null : status;
    } catch (error) {
      debugPrint('ADMIN PAYMENT FETCH ERROR orderId=$orderId $error');
      return null;
    }
  }

  Future<_AdminTaskInfo?> _fetchTaskInfo(String orderId) async {
    if (orderId.trim().isEmpty) return null;

    try {
      final data = await _client
          .from('tasks')
          .select('id, status, staff_id, before_photo_url, after_photo_url')
          .eq('order_id', orderId.trim())
          .limit(1);
      final rows = data as List;
      if (rows.isEmpty) return null;

      final row = Map<String, Object?>.from(rows.first as Map);
      final staffId = row['staff_id']?.toString().trim();
      final staffName = staffId == null || staffId.isEmpty
          ? null
          : await _fetchStaffName(staffId);

      return _AdminTaskInfo(
        id: row['id']?.toString() ?? orderId.trim(),
        status: row['status']?.toString(),
        staffId: staffId,
        staffName: staffName,
        beforePhotoUrl: row['before_photo_url']?.toString(),
        afterPhotoUrl: row['after_photo_url']?.toString(),
      );
    } catch (error) {
      debugPrint('ADMIN TASK FETCH ERROR orderId=$orderId $error');
      return null;
    }
  }

  Future<String?> _fetchStaffName(String staffId) async {
    String? staffName;

    try {
      final profileData = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', staffId.trim())
          .maybeSingle();
      staffName = profileData?['full_name'] as String?;
    } catch (error) {
      debugPrint('ADMIN STAFF PROFILE FETCH ERROR staffId=$staffId $error');
    }

    if (staffName == null || staffName.trim().isEmpty) {
      try {
        final staffData = await _client
            .from('staffs')
            .select('full_name')
            .eq('id', staffId.trim())
            .maybeSingle();
        staffName = staffData?['full_name'] as String?;
      } catch (error) {
        debugPrint('ADMIN STAFF FETCH ERROR staffId=$staffId $error');
      }
    }

    final cleanName = staffName?.trim();
    return cleanName == null || cleanName.isEmpty ? null : cleanName;
  }

  Future<List<Map<String, Object?>>> _getAllTasks() async {
    final data = await _client.from('tasks').select('*');
    return (data as List)
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, Object?>>> _getAllReviews() async {
    final data = await _client.from('reviews').select('*');
    return (data as List)
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();
  }

  Future<AdminItemInsights> _getOrderItemInsights() async {
    final data = await _client
        .from('order_items')
        .select('item_type, item_name, quantity, total_price');
    final rows = (data as List)
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();

    final serviceMap = <String, _ItemAccumulator>{};
    final productMap = <String, _ItemAccumulator>{};
    for (final row in rows) {
      final name = row['item_name']?.toString().trim();
      if (name == null || name.isEmpty) continue;
      final quantity = _readInt(row['quantity']).clamp(1, 999999);
      final revenue = _readInt(row['total_price']);
      final target = row['item_type']?.toString() == 'service'
          ? serviceMap
          : productMap;
      final key = name.toLowerCase();
      target.putIfAbsent(key, () => _ItemAccumulator(name));
      target[key]!.count += quantity;
      target[key]!.revenue += revenue;
    }

    List<AdminTopItem> ranked(Map<String, _ItemAccumulator> source) {
      final result =
          source.values
              .map(
                (item) => AdminTopItem(
                  name: item.name,
                  count: item.count,
                  revenue: item.revenue,
                ),
              )
              .toList()
            ..sort((a, b) => b.count.compareTo(a.count));
      return result.take(6).toList();
    }

    return AdminItemInsights(
      services: ranked(serviceMap),
      products: ranked(productMap),
    );
  }

  List<AdminStaffProfile> _withStaffMetrics({
    required List<AdminStaffProfile> staff,
    required List<Map<String, Object?>> tasks,
    required List<Map<String, Object?>> reviews,
    required List<AdminComplaintRow> complaints,
    required List<AdminOrderRow> orders,
  }) {
    final orderById = {for (final order in orders) order.id: order};
    return staff.map((person) {
      final staffTasks = tasks
          .where((task) => task['staff_id']?.toString() == person.id)
          .toList();
      final staffReviews = reviews
          .where((review) => review['staff_id']?.toString() == person.id)
          .toList();
      final ratings = staffReviews
          .map((review) => _readDouble(review['rating']))
          .where((rating) => rating > 0)
          .toList();
      final complaintCount = complaints.where((complaint) {
        if (complaint.assignedStaffId == person.id) return true;
        final order = orderById[complaint.orderId];
        return order?.assignedStaffId == person.id;
      }).length;

      return person.copyWithMetrics(
        assignedTasks: staffTasks.length,
        completedTasks: staffTasks
            .where((task) => task['status']?.toString() == 'completed')
            .length,
        inProgressTasks: staffTasks
            .where((task) => task['status']?.toString() == 'in_progress')
            .length,
        averageRating: ratings.isEmpty
            ? 0
            : ratings.reduce((a, b) => a + b) / ratings.length,
        complaintCount: complaintCount,
      );
    }).toList();
  }

  Future<_ExistingTask?> _getExistingTask(String orderId) async {
    final data = await _client
        .from('tasks')
        .select('id, status')
        .eq('order_id', orderId)
        .maybeSingle();
    if (data == null) return null;

    return _ExistingTask(
      id: data['id']?.toString() ?? '',
      status: data['status']?.toString(),
    );
  }

  Future<_AssignTaskResult> _insertAssignedTask({
    required String orderId,
    required String staffId,
  }) async {
    final inserted = await _writeTaskWithNoteFallback(
      payloadWithoutNote: {
        'order_id': orderId,
        'staff_id': staffId,
        'status': 'assigned',
        'assigned_at': DateTime.now().toIso8601String(),
      },
      mode: _TaskWriteMode.insert,
    );

    return _AssignTaskResult(
      taskId: inserted['id']?.toString() ?? '',
      oldStatus: null,
    );
  }

  Future<_AssignTaskResult> _updateAssignedTask({
    required _ExistingTask task,
    required String staffId,
  }) async {
    if (task.id.trim().isEmpty) {
      throw Exception('Task ID kosong saat update assignment.');
    }

    final status = _assignedTaskStatus(task.status);
    await _writeTaskWithNoteFallback(
      payloadWithoutNote: {
        'staff_id': staffId,
        'status': status,
        'assigned_at': DateTime.now().toIso8601String(),
      },
      mode: _TaskWriteMode.update,
      taskId: task.id,
    );

    return _AssignTaskResult(taskId: task.id, oldStatus: task.status);
  }

  Future<Map<String, Object?>> _writeTaskWithNoteFallback({
    required Map<String, Object?> payloadWithoutNote,
    required _TaskWriteMode mode,
    String? taskId,
  }) async {
    const noteText = 'Tugas dijadwalkan oleh admin.';
    final payloadWithStaffNote = {
      ...payloadWithoutNote,
      'staff_note': noteText,
    };

    try {
      return await _writeTask(
        payload: payloadWithStaffNote,
        mode: mode,
        taskId: taskId,
      );
    } on PostgrestException catch (error) {
      _debugPostgrestException('ADMIN TASK WRITE ERROR', error);
      if (!_isMissingStaffNoteColumn(error)) rethrow;

      debugPrint('ADMIN TASK WRITE RETRY using note column');
      final payloadWithNote = {...payloadWithoutNote, 'note': noteText};
      return _writeTask(payload: payloadWithNote, mode: mode, taskId: taskId);
    }
  }

  Future<Map<String, Object?>> _writeTask({
    required Map<String, Object?> payload,
    required _TaskWriteMode mode,
    String? taskId,
  }) async {
    switch (mode) {
      case _TaskWriteMode.insert:
        final inserted = await _client
            .from('tasks')
            .insert(payload)
            .select('id')
            .single();
        return Map<String, Object?>.from(inserted);
      case _TaskWriteMode.update:
        if (taskId == null || taskId.trim().isEmpty) {
          throw ArgumentError('Task ID tidak boleh kosong.');
        }
        final updated = await _client
            .from('tasks')
            .update(payload)
            .eq('id', taskId.trim())
            .select('id')
            .single();
        return Map<String, Object?>.from(updated);
    }
  }

  Future<void> _insertTaskHistory({
    required String taskId,
    required String? oldStatus,
    required String adminId,
  }) async {
    if (taskId.trim().isEmpty) {
      throw Exception('Task ID kosong saat menyimpan riwayat status.');
    }

    await _client.from('task_status_history').insert({
      'task_id': taskId.trim(),
      'old_status': oldStatus,
      'new_status': 'assigned',
      'changed_by': adminId,
      'note': 'Admin menugaskan petugas.',
    });
    debugPrint('ADMIN ASSIGN history inserted taskId=$taskId');
  }

  Future<_Captured<T>> _capture<T>(
    String label,
    Future<T> Function() loader,
    T fallback,
  ) async {
    try {
      return _Captured(value: await loader());
    } on PostgrestException catch (error) {
      _debugPostgrestException('$label ERROR', error);
      return _Captured(value: fallback, warnings: ['$label: ${error.message}']);
    } catch (error, stackTrace) {
      debugPrint('$label ERROR $error');
      debugPrint('$label STACKTRACE $stackTrace');
      return _Captured(value: fallback, warnings: ['$label: $error']);
    }
  }
}

class AdminDashboardData {
  final AdminProfile admin;
  final AdminDashboardSummary summary;
  final List<AdminOrderRow> orders;
  final List<AdminStaffProfile> staff;
  final List<AdminServiceItem> services;
  final List<AdminProductItem> products;
  final List<AdminComplaintRow> complaints;
  final List<AdminTopItem> topServices;
  final List<AdminTopItem> topProducts;
  final List<AdminTrendPoint> trends;
  final List<String> warnings;

  const AdminDashboardData({
    required this.admin,
    required this.summary,
    required this.orders,
    required this.staff,
    required this.services,
    required this.products,
    required this.complaints,
    required this.topServices,
    required this.topProducts,
    required this.trends,
    required this.warnings,
  });

  String get adminName => admin.name;
}

class AdminProfile {
  final String name;
  final String email;
  final String role;

  const AdminProfile({
    required this.name,
    required this.email,
    required this.role,
  });
}

class AdminDashboardSummary {
  final int totalOrders;
  final int todayOrders;
  final int waitingAssignment;
  final int assigned;
  final int inProgress;
  final int completed;
  final int openComplaints;
  final int totalRevenue;
  final int monthlyRevenue;
  final double averageOrderValue;
  final double averageRating;

  const AdminDashboardSummary({
    required this.totalOrders,
    required this.todayOrders,
    required this.waitingAssignment,
    required this.assigned,
    required this.inProgress,
    required this.completed,
    required this.openComplaints,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.averageOrderValue,
    required this.averageRating,
  });

  factory AdminDashboardSummary.fromData({
    required List<AdminOrderRow> orders,
    required List<AdminComplaintRow> complaints,
    required List<Map<String, Object?>> reviews,
  }) {
    final now = DateTime.now();
    final paidOrders = orders.where((order) => order.isPaid).toList();
    final totalRevenue = paidOrders.fold<int>(
      0,
      (total, order) => total + order.totalAmount,
    );
    final monthlyRevenue = paidOrders
        .where(
          (order) =>
              order.createdAt?.year == now.year &&
              order.createdAt?.month == now.month,
        )
        .fold<int>(0, (total, order) => total + order.totalAmount);
    final ratings = reviews
        .map((review) => _readDouble(review['rating']))
        .where((rating) => rating > 0)
        .toList();

    return AdminDashboardSummary(
      totalOrders: orders.length,
      todayOrders: orders
          .where((order) => _isSameDay(order.createdAt, now))
          .length,
      waitingAssignment: orders.where((order) => order.isUnassigned).length,
      assigned: orders.where((order) => order.isAssigned).length,
      inProgress: orders
          .where((order) => order.effectiveStatus == 'in_progress')
          .length,
      completed: orders
          .where((order) => order.effectiveStatus == 'completed')
          .length,
      openComplaints: complaints
          .where((complaint) => complaint.status == 'open')
          .length,
      totalRevenue: totalRevenue,
      monthlyRevenue: monthlyRevenue,
      averageOrderValue: paidOrders.isEmpty
          ? 0
          : totalRevenue / paidOrders.length,
      averageRating: ratings.isEmpty
          ? 0
          : ratings.reduce((a, b) => a + b) / ratings.length,
    );
  }
}

class AdminTrendPoint {
  final DateTime date;
  final int orders;
  final int revenue;

  const AdminTrendPoint({
    required this.date,
    required this.orders,
    required this.revenue,
  });

  static List<AdminTrendPoint> fromOrders(List<AdminOrderRow> orders) {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index));
      final matching = orders
          .where((order) => _isSameDay(order.createdAt, date))
          .toList();
      return AdminTrendPoint(
        date: date,
        orders: matching.length,
        revenue: matching
            .where((order) => order.isPaid)
            .fold<int>(0, (total, order) => total + order.totalAmount),
      );
    });
  }

  String get dayLabel {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }
}

class AdminOrderRow {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String serviceName;
  final List<String> itemNames;
  final DateTime? scheduleDate;
  final String? scheduleTime;
  final String address;
  final String? customerNote;
  final int totalAmount;
  final String status;
  final String? paymentStatus;
  final String? taskId;
  final String? taskStatus;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final DateTime? createdAt;

  const AdminOrderRow({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.serviceName,
    required this.itemNames,
    this.scheduleDate,
    this.scheduleTime,
    required this.address,
    this.customerNote,
    required this.totalAmount,
    required this.status,
    this.paymentStatus,
    this.taskId,
    this.taskStatus,
    this.assignedStaffId,
    this.assignedStaffName,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.createdAt,
  });

  factory AdminOrderRow.fromOrderMap(Map<String, Object?> map) {
    final id = map['id']?.toString() ?? '';
    final orderNumber = map['order_number']?.toString().trim();

    return AdminOrderRow(
      id: id,
      orderNumber: orderNumber == null || orderNumber.isEmpty
          ? _fallbackOrderNumber(id)
          : orderNumber,
      customerId: map['customer_id']?.toString() ?? '',
      customerName: 'Customer',
      serviceName: 'Layanan Bersihuy',
      itemNames: const [],
      scheduleDate: _parseDateTime(map['schedule_date']),
      scheduleTime: map['schedule_time']?.toString(),
      address: map['service_address']?.toString() ?? '-',
      customerNote: map['customer_note']?.toString(),
      totalAmount: _readInt(map['total_amount']),
      status: map['status']?.toString() ?? 'scheduled',
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  AdminOrderRow copyWith({
    String? customerName,
    String? serviceName,
    List<String>? itemNames,
    String? paymentStatus,
    String? taskId,
    String? taskStatus,
    String? assignedStaffId,
    String? assignedStaffName,
    String? beforePhotoUrl,
    String? afterPhotoUrl,
  }) {
    return AdminOrderRow(
      id: id,
      orderNumber: orderNumber,
      customerId: customerId,
      customerName: customerName ?? this.customerName,
      serviceName: serviceName ?? this.serviceName,
      itemNames: itemNames ?? this.itemNames,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      address: address,
      customerNote: customerNote,
      totalAmount: totalAmount,
      status: status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      taskId: taskId ?? this.taskId,
      taskStatus: taskStatus ?? this.taskStatus,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      beforePhotoUrl: beforePhotoUrl ?? this.beforePhotoUrl,
      afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
      createdAt: createdAt,
    );
  }

  bool get hasTask => taskId != null && taskId!.trim().isNotEmpty;

  bool get hasAssignedStaff =>
      assignedStaffId != null && assignedStaffId!.trim().isNotEmpty;

  bool get canAssign =>
      status == 'paid' ||
      status == 'scheduled' ||
      status == 'in_progress' ||
      taskStatus == 'assigned' ||
      taskStatus == 'in_progress';

  bool get isUnassigned =>
      (status == 'paid' || status == 'scheduled') && !hasAssignedStaff;

  bool get isAssigned =>
      hasAssignedStaff &&
      effectiveStatus != 'in_progress' &&
      effectiveStatus != 'completed';

  bool get isPaid =>
      paymentStatus == 'paid' ||
      status == 'paid' ||
      status == 'scheduled' ||
      status == 'in_progress' ||
      status == 'completed';

  String get effectiveStatus {
    if (taskStatus == 'completed' || status == 'completed') return 'completed';
    if (taskStatus == 'in_progress' || status == 'in_progress') {
      return 'in_progress';
    }
    if (taskStatus == 'assigned' || hasAssignedStaff) return 'assigned';
    return status;
  }

  String get scheduleLabel {
    final dateLabel = _formatDate(scheduleDate);
    final time = scheduleTime?.trim();
    if (dateLabel == '-' && (time == null || time.isEmpty)) {
      return 'Belum dijadwalkan';
    }
    if (time == null || time.isEmpty) return dateLabel;
    if (dateLabel == '-') return time;
    return '$dateLabel, $time';
  }

  String get totalLabel => formatAdminRupiah(totalAmount);

  String get statusLabel => adminOrderStatusLabel(effectiveStatus);

  String get paymentStatusLabel {
    final value = paymentStatus?.trim();
    if (value != null && value.isNotEmpty) {
      return adminPaymentStatusLabel(value);
    }
    if (status == 'pending_payment') {
      return adminPaymentStatusLabel('pending');
    }
    return 'Tidak ada';
  }

  String get assignmentLabel {
    final staffName = assignedStaffName?.trim();
    if (hasAssignedStaff && staffName != null && staffName.isNotEmpty) {
      return staffName;
    }
    return 'Menunggu penugasan';
  }

  String get detailItemsLabel {
    if (itemNames.isEmpty) return serviceName;
    return itemNames.join(', ');
  }
}

class AdminStaffProfile {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? staffArea;
  final String? staffShift;
  final String? baseLocation;
  final String? workSchedule;
  final String? statusText;
  final bool isActive;
  final int assignedTasks;
  final int completedTasks;
  final int inProgressTasks;
  final double averageRating;
  final int complaintCount;

  const AdminStaffProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.staffArea,
    this.staffShift,
    this.baseLocation,
    this.workSchedule,
    this.statusText,
    this.isActive = true,
    this.assignedTasks = 0,
    this.completedTasks = 0,
    this.inProgressTasks = 0,
    this.averageRating = 0,
    this.complaintCount = 0,
  });

  factory AdminStaffProfile.fromMap(Map<String, Object?> map) {
    final id = map['id']?.toString() ?? '';
    final fallbackName = map['email']?.toString().trim();
    final fullName = map['full_name']?.toString().trim();

    return AdminStaffProfile(
      id: id,
      fullName: fullName == null || fullName.isEmpty
          ? fallbackName ?? 'Petugas Bersihuy'
          : fullName,
      email: fallbackName,
      phone: _readOptionalString(map, ['phone', 'phone_number', 'whatsapp']),
      staffArea: _readOptionalString(map, [
        'staff_area',
        'service_area',
        'area',
      ]),
      staffShift: _readOptionalString(map, [
        'work_schedule',
        'staff_shift',
        'shift',
        'work_shift',
      ]),
      baseLocation: _readOptionalString(map, ['base_location']),
      workSchedule: _readOptionalString(map, [
        'work_schedule',
        'staff_shift',
        'shift',
        'work_shift',
      ]),
      statusText: _readOptionalString(map, [
        'status',
        'availability_status',
        'staff_status',
      ]),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  AdminStaffProfile copyWithMetrics({
    required int assignedTasks,
    required int completedTasks,
    required int inProgressTasks,
    required double averageRating,
    required int complaintCount,
  }) {
    return AdminStaffProfile(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      staffArea: staffArea,
      staffShift: staffShift,
      baseLocation: baseLocation,
      workSchedule: workSchedule,
      statusText: statusText,
      isActive: isActive,
      assignedTasks: assignedTasks,
      completedTasks: completedTasks,
      inProgressTasks: inProgressTasks,
      averageRating: averageRating,
      complaintCount: complaintCount,
    );
  }

  String get areaLabel => staffArea?.trim().isEmpty == false
      ? staffArea!.trim()
      : 'Area belum diatur';

  String get shiftLabel => staffShift?.trim().isEmpty == false
      ? staffShift!.trim()
      : 'Shift belum diatur';

  String get baseLocationLabel => baseLocation?.trim().isEmpty == false
      ? baseLocation!.trim()
      : 'Base belum diatur';

  String get workScheduleLabel =>
      workSchedule?.trim().isEmpty == false ? workSchedule!.trim() : shiftLabel;

  String get availabilityLabel {
    if (!isActive) return 'Tidak aktif';
    return statusText?.trim().isEmpty == false
        ? statusText!.trim()
        : 'Siap bertugas';
  }

  String get initials {
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) return 'B';
    return words.map((word) => word[0].toUpperCase()).join();
  }
}

class AdminServiceItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final int price;
  final int durationMinutes;
  final double rating;
  final bool isActive;
  final String? imageAssetPath;

  const AdminServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.rating,
    required this.isActive,
    this.imageAssetPath,
  });

  factory AdminServiceItem.fromMap(Map<String, Object?> map) {
    return AdminServiceItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Layanan Bersihuy',
      category: map['category']?.toString() ?? 'Cleaning',
      description: map['description']?.toString() ?? '',
      price: _readInt(map['base_price']),
      durationMinutes: _readInt(map['duration_minutes']),
      rating: _readDouble(map['rating']),
      isActive: map['is_active'] as bool? ?? true,
      imageAssetPath: map['image_asset_path']?.toString(),
    );
  }
}

class AdminProductItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final bool isAddon;
  final bool isActive;
  final String? imageAssetPath;

  const AdminProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isAddon,
    required this.isActive,
    this.imageAssetPath,
  });

  factory AdminProductItem.fromMap(Map<String, Object?> map) {
    return AdminProductItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Produk Bersihuy',
      description: map['description']?.toString() ?? '',
      price: _readInt(map['price']),
      isAddon: map['is_addon'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      imageAssetPath: map['image_asset_path']?.toString(),
    );
  }
}

class AdminComplaintRow {
  final String id;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String serviceName;
  final String category;
  final String description;
  final String? evidenceUrl;
  final String status;
  final String? resolutionNote;
  final String? handledByName;
  final String? assignedStaffId;
  final DateTime? createdAt;

  const AdminComplaintRow({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.serviceName,
    required this.category,
    required this.description,
    this.evidenceUrl,
    required this.status,
    this.resolutionNote,
    this.handledByName,
    this.assignedStaffId,
    this.createdAt,
  });

  factory AdminComplaintRow.fromMap(
    Map<String, Object?> map, {
    String? orderNumber,
    String? customerName,
    String? serviceName,
    String? assignedStaffId,
    String? handledByName,
  }) {
    return AdminComplaintRow(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      orderNumber: orderNumber ?? 'Pesanan',
      customerName: customerName ?? 'Customer',
      serviceName: serviceName ?? 'Layanan Bersihuy',
      category: map['category']?.toString() ?? 'Lainnya',
      description: map['description']?.toString() ?? '-',
      evidenceUrl: map['evidence_url']?.toString(),
      status: map['status']?.toString() ?? 'open',
      resolutionNote: map['resolution_note']?.toString(),
      handledByName: handledByName,
      assignedStaffId: assignedStaffId,
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  String get statusLabel => adminComplaintStatusLabel(status);
  String get createdLabel => _formatDate(createdAt);
}

class AdminTopItem {
  final String name;
  final int count;
  final int revenue;

  const AdminTopItem({
    required this.name,
    required this.count,
    required this.revenue,
  });
}

class AdminItemInsights {
  final List<AdminTopItem> services;
  final List<AdminTopItem> products;

  const AdminItemInsights({required this.services, required this.products});
}

class _Captured<T> {
  final T value;
  final List<String> warnings;

  const _Captured({required this.value, this.warnings = const []});
}

class _ItemAccumulator {
  final String name;
  int count = 0;
  int revenue = 0;

  _ItemAccumulator(this.name);
}

class _AdminOrderItems {
  final String serviceName;
  final List<String> itemNames;

  const _AdminOrderItems({required this.serviceName, required this.itemNames});
}

class _AdminTaskInfo {
  final String id;
  final String? status;
  final String? staffId;
  final String? staffName;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;

  const _AdminTaskInfo({
    required this.id,
    this.status,
    this.staffId,
    this.staffName,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
  });
}

class _ExistingTask {
  final String id;
  final String? status;

  const _ExistingTask({required this.id, this.status});
}

class _AssignTaskResult {
  final String taskId;
  final String? oldStatus;

  const _AssignTaskResult({required this.taskId, required this.oldStatus});
}

enum _TaskWriteMode { insert, update }

String adminOrderStatusLabel(String status) {
  return switch (status) {
    'created' => 'Dibuat',
    'pending_payment' => 'Menunggu Pembayaran',
    'paid' => 'Dibayar',
    'scheduled' => 'Dijadwalkan',
    'assigned' => 'Ditugaskan',
    'in_progress' => 'Dalam Proses',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    'complained' => 'Komplain',
    'proof_uploaded' => 'Bukti Diupload',
    _ => status,
  };
}

String adminPaymentStatusLabel(String status) {
  return switch (status) {
    'pending' => 'Menunggu',
    'pending_payment' => 'Menunggu',
    'paid' => 'Dibayar',
    'failed' => 'Gagal',
    'expired' => 'Kedaluwarsa',
    'refunded' => 'Refund',
    _ => status,
  };
}

String adminComplaintStatusLabel(String status) {
  return switch (status) {
    'open' => 'Terbuka',
    'in_review' => 'Dalam Review',
    'resolved' => 'Selesai',
    'rejected' => 'Ditolak',
    _ => status,
  };
}

String formatAdminRupiah(num value) {
  final digits = value.round().toString();
  final buffer = StringBuffer('Rp');
  for (var index = 0; index < digits.length; index++) {
    final positionFromEnd = digits.length - index;
    buffer.write(digits[index]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

String _profileDisplayName(
  Map<String, Object?>? data, {
  required String fallback,
}) {
  final fullName = data?['full_name']?.toString().trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;

  final email = data?['email']?.toString().trim();
  if (email != null && email.isNotEmpty) {
    final atIndex = email.indexOf('@');
    return atIndex > 0 ? email.substring(0, atIndex) : email;
  }

  return fallback;
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String? _readOptionalString(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

String _fallbackOrderNumber(String id) {
  if (id.trim().isEmpty) return '-';
  final cleanId = id.trim();
  final shortId = cleanId.length <= 8 ? cleanId : cleanId.substring(0, 8);
  return 'ORD-${shortId.toUpperCase()}';
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  const months = [
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _assignedTaskStatus(String? currentStatus) {
  return switch (currentStatus) {
    'in_progress' || 'completed' || 'proof_uploaded' => currentStatus!,
    _ => 'assigned',
  };
}

bool _isSameDay(DateTime? value, DateTime other) {
  if (value == null) return false;
  final local = value.toLocal();
  return local.year == other.year &&
      local.month == other.month &&
      local.day == other.day;
}

bool _isMissingStaffNoteColumn(PostgrestException error) {
  final message = error.message.toLowerCase();
  final details = error.details?.toString().toLowerCase() ?? '';
  return error.code == '42703' ||
      message.contains('staff_note') ||
      details.contains('staff_note');
}

void _debugPostgrestException(String label, PostgrestException error) {
  debugPrint(label);
  debugPrint('  code=${error.code}');
  debugPrint('  message=${error.message}');
  debugPrint('  details=${error.details}');
  debugPrint('  hint=${error.hint}');
}
