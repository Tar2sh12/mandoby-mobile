import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_service.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<PersonModel> _people = [];
  List<PersonModel> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await ApiService().getPeople();
      setState(() {
        _people = p;
        _filtered = p;
        _loading = false;
      });
    } catch (e) {
      if (mounted) showError(context, e.toString());
      setState(() => _loading = false);
    }
  }

  double get _totalUnpaidMoney =>
      _people.fold(0, (sum, p) => sum + (p.expenses ?? 0));
  // double get _totalTx => _transactions.fold(0, (s, t) => s + t.amount);
  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(
      () => _filtered = _people
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.title?.toLowerCase().contains(q) ?? false),
          )
          .toList(),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
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
            'Add Person',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Full name',
                hint: 'e.g. Mostafa',
                controller: nameCtrl,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Title / Role',
                hint: 'e.g. sool, customer...',
                controller: titleCtrl,
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
              label: 'Add',
              loading: saving,
              onPressed: () async {
                if (nameCtrl.text.isEmpty) {
                  showError(context, 'Name is required');
                  return;
                }
                setS(() => saving = true);
                try {
                  await ApiService().createPerson(
                    nameCtrl.text.trim(),
                    titleCtrl.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    showSuccess(context, 'Person added!');
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
            const Text('People'),
            Text(
              '${_people.length} contacts',
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
            onPressed: _showAddDialog,
            icon: const Icon(
              Icons.person_add_outlined,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search people...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const LoadingCenter()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: _filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: _searchCtrl.text.isEmpty
                          ? 'No people yet'
                          : 'No matches',
                      description: _searchCtrl.text.isEmpty
                          ? 'Add people to track items and payments'
                          : 'No results for "${_searchCtrl.text}"',
                      action: _searchCtrl.text.isEmpty
                          ? AppButton(
                              label: 'Add Person',
                              icon: Icons.add,
                              onPressed: _showAddDialog,
                            )
                          : null,
                    )
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            'Total unpaid: \$${_totalUnpaidMoney.toStringAsFixed(_totalUnpaidMoney.toString().length)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final p = _filtered[i];
                              final color = avatarColor(p.name);
                              return AppCard(
                                onTap: () => context.push('/people/${p.id}'),
                                child: Row(
                                  children: [
                                    AvatarCircle(
                                      initial: p.initial,
                                      color: color,
                                      size: 46,
                                      fontSize: 18,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'credits : ${p.credit} EGP',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 8,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'expenses : ${p.expenses} EGP',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 8,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),

                                          if (p.title?.isNotEmpty == true) ...[
                                            const SizedBox(height: 4),
                                            AppBadge.muted(p.title!),
                                          ],
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
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


/**
 * 
 */