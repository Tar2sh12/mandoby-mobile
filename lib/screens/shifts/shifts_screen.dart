import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_service.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  List<ShiftModel> _shifts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ApiService().getShifts();
      setState(() {
        _shifts = s;
        _loading = false;
      });
    } catch (e) {
      if (mounted) showError(context, e.toString());
      setState(() => _loading = false);
    }
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

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Create New Shift',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Shift name',
                hint: 'e.g. 1st Nabtshia in March',
                controller: nameCtrl,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'From date',
                hint: 'DD-MM-YYYY',
                controller: fromCtrl,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'To date',
                hint: 'DD-MM-YYYY',
                controller: toCtrl,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            AppButton(
              label: 'Create',
              loading: saving,
              onPressed: () async {
                if (nameCtrl.text.isEmpty ||
                    fromCtrl.text.isEmpty ||
                    toCtrl.text.isEmpty) {
                  showError(context, 'All fields are required');
                  return;
                }
                setS(() => saving = true);
                try {
                  await ApiService().createShift(
                    nameCtrl.text.trim(),
                    fromCtrl.text.trim(),
                    toCtrl.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    showSuccess(context, 'Shift created!');
                    _load();
                  }
                } catch (e) {
                  if (mounted) showError(context, e.toString());
                }
                if (mounted) setS(() => saving = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shifts'),
            Text(
              '${_shifts.length} total',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const LoadingCenter()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: _shifts.isEmpty
                  ? EmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'No shifts yet',
                      description:
                          'Create your first shift to start tracking items and transactions',
                      action: AppButton(
                        label: 'Create Shift',
                        icon: Icons.add,
                        onPressed: _showCreateDialog,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _shifts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final s = _shifts[i];
                        return AppCard(
                          onTap: () => context.push('/shifts/${s.id}'),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.accentGlow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.accent.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.calendar_month,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_formatDate(s.fromDate)} → ${_formatDate(s.toDate)}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
