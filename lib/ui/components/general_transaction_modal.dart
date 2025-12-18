import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/shad_text_field.dart';
import 'package:goldfinch_crm/ui/components/shad_dropdown.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';
import 'package:goldfinch_crm/services/attachment_service.dart';

class GeneralTransactionModal extends ConsumerStatefulWidget {
  final TransactionType type;
  final LedgerTransaction? existingTransaction;

  const GeneralTransactionModal({
    super.key,
    required this.type,
    this.existingTransaction,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionType type,
    LedgerTransaction? transaction,
  }) =>
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context) => GeneralTransactionModal(
          type: type,
          existingTransaction: transaction,
        ),
      );

  @override
  ConsumerState<GeneralTransactionModal> createState() =>
      _GeneralTransactionModalState();
}

class _GeneralTransactionModalState
    extends ConsumerState<GeneralTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  TransactionStatus _status = TransactionStatus.pending;
  DateTime _startDate = DateTime.now();
  List<String> _attachments = [];
  bool _saving = false;
  // Recurrence (One-time / Monthly)
  TransactionFrequency _frequency = TransactionFrequency.oneTime;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing != null
          ? (existing.amountPence / 100).toStringAsFixed(2)
          : '',
    );
    _status = existing?.status ?? TransactionStatus.pending;
    _startDate = existing?.startDate ?? DateTime.now();
    _attachments = List.from(existing?.attachments ?? []);
    _frequency = existing?.frequency ?? TransactionFrequency.oneTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final title = widget.existingTransaction == null
        ? (isIncome ? 'Add Income' : 'Add Expense')
        : (isIncome ? 'Edit Income' : 'Edit Expense');

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.shad)),
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
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                ),
                const SizedBox(height: 24),
                ShadTextField(
                  label: 'Title',
                  controller: _titleController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Title required' : null,
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
                    const DropdownMenuItem(
                        value: TransactionStatus.pending, child: Text('Pending')),
                    const DropdownMenuItem(
                        value: TransactionStatus.paid, child: Text('Paid')),
                  ],
                  onChanged: (v) =>
                      setState(() => _status = v ?? TransactionStatus.pending),
                ),
                const SizedBox(height: 16),
                // Repeats: One-time or Monthly
                ShadDropdown<TransactionFrequency>(
                  label: 'Repeats',
                  value: _frequency,
                  items: const [
                    DropdownMenuItem(
                      value: TransactionFrequency.oneTime,
                      child: Text('One-time'),
                    ),
                    DropdownMenuItem(
                      value: TransactionFrequency.monthly,
                      child: Text('Monthly'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _frequency = v ?? TransactionFrequency.oneTime),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_formatDate(_startDate)),
                  ),
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
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      variant: ShadButtonVariant.ghost,
                    ),
                    const SizedBox(width: 12),
                    ShadButton(
                      label: _saving ? 'Saving...' : 'Save',
                      onPressed: _saving ? null : _handleSave,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _startDate = picked);
    }
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

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final amountPence = (double.parse(_amountController.text) * 100).round();
    final now = DateTime.now();
    final currentUserAsync = ref.read(currentUserProvider);
    final userId = currentUserAsync.value?.id ?? 'unknown';

    final category = widget.type == TransactionType.income
        ? TransactionCategory.generalIncome
        : TransactionCategory.generalExpense;

    final transaction = LedgerTransaction(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      type: widget.type,
      category: category,
      title: _titleController.text.trim(),
      relatedDriverId: null,
      relatedClientId: null,
      status: _status,
      amountPence: amountPence,
      startDate: _startDate,
      endDate: null,
      attachments: _attachments,
      frequency: _frequency,
      createdByUserId:
          widget.existingTransaction?.createdByUserId ?? userId,
      createdAt: widget.existingTransaction?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(transactionsProvider.notifier).upsert(transaction);

    if (mounted) {
      Navigator.of(context).pop();
      SuccessSnackbar.show(
        context,
        widget.existingTransaction == null
            ? '${widget.type == TransactionType.income ? 'Income' : 'Expense'} created successfully'
            : '${widget.type == TransactionType.income ? 'Income' : 'Expense'} updated successfully',
      );
    }
  }
}
