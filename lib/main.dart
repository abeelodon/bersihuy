import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/views/forgot_password_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/customer/views/customer_home_screen.dart';
import 'features/customer/views/customer_services_screen.dart';
import 'features/customer/notifications/views/notification_screen.dart';
import 'features/customer/views/invoice_screen.dart';
import 'features/customer/views/payment_screen.dart';
import 'features/customer/views/service_detail_screen.dart';
import 'features/customer/views/order_tracking_screen.dart';
import 'features/customer/views/order_detail_screen.dart';
import 'features/customer/views/rating_review_screen.dart';
import 'features/customer/views/complaint_screen.dart';
import 'features/customer/views/customer_orders_screen.dart';
import 'features/customer/views/customer_profile_screen.dart';
import 'features/customer/views/subscription_screen.dart';
import 'features/customer/views/edit_profile_screen.dart';
import 'features/customer/views/payment_history_screen.dart';
import 'features/customer/views/bantuan_keluhan_screen.dart';
import 'features/customer/views/settings_screen.dart';
import 'features/customer/views/customer_edit_profile_screen.dart';
import 'features/customer/views/bersihuy_plus_screen.dart';
import 'features/customer/views/help_complaint_screen.dart';
import 'features/customer/views/customer_settings_screen.dart';
import 'features/account/views/security_account_screen.dart';
import 'features/account/views/change_password_screen.dart';
import 'features/account/views/google_login_screen.dart';
import 'features/account/views/delete_account_screen.dart';
import 'features/account/views/login_activity_screen.dart';
import 'features/account/views/connected_devices_screen.dart';
import 'features/admin/dashboard/views/admin_dashboard_screen.dart';
import 'features/staff/views/staff_home_screen.dart';
import 'features/staff/views/staff_bonus_screen.dart';
import 'features/staff/views/staff_referral_screen.dart';
import 'features/staff/views/staff_tasks_screen.dart';
import 'features/staff/views/staff_task_detail_screen.dart';
import 'features/staff/views/staff_upload_proof_screen.dart';
import 'features/staff/views/staff_history_screen.dart';
import 'features/staff/views/staff_profile_screen.dart';
import 'features/staff/views/staff_edit_profile_screen.dart';
import 'features/staff/views/staff_schedule_screen.dart';
import 'features/staff/views/staff_service_area_screen.dart';
import 'features/staff/views/staff_help_screen.dart';
import 'features/staff/views/staff_settings_screen.dart';

String _orderIdFromRouteArgs(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args is Map) {
    final orderId = args['orderId'];
    if (orderId is String) return orderId.trim();
  }
  return '';
}

String _taskIdFromRouteArgs(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args is Map) {
    final taskId = args['taskId'];
    if (taskId is String) return taskId.trim();
  }
  return '';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bersihuy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: _buildAuthRoute,
      routes: {
        AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),
        AppRoutes.customerHome: (context) => const CustomerHomeScreen(),
        AppRoutes.petugasHome: (context) => const StaffHomeScreen(),
        AppRoutes.customerServices: (context) => const CustomerServicesScreen(),
        AppRoutes.customerNotifications: (context) =>
            const CustomerNotificationScreen(),
        AppRoutes.serviceDetail: (context) => const ServiceDetailScreen(),
        AppRoutes.payment: (context) => const PaymentScreen(),
        AppRoutes.invoice: (context) => const InvoiceScreen(),
        AppRoutes.orderTracking: (context) =>
            OrderTrackingScreen(orderId: _orderIdFromRouteArgs(context)),
        AppRoutes.orderDetail: (context) => const OrderDetailScreen(),
        AppRoutes.ratingReview: (context) => const RatingReviewScreen(),
        AppRoutes.complaint: (context) => const ComplaintScreen(),
        AppRoutes.customerOrders: (context) => const CustomerOrdersScreen(),
        AppRoutes.customerProfile: (context) => const CustomerProfileScreen(),
        AppRoutes.subscription: (context) => const SubscriptionScreen(),
        AppRoutes.editProfile: (context) => const EditProfileScreen(),
        AppRoutes.paymentHistory: (context) => const PaymentHistoryScreen(),
        AppRoutes.bantuanKeluhan: (context) => const BantuanKeluhanScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
        AppRoutes.customerEditProfile: (context) =>
            const CustomerEditProfileScreen(),
        AppRoutes.bersihuyPlus: (context) => const BersihuyPlusScreen(),
        AppRoutes.helpComplaint: (context) => const HelpComplaintScreen(),
        AppRoutes.customerSettings: (context) => const CustomerSettingsScreen(),
        AppRoutes.securityAccount: (context) => const SecurityAccountScreen(),
        AppRoutes.changePassword: (context) => const ChangePasswordScreen(),
        AppRoutes.googleLogin: (context) => const GoogleLoginScreen(),
        AppRoutes.deleteAccount: (context) => const DeleteAccountScreen(),
        AppRoutes.loginActivity: (context) => const LoginActivityScreen(),
        AppRoutes.connectedDevices: (context) => const ConnectedDevicesScreen(),
        AppRoutes.staffHome: (context) => const StaffHomeScreen(),
        AppRoutes.staffBonus: (context) => const StaffBonusScreen(),
        AppRoutes.staffReferral: (context) => const StaffReferralScreen(),
        AppRoutes.staffTasks: (context) => const StaffTasksScreen(),
        AppRoutes.staffTaskDetail: (context) =>
            StaffTaskDetailScreen(taskId: _taskIdFromRouteArgs(context)),
        AppRoutes.staffUploadProof: (context) => const StaffUploadProofScreen(),
        AppRoutes.staffHistory: (context) => const StaffHistoryScreen(),
        AppRoutes.staffProfile: (context) => const StaffProfileScreen(),
        AppRoutes.staffEditProfile: (context) => const StaffEditProfileScreen(),
        AppRoutes.staffSchedule: (context) => const StaffScheduleScreen(),
        AppRoutes.staffServiceArea: (context) => const StaffServiceAreaScreen(),
        AppRoutes.staffHelp: (context) => const StaffHelpScreen(),
        AppRoutes.staffSettings: (context) => const StaffSettingsScreen(),
      },
    );
  }

  Route<dynamic>? _buildAuthRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.login => const LoginScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),
      _ => null,
    };

    if (page == null) {
      return null;
    }

    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.035, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
