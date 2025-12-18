import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/models/client.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/shad_text_field.dart';
import 'package:goldfinch_crm/ui/components/shad_dropdown.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';
import 'package:goldfinch_crm/ui/components/search_select.dart';

class ClientInvoiceModal extends ConsumerStatefulWidget {
  final LedgerTransaction? existingInvoice;

  const ClientInvoiceModal({super.key, this.existingInvoice});

  static Future<void> show(BuildContext context, {LedgerTransaction? invoice}) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => ClientInvoiceModal(existingInvoice: invoice),
    );
  }

  @override
  ConsumerState<ClientInvoiceModal> createState() => _ClientInvoiceModalState();
}

class _ClientInvoiceModalState extends ConsumerState<ClientInvoiceModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _noteController;
  late TextEditingController _clientSearchController;
  String? _selectedClientId;
  String? _selectedClientLabel; // keep label in sync for robust selection
  TransactionStatus _status = TransactionStatus.outstanding;
  DateTime _invoiceDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingInvoice;
    _amountController = TextEditingController(
      text: existing != null ? (existing.amountPence / 100).toStringAsFixed(2) : '',
    );
    _invoiceNumberController = TextEditingController(
      text: existing?.invoiceNumber ?? '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _clientSearchController = TextEditingController();
    _selectedClientId = existing?.relatedClientId;
    // Clear client selection only when the field is fully cleared to avoid
    // invalidating a just-made selection from the dropdown overlay.
    _clientSearchController.addListener(() {
      final currentText = _clientSearchController.text;
      if (currentText.isEmpty && _selectedClientId != null) {
        debugPrint('ClientInvoiceModal: text cleared -> clearing selected client');
        setState(() => _selectedClientId = null);
      }
    });
    _status = existing?.status ?? TransactionStatus.outstanding;
    _invoiceDate = existing?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceNumberController.dispose();
    _noteController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.shad)),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Dialog should never exceed 90% of viewport height
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            maxWidth: 640,
          ),
          child: Container(
            width: 600,
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              // Add extra bottom padding for keyboard/smaller screens
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.existingInvoice == null ? 'Add Client Invoice' : 'Edit Client Invoice',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Make the form body scrollable to avoid overflow on smaller heights
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          clientsAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => Text('Error: $e'),
                            data: (clients) {
                              if (clients.isEmpty) {
                                return const Text('No clients available');
                              }
                              if (_selectedClientId != null && _clientSearchController.text.isEmpty) {
                                final sel = clients.firstWhere((c) => c.id == _selectedClientId, orElse: () => clients.first);
                                final label = sel.name; // titleOf(c) below is just name
                                _clientSearchController.text = label;
                                _selectedClientLabel = label;
                              }

                              return SearchSelect<Client>(
                                label: 'Client',
                                items: clients,
                                controller: _clientSearchController,
                                selectedId: _selectedClientId,
                                idOf: (c) => c.id,
                                titleOf: (c) => c.name,
                                subtitleOf: (c) => [c.email, c.address].where((e) => e.isNotEmpty).join(' • '),
                                tokensOf: (c) => [c.name, c.email, c.address],
                                onSelected: (c) => setState(() {
                                  _selectedClientId = c.id;
                                  _selectedClientLabel = c.name;
                                  debugPrint('ClientInvoiceModal: selected client ${c.id} -> ${c.name}');
                                }),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ShadTextField(
                            label: 'Invoice Number',
                            controller: _invoiceNumberController,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Invoice number required';
                              return null;
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
                          ShadTextField(
                            label: 'Staff Note (optional)',
                            controller: _noteController,
                            minLines: 2,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          ShadDropdown<TransactionStatus>(
                            label: 'Status',
                            value: _status,
                            items: [
                              const DropdownMenuItem(value: TransactionStatus.outstanding, child: Text('Outstanding')),
                              const DropdownMenuItem(value: TransactionStatus.received, child: Text('Received')),
                            ],
                            onChanged: (v) => setState(() => _status = v ?? TransactionStatus.outstanding),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Invoice Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_formatDate(_invoiceDate)),
                            ),
                          ),
                        ],
                      ),
                    ),
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
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _handleSave(dynamic user) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      debugPrint('ClientInvoiceModal: save blocked, no client selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    setState(() => _saving = true);

    final amountPence = (double.parse(_amountController.text) * 100).round();
    final now = DateTime.now();
    final userId = user?.id ?? 'unknown';
    debugPrint('ClientInvoiceModal: saving with clientId=$_selectedClientId amountPence=$amountPence');

    final invoice = LedgerTransaction(
      id: widget.existingInvoice?.id ?? const Uuid().v4(),
      type: TransactionType.income,
      category: TransactionCategory.clientInvoice,
      title: 'Client Invoice',
      relatedDriverId: null,
      relatedClientId: _selectedClientId,
      status: _status,
      amountPence: amountPence,
      startDate: _invoiceDate,
      endDate: null,
      attachments: widget.existingInvoice?.attachments ?? const [],
      frequency: null,
      createdByUserId: widget.existingInvoice?.createdByUserId ?? userId,
      createdAt: widget.existingInvoice?.createdAt ?? now,
      updatedAt: now,
      invoiceNumber: _invoiceNumberController.text,
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
