import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<ShiftModel> _shifts = [];
  String? _selectedShiftId;
  List<ItemModel> _items = [];
  bool _shiftsLoading = true;
  bool _itemsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    try {
      final s = await ApiService().getShifts();
      setState(() { _shifts = s; _shiftsLoading = false; });
    } catch (e) {
      if (mounted) showError(context, e.toString());
      setState(() => _shiftsLoading = false);
    }
  }

  Future<void> _loadItems(String shiftId) async {
    setState(() => _itemsLoading = true);
    try {
      final items = await ApiService().getItemsByShift(shiftId);
      setState(() { _items = items; _itemsLoading = false; });
    } catch (e) {
      if (mounted) showError(context, e.toString());
      setState(() => _itemsLoading = false);
    }
  }

  double get _total => _items.fold(0, (s, i) => s + i.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Items')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              child: _shiftsLoading
                  ? const LoadingCenter()
                  : DropdownButtonFormField<String>(
                      value: _selectedShiftId,
                      dropdownColor: AppColors.bgElevated,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(labelText: 'Select a shift to view items'),
                      hint: const Text('Choose a shift...', style: TextStyle(color: AppColors.textMuted)),
                      items: _shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (v) {
                        setState(() { _selectedShiftId = v; _items = []; });
                        if (v != null) _loadItems(v);
                      },
                    ),
            ),
          ),
          if (_selectedShiftId != null && !_itemsLoading && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_items.length} item${_items.length != 1 ? 's' : ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Text('Total: EGP ${_total.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          Expanded(
            child: _itemsLoading
                ? const LoadingCenter()
                : _selectedShiftId == null
                    ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'Select a shift', description: 'Choose a shift above to see its items')
                    : _items.isEmpty
                        ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'No items', description: 'This shift has no items. Add them from the shift detail page.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final item = _items[i];
                              return AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.border)),
                                      child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                        const SizedBox(height: 4),
                                        Wrap(spacing: 8, children: [
                                          Text('Qty: ${item.quantity}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                          Text('· EGP ${item.cost}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                          if (item.note?.isNotEmpty == true) Text('· ${item.note}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        ]),
                                        if (item.person != null) ...[
                                          const SizedBox(height: 6),
                                          AppBadge.muted(item.person!.name),
                                        ],
                                      ]),
                                    ),
                                    Text('EGP ${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
