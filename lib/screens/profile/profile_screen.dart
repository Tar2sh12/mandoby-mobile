import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final color = user != null ? avatarColor(user.fullName) : AppColors.accent;
    int calculateAge(String dobString) {
      final dob = DateTime.parse(dobString);
      final today = DateTime.now();

      int age = today.year - dob.year;

      // Check if birthday has occurred this year
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }

      return age;
    }

    final fields = [
      (Icons.person_outline, 'Full Name', user?.fullName ?? '—'),
      (Icons.email_outlined, 'Email', user?.email ?? '—'),
      (Icons.phone_outlined, 'Phone', user?.phone ?? '—'),
      (Icons.cake_outlined, 'Date of Birth', user?.DOB ?? '—'),
      (Icons.tag, 'Age', calculateAge(user?.DOB?? '').toString() ?? '—'),
      (Icons.shield_outlined, 'Role', user?.role ?? '—'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                AvatarCircle(
                  initial: user?.initial ?? '?',
                  color: color,
                  size: 72,
                  fontSize: 28,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (user?.role != null) AppBadge.accent(user!.role!),
                          if (user?.gender != null)
                            AppBadge.muted(user!.gender!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    'Account Details',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...fields.asMap().entries.map(
                  (entry) => Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            entry.value.$1,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          entry.value.$2,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          entry.value.$3.isNotEmpty ? entry.value.$3 : '—',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (entry.key < fields.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Sign Out',
            color: AppColors.danger,
            icon: Icons.logout,
            width: double.infinity,
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
