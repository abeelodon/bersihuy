import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

/// Raw data class mapping 1-to-1 with the `tasks` table.
class StaffTask {
  final String id;
  final String orderId;
  final String staffId;
  final String status;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final DateTime? proofUploadedAt;
  final String? note;
  final Map<String, dynamic> checklistData;

  const StaffTask({
    required this.id,
    required this.orderId,
    required this.staffId,
    required this.status,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.proofUploadedAt,
    this.note,
    this.checklistData = const {},
  });

  factory StaffTask.fromMap(Map<String, Object?> map) {
    // Parse checklist_data JSONB — may be Map or null
    Map<String, dynamic> checklist = const {};
    final raw = map['checklist_data'];
    if (raw is Map) {
      checklist = Map<String, dynamic>.from(raw);
    }

    return StaffTask(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      staffId: map['staff_id']?.toString() ?? '',
      status: map['status'] as String? ?? 'assigned',
      assignedAt: _parseDateTime(map['assigned_at']),
      startedAt: _parseDateTime(map['started_at']),
      completedAt: _parseDateTime(map['completed_at']),
      beforePhotoUrl: map['before_photo_url'] as String?,
      afterPhotoUrl: map['after_photo_url'] as String?,
      proofUploadedAt: _parseDateTime(map['proof_uploaded_at']),
      note: map['note'] as String?,
      checklistData: checklist,
    );
  }

  /// Display label for staff UI.
  String get statusLabel => switch (status) {
    'assigned' => 'Ditugaskan',
    'in_progress' => 'Dalam Proses',
    'completed' => 'Selesai',
    'proof_uploaded' => 'Bukti Diupload',
    _ => status,
  };

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Enriched task with order + customer + service details for display.
class StaffTaskWithDetails {
  final StaffTask task;
  final String serviceName;
  final String customerName;
  final String customerId;
  final String serviceAddress;
  final DateTime? scheduleDate;
  final String? scheduleTime;
  final String? customerNote;
  final String orderNumber;

  const StaffTaskWithDetails({
    required this.task,
    required this.serviceName,
    required this.customerName,
    required this.customerId,
    required this.serviceAddress,
    this.scheduleDate,
    this.scheduleTime,
    this.customerNote,
    required this.orderNumber,
  });

  /// Formatted schedule for display.
  String get formattedSchedule {
    if (scheduleDate == null &&
        (scheduleTime == null || scheduleTime!.isEmpty)) {
      return 'Belum dijadwalkan';
    }
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
    final dateStr = scheduleDate != null
        ? '${scheduleDate!.day} ${months[scheduleDate!.month - 1]} ${scheduleDate!.year}'
        : null;
    if (dateStr != null && scheduleTime != null && scheduleTime!.isNotEmpty) {
      return '$dateStr, $scheduleTime';
    }
    return dateStr ?? scheduleTime ?? 'Belum dijadwalkan';
  }

  /// Whether this task is considered "active" (not yet completed).
  bool get isActive => !isCompleted;

  bool get isCompleted =>
      task.status == 'completed' || task.status == 'cancelled';

  DateTime? get scheduledDateTime {
    final date = scheduleDate;
    if (date == null) return null;

    var hour = 23;
    var minute = 59;
    var second = 59;
    final normalizedTime = scheduleTime?.trim();
    if (normalizedTime != null && normalizedTime.isNotEmpty) {
      final parts = normalizedTime.split(':');
      if (parts.isNotEmpty) hour = int.tryParse(parts[0]) ?? 0;
      if (parts.length > 1) minute = int.tryParse(parts[1]) ?? 0;
      if (parts.length > 2) second = int.tryParse(parts[2]) ?? 0;
    }

    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  bool isOverdueAt(DateTime now) {
    final schedule = scheduledDateTime;
    return isActive && schedule != null && schedule.isBefore(now);
  }

  bool isTodayAt(DateTime now) {
    final schedule = scheduledDateTime;
    return schedule != null &&
        schedule.year == now.year &&
        schedule.month == now.month &&
        schedule.day == now.day;
  }

  static int compareByOperationalPriority(
    StaffTaskWithDetails a,
    StaffTaskWithDetails b, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final aRank = _priorityRank(a, reference);
    final bRank = _priorityRank(b, reference);
    if (aRank != bRank) return aRank.compareTo(bRank);

    final aSchedule = a.scheduledDateTime;
    final bSchedule = b.scheduledDateTime;
    if (aSchedule == null && bSchedule == null) {
      return (a.task.assignedAt ?? DateTime(9999)).compareTo(
        b.task.assignedAt ?? DateTime(9999),
      );
    }
    if (aSchedule == null) return 1;
    if (bSchedule == null) return -1;
    return aSchedule.compareTo(bSchedule);
  }

  static int _priorityRank(StaffTaskWithDetails item, DateTime now) {
    if (item.isCompleted) return 3;
    if (item.isOverdueAt(now)) return 0;
    if (item.isTodayAt(now)) return 1;
    return 2;
  }
}

class StaffOperationalProfile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? serviceArea;
  final String? baseLocation;
  final String? workSchedule;

