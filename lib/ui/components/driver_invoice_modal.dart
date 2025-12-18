import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/models/driver.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/shad_text_field.dart';
import 'package:goldfinch_crm/ui/components/shad_dropdown.dart';
import 'package:goldfinch_crm/ui/components/search_select.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';
import 'package:go_router/go_router.dart';

class DriverInvoiceModal extends ConsumerStatefulWidget {
  final LedgerTransaction? existingInvoice;

  const DriverInvoiceModal({super.key, this.existingInvoice});

  static Future<void> show(BuildContext context, {LedgerTransaction? invoice}) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => DriverInvoiceModal(existingInvoice: invoice),
    );
  }

  @override
  ConsumerState<DriverInvoiceModal> createState() => _DriverInvoiceModalState();
}

class _DriverInvoiceModalState extends ConsumerState<DriverInvoiceModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _driverSearchController;
  String? _selectedDriverId;
  String? _selectedDriverLabel; // keep label in sync with field for robust selection
  TransactionStatus _status = TransactionStatus.pending;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _attachments = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingInvoice;
    _amountController = TextEditingController(
      text: existing != null ? (existing.amountPence / 100).toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _driverSearchController = TextEditingController();
    _selectedDriverId = existing?.relatedDriverId;
    // Clear driver selection only if the user clears the field entirely.
    // Avoid clearing on partial edits to prevent race conditions with overlay selection.
    _driverSearchController.addListener(() {
      final currentText = _driverSearchController.text;
      if (currentText.isEmpty && _selectedDriverId != null) {
        debugPrint('DriverInvoiceModal: text cleared -> clearing selected driver');
        setState(() => _selectedDriverId = null);
      }
    });
    _status = existing?.status ?? TransactionStatus.pending;
    _startDate = existing?.startDate ?? DateTime.now();
    _endDate = existing?.endDate;
    _attachments = List.from(existing?.attachments ?? []);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _driverSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.shad)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingInvoice == null ? 'Add Driver Invoice' : 'Edit Driver Invoice',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                ),
                const SizedBox(height: 24),
                driversAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (drivers) {
                    if (drivers.isEmpty) {
                      return const Text('No drivers available');
                    }
                    // Prefill search field with selected driver label (consistent with titleOf)
                    if (_selectedDriverId != null && (_driverSearchController.text.isEmpty)) {
                      final sel = drivers.firstWhere((d) => d.id == _selectedDriverId, orElse: () => drivers.first);
                      final label = (sel.name.isNotEmpty && sel.code.isNotEmpty)
                          ? '${sel.name} • ${sel.code}'
                          : (sel.name.isNotEmpty ? sel.name : sel.code);
                      _driverSearchController.text = label;
                      _selectedDriverLabel = label;
                    }

                    return SearchSelect<Driver>(
                      label: 'Driver',
                      items: drivers,
                      controller: _driverSearchController,
                      selectedId: _selectedDriverId,
                      idOf: (d) => d.id,
                      titleOf: (d) => d.name.isNotEmpty && d.code.isNotEmpty
                          ? '${d.name} • ${d.code}'
                          : (d.name.isNotEmpty ? d.name : d.code),
                      subtitleOf: (d) => [d.email, d.vehicleReg].where((e) => e.isNotEmpty).join(' • '),
                      tokensOf: (d) => [d.name, d.code, d.email, d.vehicleReg],
                      onSelected: (d) {
                        final label = (d.name.isNotEmpty && d.code.isNotEmpty)
                            ? '${d.name} • ${d.code}'
                            : (d.name.isNotEmpty ? d.name : d.code);
                        setState(() {
                          _selectedDriverId = d.id;
                          _selectedDriverLabel = label;
                        });
                         debugPrint('DriverInvoiceModal: selected driver ${d.id} -> $label');
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                ShadTextField(
                  label: 'Amount (£)',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount required';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ShadDropdown<TransactionStatus>(
                  label: 'Status',
                  value: _status,
                  items: [
                    const DropdownMenuItem(value: TransactionStatus.pending, child: Text('Pending')),
                    const DropdownMenuItem(value: TransactionStatus.paid, child: Text('Paid')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? TransactionStatus.pending),
                ),
                const SizedBox(height: 16),
                ShadTextField(
                  label: 'Staff Note (optional)',
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_formatDate(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_endDate != null ? _formatDate(_endDate!) : 'None'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Attachments (${_attachments.length})',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickAttachment,
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShadButton(
                      label: 'Cancel',
                      onPressed: _saving ? null : () => context.pop(),
                      variant: ShadButtonVariant.ghost,
                    ),
                    const SizedBox(width: 12),
                    ShadButton(
                      label: _saving ? 'Saving...' : 'Save',
                      onPressed: _saving ? null : () => _handleSave(currentUserAsync.value),
                      variant: ShadButtonVariant.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final attachmentService = ref.read(attachmentServiceProvider);
    final picked = await attachmentService.pick();
    if (!mounted) return;
    if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading attachment...')));
      final url = await attachmentService.uploadAndGetUrl(picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (url != null) {
        setState(() => _attachments.add(url));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment uploaded')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Check Storage rules and try again.')));
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _handleSave(dynamic user) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDriverId == null) {
      debugPrint('DriverInvoiceModal: save blocked, no driver selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a driver')),
      );
      return;
    }

    setState(() => _saving = true);

    final amountPence = (double.parse(_amountController.text) * 100).round();
    final now = DateTime.now();
    final userId = user?.id ?? 'unknown';
    debugPrint('DriverInvoiceModal: saving with driverId=$_selectedDriverId amountPence=$amountPence');

    final invoice = LedgerTransaction(
      id: widget.existingInvoice?.id ?? const Uuid().v4(),
      type: TransactionType.expense,
      category: TransactionCategory.driverPayout,
      title: 'Driver Invoice',
      relatedDriverId: _selectedDriverId,
      relatedClientId: null,
      status: _status,
      amountPence: amountPence,
      startDate: _startDate,
      endDate: _endDate,
      attachments: _attachments,
      frequency: null,
      createdByUserId: widget.existingInvoice?.createdByUserId ?? userId,
      createdAt: widget.existingInvoice?.createdAt ?? now,
      updatedAt: now,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(transactionsProvider.notifier).upsert(invoice);

    if (mounted) {
      context.pop();
      SuccessSnackbar.show(
        context,
        widget.existingInvoice == null ? 'Invoice created successfully' : 'Invoice updated successfully',
      );
    }
  }
}
