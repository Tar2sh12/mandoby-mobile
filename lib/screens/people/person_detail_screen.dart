import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_service.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  PersonModel? _person;
  List<TransactionModel> _transactions = [];
  List<ShiftModel> _shifts = [];
  String? _selectedShiftId;
  List<ItemModel> _shiftItems = [];
  List<TransactionModel> _shiftTx = [];
  bool _loading = true;
  bool _shiftLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService().getPerson(widget.personId),
        ApiService().getTransactionsByPerson(widget.personId),
        ApiService().getShifts(),
      ]);
      setState(() {
        _person = results[0] as PersonModel;
        _transactions = results[1] as List<TransactionModel>;
        _shifts = results[2] as List<ShiftModel>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) showError(context, e.toString());
      setState(() => _loading = false);
    }
  }

  Future<void> _filterByShift(String? shiftId) async {
    setState(() { _selectedShiftId = shiftId; _shiftItems = []; _shiftTx = []; });
    if (shiftId == null) return;
    setState(() => _shiftLoading = true);
    try {
      final results = await Future.wait([
        ApiService().getItemsByShiftAndPerson(shiftId, widget.personId),
        ApiService().getTransactionsByShiftAndPerson(shiftId, widget.personId),
      ]);
      setState(() {
        _shiftItems = results[0] as List<ItemModel>;
        _shiftTx = results[1] as List<TransactionModel>;
        _shiftLoading = false;
      });
    } catch (e) {
      if (mounted) showError(context, e.toString());
      setState(() => _shiftLoading = false);
    }
  }

  double get _totalPaid => _transactions.fold(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppColors.bg, body: LoadingCenter());
    if (_person == null) return const Scaffold(backgroundColor: AppColors.bg, body: Center(child: Text('Person not found')));

    final color = avatarColor(_person!.name);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_person!.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            AppCard(
              child: Row(
                children: [
                  AvatarCircle(initial: _person!.initial, color: color, size: 64, fontSize: 26),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_person!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      if (_person!.title?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        AppBadge.accent(_person!.title!),
                      ],
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stats
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('TOTAL PAID', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('EGP ${_totalPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.success)),
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('TRANSACTIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${_transactions.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Shift filter
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter by Shift', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedShiftId,
                    dropdownColor: AppColors.bgElevated,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(hintText: 'Select a shift...'),
                    hint: const Text('Select a shift...', style: TextStyle(color: AppColors.textMuted)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All shifts', style: TextStyle(color: AppColors.textMuted))),
                      ..._shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: _filterByShift,
                  ),
                ],
              ),
            ),

            if (_selectedShiftId != null) ...[
              const SizedBox(height: 14),
              if (_shiftLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: LoadingCenter())
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: const [
                              Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.accent),
                              SizedBox(width: 6),
                              Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                            ]),
                            const SizedBox(height: 10),
                            if (_shiftItems.isEmpty)
                              const Text('No items', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                            else
                              ..._shiftItems.asMap().entries.map((e) => Column(children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text('Qty: ${e.value.quantity} · EGP ${e.value.cost}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                      ]),
                                    ),
                                    if (e.key < _shiftItems.length - 1) const Divider(height: 1),
                                  ])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: const [
                              Icon(Icons.swap_horiz, size: 16, color: AppColors.success),
                              SizedBox(width: 6),
                              Text('Payments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                            ]),
                            const SizedBox(height: 10),
                            if (_shiftTx.isEmpty)
                              const Text('No payments', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                            else
                              ..._shiftTx.asMap().entries.map((e) => Column(children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Expanded(child: Text(e.value.description?.isNotEmpty == true ? e.value.description! : 'Payment', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                        AppBadge.success('EGP ${e.value.amount.toStringAsFixed(0)}'),
                                      ]),
                                    ),
                                    if (e.key < _shiftTx.length - 1) const Divider(height: 1),
                                  ])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],

            const SizedBox(height: 14),

            // All transactions
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('All Transactions', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    const Text('No transactions yet', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                  else
                    ..._transactions.asMap().entries.map((e) => Column(children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: AppColors.successGlow, borderRadius: BorderRadius.circular(9)),
                              child: const Icon(Icons.attach_money, color: AppColors.success, size: 18),
                            ),
                            title: Text(e.value.description?.isNotEmpty == true ? e.value.description! : 'Payment received', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(e.value.shiftName ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            trailing: AppBadge.success('+EGP ${e.value.amount.toStringAsFixed(0)}'),
                          ),
                          if (e.key < _transactions.length - 1) const Divider(height: 1),
                        ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}