  const StaffOperationalProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.serviceArea,
    this.baseLocation,
    this.workSchedule,
  });

  factory StaffOperationalProfile.fromMap(
    Map<String, Object?> map, {
    String fallbackEmail = '',
  }) {
    String? optional(String key) {
      final value = map[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return StaffOperationalProfile(
      id: map['id']?.toString() ?? '',
      fullName: optional('full_name') ?? 'Petugas Bersihuy',
      email: optional('email') ?? (fallbackEmail.isEmpty ? '-' : fallbackEmail),
      phone: optional('phone'),
      serviceArea: optional('service_area'),
      baseLocation: optional('base_location'),
      workSchedule: optional('work_schedule'),
    );
  }

  String get initials {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final value = parts.map((part) => part[0].toUpperCase()).join();
    return value.isEmpty ? 'P' : value;
  }
}

class StaffProfileStats {
  final int completedTasks;
  final int tasksThisMonth;
  final double? averageRating;
  final int complaintCount;

  const StaffProfileStats({
    required this.completedTasks,
    required this.tasksThisMonth,
    required this.averageRating,
    required this.complaintCount,
  });

  static const empty = StaffProfileStats(
    completedTasks: 0,
    tasksThisMonth: 0,
    averageRating: null,
    complaintCount: 0,
  );
}

class StaffProfileOverview {
  final StaffOperationalProfile profile;
  final StaffProfileStats stats;

  const StaffProfileOverview({required this.profile, required this.stats});
}

enum TaskProofType { before, after }

class ProofUploadException implements Exception {
  final String message;

  const ProofUploadException(this.message);

  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

/// Repository for staff task Supabase operations.
class StaffTaskRepository {
  const StaffTaskRepository();

  SupabaseClient get _client => SupabaseService.client;

  // ── Fetch all tasks for the current staff user ────────────────────────────

  /// Returns all tasks assigned to the current staff user, enriched with
  /// order/customer/service data. Ordered by assigned_at descending.
  ///
  /// Throws on core fetch failure. Enrichment errors are safe (fallback values).
  Future<List<StaffTaskWithDetails>> getStaffTasks() async {
    final staffId = SupabaseService.currentUser?.id;
    debugPrint('STAFF TASKS FETCH START staffId=$staffId');
    if (staffId == null) return [];

    final data = await _client
        .from('tasks')
        .select('*')
        .eq('staff_id', staffId)
        .order('assigned_at', ascending: false);

    final rows = data as List;
    debugPrint('STAFF TASKS FETCH RAW count=${rows.length}');

    final results = <StaffTaskWithDetails>[];
    for (final row in rows) {
      final task = StaffTask.fromMap(row as Map<String, Object?>);
      final details = await _enrichTask(task);
      results.add(details);
    }

    debugPrint('STAFF TASKS FETCH SUCCESS count=${results.length}');
    return results;
  }

  /// Returns all tasks for the current staff user for the home summary.
  /// Uses the same data source as getStaffTasks() so home and tasks screens
  /// are always consistent.
  Future<List<StaffTaskWithDetails>> getHomeTasks() async {
    return getStaffTasks();
  }

  /// Returns completed tasks for the staff history screen.
  Future<List<StaffTaskWithDetails>> getCompletedTasks() async {
    final staffId = SupabaseService.currentUser?.id;
    debugPrint('STAFF COMPLETED TASKS FETCH START staffId=$staffId');
    if (staffId == null) return [];

    final data = await _client
        .from('tasks')
        .select('*')
        .eq('staff_id', staffId)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);

    final rows = data as List;
    debugPrint('STAFF COMPLETED TASKS FETCH RAW count=${rows.length}');

    final results = <StaffTaskWithDetails>[];
    for (final row in rows) {
      final task = StaffTask.fromMap(row as Map<String, Object?>);
      final details = await _enrichTask(task);
      results.add(details);
    }

    debugPrint('STAFF COMPLETED TASKS FETCH SUCCESS count=${results.length}');
    return results;
  }

  /// Returns the review rating for a completed order, or null.
  Future<double?> getReviewRatingForOrder(String orderId) async {
    if (orderId.trim().isEmpty) return null;
    try {
      final data = await _client
          .from('reviews')
          .select('rating')
          .eq('order_id', orderId.trim())
          .maybeSingle();
      if (data == null) return null;
      return (data['rating'] as num?)?.toDouble();
    } catch (e) {
      debugPrint('REVIEW FETCH ERROR orderId=$orderId: $e');
      return null;
    }
  }

  /// Returns true if a complaint exists for this order.
  Future<bool> hasComplaintForOrder(String orderId) async {
    if (orderId.trim().isEmpty) return false;
    try {
      final data = await _client
          .from('complaints')
          .select('id')
          .eq('order_id', orderId.trim())
          .maybeSingle();
      return data != null;
    } catch (e) {
      debugPrint('COMPLAINT CHECK ERROR orderId=$orderId: $e');
      return false;
    }
  }

  /// Fetches a single task by ID, enriched with details.
  Future<StaffTaskWithDetails?> getTaskById(String taskId) async {
    if (taskId.trim().isEmpty) return null;
    debugPrint('STAFF TASK FETCH BY ID taskId=$taskId');

    final data = await _client
        .from('tasks')
        .select('*')
        .eq('id', taskId.trim())
        .maybeSingle();

    if (data == null) return null;
    final task = StaffTask.fromMap(data);
    return _enrichTask(task);
  }

  Future<String> uploadTaskProof({
    required String taskId,
    required TaskProofType type,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final normalizedTaskId = taskId.trim();
    if (normalizedTaskId.isEmpty) {
      throw const ProofUploadException('Task ID tidak tersedia.');
    }
    if (bytes.isEmpty) {
      throw const ProofUploadException('File gambar kosong atau tidak valid.');
    }

    final normalizedContentType = contentType.toLowerCase();
    if (!{
      'image/jpeg',
      'image/png',
      'image/webp',
    }.contains(normalizedContentType)) {
      throw const ProofUploadException(
        'Format gambar harus JPG, PNG, atau WebP.',
      );
    }

    final extension = switch (normalizedContentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final proofName = type == TaskProofType.before ? 'before' : 'after';
    final path =
        '$normalizedTaskId/${proofName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final bucket = _client.storage.from('task-proofs');

    try {
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: normalizedContentType,
          upsert: false,
        ),
      );
    } on StorageException catch (error) {
      final message = error.message.toLowerCase();
      if (error.statusCode == '404' ||
          message.contains('bucket') && message.contains('not found')) {
        throw const ProofUploadException(
          'Bucket task-proofs belum tersedia di Supabase Storage.',
        );
      }
      throw ProofUploadException('Gagal mengunggah gambar: ${error.message}');
    } catch (error) {
      throw ProofUploadException('Gagal mengunggah gambar: $error');
    }

    final publicUrl = bucket.getPublicUrl(path);
    final column = type == TaskProofType.before
        ? 'before_photo_url'
        : 'after_photo_url';

    try {
      await _client
          .from('tasks')
          .update({
            column: publicUrl,
            'proof_uploaded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', normalizedTaskId);
    } catch (error) {
      try {
        await bucket.remove([path]);
      } catch (_) {
        // The database error is more actionable than cleanup failure.
      }
      throw ProofUploadException(
        'Gambar terunggah, tetapi URL gagal disimpan ke task: $error',
      );
    }

    return publicUrl;
  }

  // ── Update task status ────────────────────────────────────────────────────

  /// Updates task status with proper timestamps, history tracking, and
  /// order status synchronization.
  ///
  /// Allowed transitions:
  ///   assigned → in_progress
  ///   in_progress → completed
  ///
  /// Throws on failure.
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    final staffId = SupabaseService.currentUser?.id;
    debugPrint('TASK STATUS UPDATE START taskId=$taskId newStatus=$newStatus');
    if (staffId == null) {
      throw Exception('User belum login.');
    }
    if (taskId.trim().isEmpty) {
      throw ArgumentError('Task ID tidak boleh kosong.');
    }

    // 1. Read current task
    final currentData = await _client
        .from('tasks')
        .select('id, status, order_id')
        .eq('id', taskId.trim())
        .single();

    final oldStatus = currentData['status'] as String? ?? '';
    final orderId = currentData['order_id']?.toString() ?? '';
    debugPrint(
      'TASK STATUS UPDATE current=$oldStatus → $newStatus orderId=$orderId',
    );

    // 2. Build update payload
    final updatePayload = <String, Object?>{'status': newStatus};
    if (newStatus == 'in_progress') {
      updatePayload['started_at'] = DateTime.now().toIso8601String();
    } else if (newStatus == 'completed') {
      updatePayload['completed_at'] = DateTime.now().toIso8601String();
    }

    // 3. Update tasks row
    await _client.from('tasks').update(updatePayload).eq('id', taskId.trim());
    debugPrint('TASK STATUS UPDATE tasks row updated');

    // 4. Insert task_status_history
    try {
      await _client.from('task_status_history').insert({
        'task_id': taskId.trim(),
        'old_status': oldStatus,
        'new_status': newStatus,
        'changed_by': staffId,
        'note': 'Status diubah oleh petugas',
      });
      debugPrint('TASK STATUS UPDATE history inserted');
    } catch (e) {
      debugPrint('TASK STATUS UPDATE history insert FAILED (non-fatal): $e');
      // Non-fatal — task is already updated
    }

    // 5. Sync orders.status
    if (orderId.isNotEmpty) {
      try {
        final orderStatus = switch (newStatus) {
          'in_progress' => 'in_progress',
          'completed' => 'completed',
          _ => null,
        };
        if (orderStatus != null) {
          await _client
              .from('orders')
              .update({'status': orderStatus})
              .eq('id', orderId.trim());
          debugPrint('TASK STATUS UPDATE orders.status → $orderStatus');
        }
      } catch (e) {
        debugPrint('TASK STATUS UPDATE orders sync FAILED (non-fatal): $e');
      }
    }

    debugPrint('TASK STATUS UPDATE SUCCESS');
  }

  // ── Checklist persistence ─────────────────────────────────────────────────

  /// Persists checklist state to tasks.checklist_data JSONB column.
  ///
  /// [checklistData] should be a map like:
  /// {
  ///   "area_utama_dibersihkan": true,
  ///   "lantai_dipel": false,
  ///   ...
  /// }
  Future<void> updateTaskChecklist(
    String taskId,
    Map<String, dynamic> checklistData,
  ) async {
    if (taskId.trim().isEmpty) {
      debugPrint('CHECKLIST UPDATE SKIP: empty taskId');
      return;
    }

    debugPrint('CHECKLIST UPDATE taskId=$taskId data=$checklistData');

    try {
      await _client
          .from('tasks')
          .update({'checklist_data': checklistData})
          .eq('id', taskId.trim());
      debugPrint('CHECKLIST UPDATE SUCCESS');
    } on PostgrestException catch (e) {
      debugPrint('CHECKLIST UPDATE PostgrestException:');
      debugPrint('  code=${e.code}');
      debugPrint('  message=${e.message}');
      debugPrint('  details=${e.details}');
      rethrow;
    } catch (e) {
      debugPrint('CHECKLIST UPDATE ERROR: $e');
      rethrow;
    }
  }

  // ── Fetch staff profile name ──────────────────────────────────────────────

  /// Returns the full_name of the current staff user from profiles.
  Future<String?> getStaffName() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      return data?['full_name'] as String?;
    } catch (e) {
      debugPrint('STAFF NAME FETCH ERROR: $e');
      return null;
    }
  }

  Future<StaffOperationalProfile?> getStaffOperationalProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select(
            'id, full_name, email, phone, service_area, base_location, work_schedule',
          )
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) {
        final metadataName = user.userMetadata?['full_name']?.toString().trim();
        return StaffOperationalProfile(
          id: user.id,
          fullName: metadataName == null || metadataName.isEmpty
              ? 'Petugas Bersihuy'
              : metadataName,
          email: user.email?.trim().isNotEmpty == true
              ? user.email!.trim()
              : '-',
        );
      }
      return StaffOperationalProfile.fromMap(
        Map<String, Object?>.from(data),
        fallbackEmail: user.email?.trim() ?? '',
      );
    } catch (error) {
      debugPrint('STAFF OPERATIONAL PROFILE FETCH ERROR: $error');
      rethrow;
    }
  }

  Future<StaffProfileOverview> getStaffProfileOverview() async {
    final profile = await getStaffOperationalProfile();
    if (profile == null) {
      throw StateError('Sesi petugas tidak ditemukan.');
    }

    final stats = await _getStaffProfileStats(profile.id);
    return StaffProfileOverview(profile: profile, stats: stats);
  }

  Future<void> updateStaffOperationalProfile({
    required String fullName,
    required String phone,
    required String serviceArea,
    required String baseLocation,
    required String workSchedule,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw StateError('Sesi petugas tidak ditemukan.');
    }

    await _client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'phone': _nullIfEmpty(phone),
          'service_area': _nullIfEmpty(serviceArea),
          'base_location': _nullIfEmpty(baseLocation),
          'work_schedule': _nullIfEmpty(workSchedule),
        })
        .eq('id', userId)
        .select('id')
        .single();
  }

  Future<StaffProfileStats> _getStaffProfileStats(String staffId) async {
    var completedTasks = 0;
    var tasksThisMonth = 0;
    double? averageRating;
    var complaintCount = 0;
    var orderIds = <String>[];

    try {
      final data = await _client
          .from('tasks')
          .select('order_id, status, assigned_at')
          .eq('staff_id', staffId);
      final rows = (data as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList();
      completedTasks = rows
          .where((row) => row['status']?.toString() == 'completed')
          .length;

      final now = DateTime.now();
      tasksThisMonth = rows.where((row) {
        final assignedAt = StaffTask._parseDateTime(
          row['assigned_at'],
        )?.toLocal();
        return assignedAt != null &&
            assignedAt.year == now.year &&
            assignedAt.month == now.month;
      }).length;

      orderIds = rows
          .map((row) => row['order_id']?.toString().trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    } catch (error) {
      debugPrint('STAFF PROFILE TASK STATS ERROR: $error');
    }

    try {
      final data = await _client
          .from('reviews')
          .select('rating')
          .eq('staff_id', staffId);
      final ratings = (data as List)
          .map((row) => (row as Map)['rating'])
          .whereType<num>()
          .map((rating) => rating.toDouble())
          .where((rating) => rating > 0)
          .toList();
      if (ratings.isNotEmpty) {
        averageRating =
            ratings.reduce((total, rating) => total + rating) / ratings.length;
      }
    } catch (error) {
      debugPrint('STAFF PROFILE RATING STATS ERROR: $error');
    }

    if (orderIds.isNotEmpty) {
      try {
        final data = await _client
            .from('complaints')
            .select('id')
            .inFilter('order_id', orderIds);
        complaintCount = (data as List).length;
      } catch (error) {
        debugPrint('STAFF PROFILE COMPLAINT STATS ERROR: $error');
      }
    }

    return StaffProfileStats(
      completedTasks: completedTasks,
      tasksThisMonth: tasksThisMonth,
      averageRating: averageRating,
      complaintCount: complaintCount,
    );
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // ── Private enrichment helpers ────────────────────────────────────────────

  /// Enriches a raw StaffTask with order, customer, and service details.
  /// Safe — uses fallbacks if any secondary query fails.
  Future<StaffTaskWithDetails> _enrichTask(StaffTask task) async {
    String serviceName = 'Layanan Bersihuy';
    String customerName = 'Pelanggan';
    String customerId = '';
    String serviceAddress = '-';
    DateTime? scheduleDate;
    String? scheduleTime;
    String? customerNote;
    String orderNumber = '-';

    debugPrint('STAFF TASK ENRICH orderId=${task.orderId}');

    if (task.orderId.trim().isNotEmpty) {
      // Fetch order data
      try {
        final orderData = await _client
            .from('orders')
            .select(
              'order_number, customer_id, service_address, schedule_date, schedule_time, customer_note',
            )
            .eq('id', task.orderId.trim())
            .maybeSingle();

        if (orderData != null) {
          orderNumber = orderData['order_number'] as String? ?? '-';
          serviceAddress = orderData['service_address'] as String? ?? '-';
          scheduleTime = orderData['schedule_time'] as String?;
          customerNote = orderData['customer_note'] as String?;

          final scheduleDateRaw = orderData['schedule_date'];
          if (scheduleDateRaw is String) {
            scheduleDate = DateTime.tryParse(scheduleDateRaw);
          }

          // Fetch customer name from profiles
          final orderCustomerId = orderData['customer_id']?.toString();
          debugPrint('STAFF TASK customerId=$orderCustomerId');
          if (orderCustomerId != null && orderCustomerId.trim().isNotEmpty) {
            customerId = orderCustomerId.trim();
            customerName = await _fetchCustomerName(orderCustomerId.trim());
            debugPrint('STAFF TASK customerName=$customerName');
          }
        }
      } catch (e) {
        debugPrint('ENRICH TASK order fetch ERROR: $e');
      }

      // Fetch service name from order_items
      try {
        final itemsData = await _client
            .from('order_items')
            .select('item_type, item_name')
            .eq('order_id', task.orderId.trim());

        final items = (itemsData as List)
            .map((row) => Map<String, Object?>.from(row as Map))
            .toList();
        // Try service item first, then fall back to first item
        final serviceItem = items
            .where((item) => item['item_type'] == 'service')
            .firstOrNull;
        final firstItem = items.firstOrNull;
        final bestItem = serviceItem ?? firstItem;
        final itemName = bestItem?['item_name'] as String?;
        if (itemName != null && itemName.trim().isNotEmpty) {
          serviceName = itemName.trim();
        }
      } catch (e) {
        debugPrint('ENRICH TASK order_items fetch ERROR: $e');
      }
    }

    return StaffTaskWithDetails(
      task: task,
      serviceName: serviceName,
      customerName: customerName,
      customerId: customerId,
      serviceAddress: serviceAddress,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      customerNote: customerNote,
      orderNumber: orderNumber,
    );
  }

  /// Fetches customer full_name from profiles.
  /// Returns 'Pelanggan' if all lookups fail.
  ///
  /// If this returns 'Pelanggan', check console for RLS error details.
  /// The staff user needs SELECT permission on profiles for other users.
  ///
  /// Required RLS policy (if missing):
  ///   CREATE POLICY "Authenticated users can read profiles"
  ///     ON public.profiles FOR SELECT
  ///     TO authenticated
  ///     USING (true);
  Future<String> _fetchCustomerName(String customerId) async {
    debugPrint('STAFF DETAIL customerId=$customerId');

    // Try profiles table
    try {
      final profileData = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', customerId)
          .maybeSingle();
      debugPrint('STAFF DETAIL customerProfileRaw=$profileData');
      final name = profileData?['full_name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        debugPrint('STAFF DETAIL customerName=${name.trim()}');
        return name.trim();
      }
      debugPrint('STAFF DETAIL profiles returned null/empty full_name');
    } on PostgrestException catch (e) {
      // Log full RLS/Postgrest error for diagnosis
      debugPrint('STAFF DETAIL customer profile PostgrestException:');
      debugPrint('  code=${e.code}');
      debugPrint('  message=${e.message}');
      debugPrint('  details=${e.details}');
      debugPrint('  hint=${e.hint}');
      debugPrint(
        '>>> FIX: Add RLS SELECT policy on profiles for authenticated users',
      );
    } catch (e) {
      debugPrint('STAFF DETAIL customer profile GENERIC ERROR: $e');
    }

    debugPrint('STAFF DETAIL customerName=Pelanggan (fallback)');
    return 'Pelanggan';
  }
}
