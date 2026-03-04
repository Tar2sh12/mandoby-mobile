import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<ShiftModel> _shifts = [];
  List<PersonModel> _people = [];
  String? _selectedShiftId;
  List<TransactionModel> _transactions = [];
  bool _loading = true;
  bool _txLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService().getShifts(), ApiService().getPeople()]);
      setState(() {
        _shifts = results[0] as List<ShiftModel>;
        _people = results[1] as List<PersonModel>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) showError(context, e.toString());
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTx(String shiftId) async {
    setState(() { _selectedShiftId = shiftId; _txLoading = true; _transactions = []; });
    try {
      final tx = await ApiService().getTransactionsByShift(shiftId);
      setState(() { _transactions = tx; _txLoading = false; });
    } catch (e) {
      if (mounted) showError(context, e.toString());
      setState(() => _txLoading = false);
    }
  }

  void _showRecordDialog() {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String? personId;
    String? shiftId = _selectedShiftId;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Record Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: shiftId,
                dropdownColor: AppColors.bgElevated,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(labelText: 'Shift *'),
                hint: const Text('Select shift', style: TextStyle(color: AppColors.textMuted)),
                items: _shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setS(() => shiftId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: personId,
                dropdownColor: AppColors.bgElevated,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(labelText: 'From person *'),
                hint: const Text('Select person', style: TextStyle(color: AppColors.textMuted)),
                items: _people.map((p) => DropdownMenuItem(value: p.id, child: Text(p.displayName))).toList(),
                onChanged: (v) => setS(() => personId = v),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Amount (EGP)', hint: '600', controller: amtCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              AppTextField(label: 'Description', hint: 'e.g. Sool Mahmoud paid 600 EGP', controller: descCtrl),
              const SizedBox(height: 20),
              AppButton(
                label: 'Record Payment',
                color: AppColors.success,
                loading: saving,
                width: double.infinity,
                onPressed: () async {
                  if (amtCtrl.text.isEmpty || personId == null || shiftId == null) {
                    showError(context, 'Shift, person and amount are required');
                    return;
                  }
                  setS(() => saving = true);
                  try {
                    await ApiService().recordPayment({
                      'amount': double.parse(amtCtrl.text),
                      'fromPersonId': personId,
                      'shiftId': shiftId,
                      'description': descCtrl.text,
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      showSuccess(context, 'Payment recorded!');
                      if (shiftId == _selectedShiftId) _loadTx(_selectedShiftId!);
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
      ),
    );
  }

  double get _total => _transactions.fold(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(onPressed: _showRecordDialog, icon: const Icon(Icons.add_circle_outline, color: AppColors.success)),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const LoadingCenter()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppCard(
                    child: DropdownButtonFormField<String>(
                      value: _selectedShiftId,
                      dropdownColor: AppColors.bgElevated,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(labelText: 'Filter by shift'),
                      hint: const Text('Choose a shift...', style: TextStyle(color: AppColors.textMuted)),
                      items: _shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (v) { if (v != null) _loadTx(v); },
                    ),
                  ),
                ),
                if (_selectedShiftId != null && !_txLoading && _transactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      borderColor: AppColors.success.withOpacity(0.3),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, color: AppColors.success, size: 22),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('TOTAL COLLECTED', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                            Text('EGP ${_total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: _txLoading
                      ? const LoadingCenter()
                      : _selectedShiftId == null
                          ? EmptyState(icon: Icons.swap_horiz, title: 'Select a shift', description: 'Choose a shift to view its transactions', action: AppButton(label: 'Record Payment', color: AppColors.success, icon: Icons.add, onPressed: _showRecordDialog))
                          : _transactions.isEmpty
                              ? EmptyState(icon: Icons.swap_horiz, title: 'No transactions', description: 'No payments recorded for this shift', action: AppButton(label: 'Record Payment', color: AppColors.success, icon: Icons.add, onPressed: _showRecordDialog))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                                  itemCount: _transactions.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final tx = _transactions[i];
                                    return AppCard(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(color: AppColors.successGlow, borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.success.withOpacity(0.3))),
                                            child: const Icon(Icons.attach_money, color: AppColors.success, size: 22),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text(tx.description?.isNotEmpty == true ? tx.description! : 'Payment received', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                                              Text('From: ${tx.fromPersonId?.name ?? 'Unknown'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                            ]),
                                          ),
                                          AppBadge.success('+EGP ${tx.amount.toStringAsFixed(0)}'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRecordDialog,
        backgroundColor: AppColors.success,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
