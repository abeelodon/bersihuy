import 'package:bersihuy/features/admin/dashboard/repositories/admin_dashboard_repository.dart';
import 'package:bersihuy/features/customer/views/payment_screen.dart';
import 'package:bersihuy/features/staff/repositories/staff_task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('payment screen presents Midtrans as the primary action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Bayar Sekarang'), findsOneWidget);
    expect(
      find.text('Transaksi ini menggunakan lingkungan Midtrans Sandbox.'),
      findsOneWidget,
    );
    expect(find.text('Gunakan Pembayaran Demo'), findsNothing);
  });

  test('admin summary derives operational metrics from loaded data', () {
    final now = DateTime.now();
    final orders = [
      AdminOrderRow(
        id: 'order-1',
        orderNumber: 'ORD-001',
        customerId: 'customer-1',
        customerName: 'Customer Satu',
        serviceName: 'Bersih Rumah',
        itemNames: const ['Bersih Rumah'],
        address: 'Semarang',
        totalAmount: 150000,
        status: 'scheduled',
        paymentStatus: 'paid',
        createdAt: now,
      ),
      AdminOrderRow(
        id: 'order-2',
        orderNumber: 'ORD-002',
        customerId: 'customer-2',
        customerName: 'Customer Dua',
        serviceName: 'Deep Cleaning',
        itemNames: const ['Deep Cleaning'],
        address: 'Semarang',
        totalAmount: 250000,
        status: 'completed',
        paymentStatus: 'paid',
        taskId: 'task-2',
        taskStatus: 'completed',
        assignedStaffId: 'staff-1',
        assignedStaffName: 'Budi Santoso',
        createdAt: now,
      ),
    ];

    final summary = AdminDashboardSummary.fromData(
      orders: orders,
      complaints: const [
        AdminComplaintRow(
          id: 'complaint-1',
          orderId: 'order-1',
          orderNumber: 'ORD-001',
          customerName: 'Customer Satu',
          serviceName: 'Bersih Rumah',
          category: 'Kualitas',
          description: 'Perlu ditinjau.',
          status: 'open',
        ),
      ],
      reviews: const [
        {'rating': 4},
        {'rating': 5},
      ],
    );

    expect(summary.totalOrders, 2);
    expect(summary.todayOrders, 2);
    expect(summary.waitingAssignment, 1);
    expect(summary.completed, 1);
    expect(summary.openComplaints, 1);
    expect(summary.totalRevenue, 400000);
    expect(summary.averageOrderValue, 200000);
    expect(summary.averageRating, 4.5);
  });

  test('staff operational priority sorts overdue before upcoming tasks', () {
    const staffId = 'staff-1';
    StaffTaskWithDetails task({
      required String id,
      required DateTime date,
      required String time,
      String status = 'assigned',
    }) {
      return StaffTaskWithDetails(
        task: StaffTask(
          id: id,
          orderId: 'order-$id',
          staffId: staffId,
          status: status,
        ),
          serviceName: 'Test Service',
          customerName: 'Test Customer',
          customerId: 'test-customer-id',
          serviceAddress: 'Test Address',
        scheduleDate: date,
        scheduleTime: time,
        orderNumber: id,
      );
    }

    final now = DateTime(2026, 6, 8, 12);
    final tasks =
        [
          task(id: 'upcoming', date: DateTime(2026, 6, 10), time: '18:00'),
          task(id: 'oldest', date: DateTime(2026, 6, 3), time: '09:00'),
          task(id: 'today', date: DateTime(2026, 6, 8), time: '14:00'),
          task(
            id: 'completed',
            date: DateTime(2026, 6, 2),
            time: '09:00',
            status: 'completed',
          ),
        ]..sort(
          (a, b) =>
              StaffTaskWithDetails.compareByOperationalPriority(a, b, now: now),
        );

    expect(tasks.map((item) => item.task.id), [
      'oldest',
      'today',
      'upcoming',
      'completed',
    ]);
    expect(tasks.first.isOverdueAt(now), isTrue);
  });
}
