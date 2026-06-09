import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';

class PetugasHomePlaceholderScreen extends StatelessWidget {
  const PetugasHomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Petugas Area', style: AppTextStyles.headlineMedium),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: const PremiumStaffBackground(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.engineering_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                SizedBox(height: 16),
                Text('Petugas Home', style: AppTextStyles.headlineSmall),
                SizedBox(height: 8),
                Text(
                  'Halaman utama petugas sedang dalam pengembangan.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
