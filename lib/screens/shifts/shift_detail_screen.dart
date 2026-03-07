import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_service.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class ShiftDetailScreen extends StatefulWidget {
  final String shiftId;
  const ShiftDetailScreen({super.key, required this.shiftId});

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<ItemModel> _items = [];
  List<TransactionModel> _transactions = [];
  List<PersonModel> _people = [];
  bool _loading = true;

  // Tracks which date sections are expanded; default all expanded
  final Set<String> _collapsedDates = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService().getItemsByShift(widget.shiftId),
        ApiService().getTransactionsByShift(widget.shiftId),
        ApiService().getPeople(),
      ]);
      print(results.toString());
      setState(() {
        _items = results[0] as List<ItemModel>;
        _transactions = results[1] as List<TransactionModel>;
        _people = results[2] as List<PersonModel>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) showError(context, e.toString() + " 11");
      setState(() => _loading = false);
    }
  }

  double get _totalItems => _items.fold(0, (s, i) => s + i.total);
  double get _totalTx => _transactions.fold(0, (s, t) => s + t.amount);
  double get _totalBoughtItems =>
      _items.fold(0, (s, i) => i.checked ? s + i.total : s);

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Returns: { dateLabel -> { personName -> [items] } }
  /// Sorted newest date first.
  Map<String, Map<String, List<ItemModel>>> _groupByDateAndPerson() {
    final Map<String, Map<String, List<ItemModel>>> grouped = {};
    for (final item in _items) {
      final dateLabel = _formatDate(item.date);
      final personName = item?.personId?.name ?? 'Unknown';
      grouped.putIfAbsent(dateLabel, () => {});
      grouped[dateLabel]!.putIfAbsent(personName, () => []).add(item);
    }

    // Sort dates descending (newest first)
    final sorted = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) {
        try {
          DateTime parse(String s) {
            final p = s.split('-');
            return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
          }

          return parse(b.key).compareTo(parse(a.key));
        } catch (_) {
          return b.key.compareTo(a.key);
        }
      }),
    );
    return sorted;
  }

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? selectedPersonId;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Item',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Item name',
                hint: 'e.g. LM Blue',
                controller: nameCtrl,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Quantity',
                      hint: '1',
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Cost (EGP)',
                      hint: '85',
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_people.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: selectedPersonId,
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Person (optional)',
                  ),
                  hint: const Text(
                    'Select person',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  items: _people
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setS(() => selectedPersonId = v),
                ),
                const SizedBox(height: 12),
              ],
              AppTextField(
                label: 'Note',
                hint: 'Optional...',
                controller: noteCtrl,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Add Item',
                loading: saving,
                width: double.infinity,
                onPressed: () async {
                  if (nameCtrl.text.isEmpty ||
                      qtyCtrl.text.isEmpty ||
                      costCtrl.text.isEmpty) {
                    showError(context, 'Name, quantity and cost are required');
                    return;
                  }
                  setS(() => saving = true);
                  try {
                    final data = <String, dynamic>{
                      'name': nameCtrl.text.trim(),
                      'quantity': int.parse(qtyCtrl.text),
                      'cost': double.parse(costCtrl.text),
                      'shiftId': widget.shiftId,
                      'note': noteCtrl.text,
                    };
                    if (selectedPersonId != null)
                      data['personId'] = selectedPersonId;
                    await ApiService().createItem(data);
                    if (mounted) {
                      Navigator.pop(ctx);
                      showSuccess(context, 'Item added!');
                      _load();
                    }
                  } catch (e) {
                    if (mounted) showError(context, e.toString() + " 222");
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

  void _showEditItemDialog(ItemModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: '${item.quantity}');
    final costCtrl = TextEditingController(text: '${item.cost}');
    final noteCtrl = TextEditingController(text: item.note ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Edit: ${item.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const Text(
                'Only changed fields will be sent to the server.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Name', controller: nameCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Quantity',
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Cost (EGP)',
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Note', controller: noteCtrl),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Changes',
                loading: saving,
                width: double.infinity,
                onPressed: () async {
                  final payload = <String, dynamic>{};
                  if (nameCtrl.text.trim().isNotEmpty &&
                      nameCtrl.text.trim() != item.name)
                    payload['name'] = nameCtrl.text.trim();
                  final qty = int.tryParse(qtyCtrl.text);
                  if (qty != null && qty != item.quantity)
                    payload['quantity'] = qty;
                  final cost = double.tryParse(costCtrl.text);
                  if (cost != null && cost != item.cost) payload['cost'] = cost;
                  if (noteCtrl.text != (item.note ?? ''))
                    payload['note'] = noteCtrl.text;
                  if (payload.isEmpty) {
                    showError(context, 'No changes to save');
                    return;
                  }
                  setS(() => saving = true);
                  try {
                    await ApiService().updateItem(item.id, payload);
                    if (mounted) {
                      Navigator.pop(ctx);
                      showSuccess(context, 'Item updated!');
                      _load();
                    }
                  } catch (e) {
                    if (mounted) showError(context, e.toString() + " 333");
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

  void _showAddTxDialog() {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String? selectedPersonId;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Record Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_people.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: selectedPersonId,
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(labelText: 'From person *'),
                  hint: const Text(
                    'Select person',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  items: _people
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setS(() => selectedPersonId = v),
                ),
                const SizedBox(height: 12),
              ],
              AppTextField(
                label: 'Amount (EGP)',
                hint: '600',
                controller: amtCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Description',
                hint: 'e.g. Payment for items',
                controller: descCtrl,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Record Payment',
                color: AppColors.success,
                loading: saving,
                width: double.infinity,
                onPressed: () async {
                  if (amtCtrl.text.isEmpty || selectedPersonId == null) {
                    showError(context, 'Person and amount are required');
                    return;
                  }
                  setS(() => saving = true);
                  try {
                    await ApiService().recordPayment({
                      'amount': double.parse(amtCtrl.text),
                      'fromPersonId': selectedPersonId,
                      'shiftId': widget.shiftId,
                      'description': descCtrl.text,
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      showSuccess(context, 'Payment recorded!');
                      _load();
                    }
                  } catch (e) {
                    if (mounted) showError(context, e.toString() + " 444");
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

  Widget _buildGroupedItems() {
    final grouped = _groupByDateAndPerson();
    if (grouped.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No items',
        description: 'Add items to this shift',
        action: AppButton(
          label: 'Add Item',
          icon: Icons.add,
          onPressed: _showAddItemDialog,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: grouped.length,
      itemBuilder: (_, dateIndex) {
        final dateLabel = grouped.keys.elementAt(dateIndex);
        final personMap = grouped[dateLabel]!;
        final dateTotalEGP = personMap.values
            .expand((items) => items)
            .fold(0.0, (s, i) => s + i.total);
        final dateTotalBoughtEGP = personMap.values
            .expand((items) => items)
            .fold(0.0, (s, i) => i.checked ? s + i.total : s);

        final isCollapsed = _collapsedDates.contains(dateLabel);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Foldable date header ──────────────────────────────────────
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isCollapsed) {
                    _collapsedDates.remove(dateLabel);
                  } else {
                    _collapsedDates.add(dateLabel);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGlow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: icon + date + bought price
                    Expanded(
                      child: Row(
                        children: [
                          AnimatedRotation(
                            turns: isCollapsed ? -0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.expand_more,
                              size: 16,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.calendar_today,
                            size: 13,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "bought ${dateTotalBoughtEGP.toStringAsFixed(0)} EGP",
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right: total
                    Text(
                      'EGP ${dateTotalEGP.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Collapsible content ───────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Column(
                children: [
                  const SizedBox(height: 10),
                  // Per-person cards under this date
                  ...personMap.entries.map((personEntry) {
                    final personName = personEntry.key;
                    final items = personEntry.value;
                    final personTotal = items.fold(0.0, (s, i) => s + i.total);
                    final personTotalBoughtItemsPrice = items.fold(
                      0.0,
                      (s, i) => i.checked ? s + i.total : s,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Person header
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: AppColors.bgElevated,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          personName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'EGP ${personTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Text(
                                  "bought item's price ${personTotalBoughtItemsPrice.toStringAsFixed(0)} EGP",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // Items list
                            ...items.asMap().entries.map((e) {
                              final item = e.value;
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      try {
                                        final updated = await ApiService()
                                            .toggleItemChecked(item.id);
                                        setState(() {
                                          final idx = _items.indexWhere(
                                            (i) => i.id == item.id,
                                          );
                                          if (idx != -1) _items[idx] = updated;
                                        });
                                      } catch (err) {
                                        if (mounted)
                                          showError(
                                            context,
                                            err.toString() + " 555",
                                          );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          // Checkbox
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: item.checked
                                                  ? AppColors.success
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: item.checked
                                                    ? AppColors.success
                                                    : AppColors.border,
                                                width: 2,
                                              ),
                                            ),
                                            child: item.checked
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          // Name + subtitle
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: item.checked
                                                        ? AppColors.textMuted
                                                        : AppColors.textPrimary,
                                                    decoration: item.checked
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : TextDecoration.none,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Qty: ${item.quantity}'
                                                  '${item.note != null && item.note!.isNotEmpty ? ' · ${item.note}' : ''}',
                                                  style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Price + edit
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'EGP ${item.total.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: item.checked
                                                      ? AppColors.textMuted
                                                      : AppColors.textPrimary,
                                                  decoration: item.checked
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : TextDecoration.none,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              GestureDetector(
                                                onTap: () =>
                                                    _showEditItemDialog(item),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.bgElevated,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          7,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors.border,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 13,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (e.key < items.length - 1)
                                    const Divider(height: 12),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              // Collapsed state: just a tiny gap so the next date header
              // doesn't feel squished
              secondChild: const SizedBox(height: 4),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Shift Details'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Items'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingCenter()
          : Column(
              children: [
                // Summary row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ITEMS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_items.length}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
                                ),
                              ),
                              Text(
                                'EGP ${_totalItems.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'total price of items bought ${_totalBoughtItems.toStringAsFixed(0)} EGP',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PAYMENTS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_transactions.length}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                'EGP ${_totalTx.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      // Items tab — grouped by date then person
                      RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accent,
                        child: _buildGroupedItems(),
                      ),

                      // Transactions tab
                      RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accent,
                        child: _transactions.isEmpty
                            ? EmptyState(
                                icon: Icons.swap_horiz,
                                title: 'No payments',
                                description: 'Record payments from people',
                                action: AppButton(
                                  label: 'Record Payment',
                                  color: AppColors.success,
                                  icon: Icons.add,
                                  onPressed: _showAddTxDialog,
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  80,
                                ),
                                itemCount: _transactions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final tx = _transactions[i];
                                  return AppCard(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.successGlow,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: AppColors.success
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.attach_money,
                                            color: AppColors.success,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.description?.isNotEmpty ==
                                                        true
                                                    ? tx.description!
                                                    : 'Payment received',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                tx.fromPersonId?.name ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        AppBadge.success(
                                          '+EGP ${tx.amount.toStringAsFixed(0)}',
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
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tab.index == 0 ? _showAddItemDialog : _showAddTxDialog,
        backgroundColor: _tab.index == 0 ? AppColors.accent : AppColors.success,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
