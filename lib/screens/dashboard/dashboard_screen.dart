import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../api/api_service.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ShiftModel> _shifts = [];
  List<PersonModel> _people = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService().getShifts(),
        ApiService().getPeople(),
      ]);
      if (!mounted) return;
      setState(() {
        _shifts = results[0] as List<ShiftModel>;
        _people = results[1] as List<PersonModel>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return raw;
    }
  } 
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final recent = [..._shifts]
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    final recentShifts = recent.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_greeting 👋',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              '${user?.username ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: CircleAvatar(
              backgroundColor: AppColors.accent,
              radius: 18,
              child: Text(
                user?.initial ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const LoadingCenter()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Stats grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: [
                      StatCard(
                        label: 'Total Shifts',
                        value: '${_shifts.length}',
                        icon: Icons.calendar_month,
                        accentColor: AppColors.accent,
                        subtitle: 'All time',
                      ),
                      StatCard(
                        label: 'People',
                        value: '${_people.length}',
                        icon: Icons.people,
                        accentColor: AppColors.success,
                        subtitle: 'Contacts',
                      ),
                      StatCard(
                        label: 'Role',
                        value: user?.role ?? '—',
                        icon: Icons.shield_outlined,
                        accentColor: AppColors.warning,
                        subtitle: 'Your permissions',
                      ),
                      StatCard(
                        label: 'Status',
                        value: 'Active',
                        icon: Icons.verified_outlined,
                        accentColor: AppColors.success,
                        subtitle: 'Account verified',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Shifts
                  SectionHeader(
                    title: 'Recent Shifts',
                    trailing: TextButton(
                      onPressed: () => context.go('/shifts'),
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (recentShifts.isEmpty)
                    AppCard(
                      child: EmptyState(
                        icon: Icons.calendar_month_outlined,
                        title: 'No shifts yet',
                        description: 'Create your first shift to get started',
                        action: AppButton(
                          label: 'Create Shift',
                          icon: Icons.add,
                          onPressed: () => context.go('/shifts'),
                        ),
                      ),
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: recentShifts.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          return Column(
                            children: [
                              ListTile(
                                onTap: () => context.push('/shifts/${s.id}'),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGlow,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_formatDate(s.fromDate)} → ${_formatDate(s.toDate)}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (i < recentShifts.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Quick actions
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _QuickAction(
                          label: 'New Shift',
                          icon: Icons.calendar_month,
                          color: AppColors.accent,
                          onTap: () => context.go('/shifts'),
                        ),
                        const Divider(height: 1, indent: 16),
                        _QuickAction(
                          label: 'Add Person',
                          icon: Icons.person_add_outlined,
                          color: AppColors.success,
                          onTap: () => context.go('/people'),
                        ),
                        const Divider(height: 1, indent: 16),
                        _QuickAction(
                          label: 'Log Item',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.warning,
                          onTap: () => context.go('/items'),
                        ),
                        const Divider(height: 1, indent: 16),
                        _QuickAction(
                          label: 'Record Payment',
                          icon: Icons.payments_outlined,
                          color: AppColors.pink,
                          onTap: () => context.go('/transactions'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textMuted,
      ),
    );
  }
}