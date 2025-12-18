import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:goldfinch_crm/models/client.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/shad_text_field.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';

class ClientModal extends ConsumerStatefulWidget {
  final Client? existingClient;

  const ClientModal({super.key, this.existingClient});

  static Future<void> show(BuildContext context, {Client? client}) =>
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context) => ClientModal(existingClient: client),
      );

  @override
  ConsumerState<ClientModal> createState() => _ClientModalState();
}

class _ClientModalState extends ConsumerState<ClientModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingClient;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.shad)),
    child: Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingClient == null ? 'Add Client' : 'Edit Client',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 24),
            ShadTextField(
              label: 'Client Name',
              controller: _nameController,
              validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
            ),
            const SizedBox(height: 16),
            ShadTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
            ),
            const SizedBox(height: 16),
            ShadTextField(
              label: 'Address',
              controller: _addressController,
              validator: (v) => (v == null || v.isEmpty) ? 'Address required' : null,
              maxLines: 2,
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
  );

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    final client = Client(
      id: widget.existingClient?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      ownerId: widget.existingClient?.ownerId ?? '',
      createdAt: widget.existingClient?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(clientsProvider.notifier).upsert(client);

    if (mounted) {
      Navigator.of(context).pop();
      SuccessSnackbar.show(
        context,
        widget.existingClient == null ? 'Client created successfully' : 'Client updated successfully',
      );
    }
  }
}
